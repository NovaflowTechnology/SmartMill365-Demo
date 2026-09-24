import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:smartmachine365/web_app_template/sankey_energy_flow/widgets/sankey_chart_widget.dart';

class EchartsSankeyWidget extends StatefulWidget {
  final List<SankeyNode> nodes;
  final List<SankeyLink> links;
  final String title;
  final String subtitle;
  final double? height;

  const EchartsSankeyWidget({
    super.key,
    required this.nodes,
    required this.links,
    this.title = 'Facility Power Distribution',
    this.subtitle = '',
    this.height,
  });

  @override
  State<EchartsSankeyWidget> createState() => _EchartsSankeyWidgetState();
}

class _EchartsSankeyWidgetState extends State<EchartsSankeyWidget> {
  static final List<int> _availableViewIds = [];
  static int _maxViewId = 0;
  
  late final int _myViewId;
  late final String _viewType;
  late final String _containerId;
  late final html.DivElement _container;
  Timer? _retryTimer;
  Timer? _debounceTimer;
  int _attempt = 0;
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();
    if (_availableViewIds.isNotEmpty) {
      _myViewId = _availableViewIds.removeLast();
    } else {
      _myViewId = _maxViewId++;
    }
    
    _viewType = 'echarts-sankey-$_myViewId';
    _containerId = 'echarts-sankey-host-$_myViewId';
    
    _container = html.DivElement()
      ..id = _containerId
      ..style.width = '100%'
      ..style.height = '100%';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) => _container);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initOrUpdateChart());
  }

  @override
  void didUpdateWidget(covariant EchartsSankeyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nodes == widget.nodes &&
        oldWidget.links == widget.links &&
        oldWidget.height == widget.height &&
        oldWidget.title == widget.title &&
        oldWidget.subtitle == widget.subtitle) {
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted) _initOrUpdateChart();
    });
  }

  @override
  void dispose() {
    _availableViewIds.add(_myViewId);
    _retryTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initOrUpdateChart() {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _attempt = 0;
    _showFallback = false;
    _container.dataset['echartsReady'] = '';
    _tryRender();
  }

  void _tryRender() {
    _renderCanvas();
    if (_container.dataset['echartsReady'] == '1') return;
    _attempt++;
    if (_attempt >= 8) {
      if (mounted) setState(() => _showFallback = true);
      return;
    }
    _retryTimer = Timer(const Duration(milliseconds: 220), _tryRender);
  }

  // ── Build cross-free ordered data for canvas renderer ─────────────────────
  Map<String, dynamic> _buildCanvasData() {
    if (widget.nodes.isEmpty) return {'nodes': [], 'links': [], 'title': widget.title, 'subtitle': widget.subtitle};

    final depthMax = widget.nodes.map((n) => n.column).reduce((a, b) => a > b ? a : b);
    final col0Count = widget.nodes.where((n) => n.column == 0).length;
    final orderedNodes = _orderedNodesForEcharts(widget.nodes, widget.links, depthMax, col0Count);

    // Cross-free terminal ordering: group terminals by intermediate parent
    final nodeById = {for (final n in orderedNodes) n.id: n};
    final linksBySource = <String, List<SankeyLink>>{};
    for (final l in widget.links) {
      linksBySource.putIfAbsent(l.sourceId, () => []).add(l);
    }

    final col0Nodes = orderedNodes.where((n) => n.column == 0).toList();
    final intermediates = orderedNodes.where((n) => n.column > 0 && n.column < depthMax).toList();
    final terminalAdded = <String>{};
    final orderedList = <SankeyNode>[...col0Nodes, ...intermediates];

    for (final inter in intermediates) {
      final children = List<SankeyLink>.from(linksBySource[inter.id] ?? [])
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final lnk in children) {
        final tgt = nodeById[lnk.targetId];
        if (tgt == null || tgt.column != depthMax) continue;
        if (terminalAdded.add(tgt.id)) orderedList.add(tgt);
      }
    }
    // Any terminals connected directly from col0 (2-tier layout)
    for (final n in orderedNodes) {
      if (n.column == depthMax && terminalAdded.add(n.id)) orderedList.add(n);
    }

    final nodesJson = orderedList.map((n) => <String, dynamic>{
      'id': n.id,
      'label': n.label,
      'value': n.value,
      'color': _hex(n.color),
            'depth': n.column,
      'unit': n.unit,
      'mappingLabel': n.mappingLabel,
    }).toList();

    final linksJson = widget.links.map((l) => <String, dynamic>{
          'source': l.sourceId,
          'target': l.targetId,
      'value': l.value,
    }).toList();

    return {
      'nodes': nodesJson,
      'links': linksJson,
      'title': widget.title,
      'subtitle': widget.subtitle,
    };
  }

  // ── Canvas-based custom renderer ──────────────────────────────────────────
  void _renderCanvas() {
    final dataJson = jsonEncode(_buildCanvasData());
    final quotedDataJson = jsonEncode(dataJson);
    final script = html.ScriptElement()
      ..type = 'text/javascript'
      ..text = '''
(function() {
  var el = document.getElementById('$_containerId');
  if (!el) return;

  // Remove old canvas if re-rendering
  var old = el.querySelector('canvas');
  if (old) old.remove();

  var DATA = JSON.parse($quotedDataJson);
  var NODES = DATA.nodes || [];
  var LINKS = DATA.links || [];
  var TITLE = DATA.title || '';
  var SUBTITLE = DATA.subtitle || '';

  var canvas = document.createElement('canvas');
  canvas.style.cssText = 'display:block;width:100%;height:100%;cursor:default;';
  el.appendChild(canvas);

  var dpr = window.devicePixelRatio || 1;

  // ── Tooltip element ───────────────────────────────────────────────────────
  var tip = document.createElement('div');
  tip.style.cssText = 'position:absolute;pointer-events:none;display:none;background:rgba(10,20,40,0.92);'
    + 'color:#f1f5f9;font:12px "Inter",sans-serif;padding:8px 12px;border-radius:8px;'
    + 'border:1px solid rgba(99,179,237,0.35);box-shadow:0 4px 16px rgba(0,0,0,0.5);'
    + 'white-space:nowrap;z-index:999;max-width:260px;line-height:1.6;';
  el.style.position = 'relative';
  el.appendChild(tip);

  var hoveredRibbon = null;   // {l, path2d, srcLabel, tgtLabel}
  var ribbonPaths   = [];     // built each render, used for hit-test

  // ── Helpers ──────────────────────────────────────────────────────────────
  function fmtNum(v) {
    try { return Number(v||0).toLocaleString('en-US',{minimumFractionDigits:1,maximumFractionDigits:1}); }
    catch(_) { return String(Math.round((v||0)*10)/10); }
  }

  function hexToRgb(hex) {
    if (!hex || hex.length < 7) return '74,144,217';
    return parseInt(hex.slice(1,3),16)+','+parseInt(hex.slice(3,5),16)+','+parseInt(hex.slice(5,7),16);
  }

  // ── Main render function ─────────────────────────────────────────────────
  function render() {
    var W = el.offsetWidth || 900;
    var H = el.offsetHeight || 500;
    if (W < 80 || H < 80) return;

    canvas.width  = Math.round(W * dpr);
    canvas.height = Math.round(H * dpr);
    var ctx = canvas.getContext('2d');
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, W, H);

    // ── Layout constants ─────────────────────────────────────────────────
    var PL=130, PR=200, PT=60, PB=30;
    var NW=16, NGAP=5, MIN_H=4;
    var plotW = W - PL - PR;
    var plotH = H - PT - PB;
    if (plotW < 50 || plotH < 50) return;

    // ── Group by depth ───────────────────────────────────────────────────
    var byDepth = {}, maxDepth = 0;
    NODES.forEach(function(n) {
      var d = n.depth||0;
      if (!byDepth[d]) byDepth[d] = [];
      byDepth[d].push(n);
      if (d > maxDepth) maxDepth = d;
    });

    // ── Build adjacency (topology only, no positions yet) ────────────────
    var childLinks = {}, parentLinks = {};
    NODES.forEach(function(n){ childLinks[n.id]=[]; parentLinks[n.id]=[]; });
    LINKS.forEach(function(l){
      if (childLinks[l.source])  childLinks[l.source].push(l);
      if (parentLinks[l.target]) parentLinks[l.target].push(l);
    });

    // ── Node bar heights: bottom-up from terminal power values ──────────
    // Terminal bars: sqrt-proportional to value → normalized to fill plotH.
    // Non-terminal bars: sum of their children's bar heights (propagated up).
    // Ribbon height from A→B = B's bar height (ribbon fills target face exactly).
    // This gives source=full height, each tier shrinks naturally with power.
    var termNodes = byDepth[maxDepth] || [];
    var termGapPx = Math.max(termNodes.length - 1, 0) * NGAP;
    var availH    = Math.max(plotH - termGapPx, termNodes.length * 3);

    // sqrt of value (floor=1 so zero nodes still get a thin bar)
    var sqrtV = {};
    termNodes.forEach(function(n){ sqrtV[n.id] = Math.sqrt(Math.max(n.value||0, 1)); });
    var sqrtSum = termNodes.reduce(function(s,n){ return s + sqrtV[n.id]; }, 0) || 1;

    var nodePxH = {};
    // Proportional terminal heights
    termNodes.forEach(function(n){
      nodePxH[n.id] = Math.max(sqrtV[n.id] / sqrtSum * availH, 3);
    });
    // Cap outliers at 5× average, re-normalize
    var avgT = availH / Math.max(termNodes.length, 1);
    var capH = avgT * 5;
    termNodes.forEach(function(n){ if (nodePxH[n.id] > capH) nodePxH[n.id] = capH; });
    var capSum = termNodes.reduce(function(s,n){ return s + nodePxH[n.id]; }, 0) || 1;
    termNodes.forEach(function(n){ nodePxH[n.id] = nodePxH[n.id] / capSum * availH; });

    // Propagate up: each non-terminal bar = sum of its children bars
    for (var d = maxDepth - 1; d >= 0; d--) {
      (byDepth[d]||[]).forEach(function(n){
        var h = childLinks[n.id].reduce(function(s,l){ return s + (nodePxH[l.target]||3); }, 0);
        nodePxH[n.id] = Math.max(h, 3);
      });
    }

    // ── Ribbon thickness from real-time link values ───────────────────────
    // Each source distributes its bar-height budget to outgoing ribbons
    // proportional to the actual measured value (l.value = real-time power/energy).
    // sqrt-scale prevents one large value from collapsing all others.
    // MIN_RH ensures even zero-value links remain visible as a thin line.
    var MIN_RH = 3;
    var ribbonPx = {};
    NODES.forEach(function(srcNode) {
      var links = childLinks[srcNode.id];
      if (!links.length) return;
      var cnt    = links.length;
      var budget = Math.max(nodePxH[srcNode.id] - cnt * MIN_RH, 0);
      var sqrts  = links.map(function(l){ return Math.sqrt(Math.max(l.value||0, 0)); });
      var sqrSum = sqrts.reduce(function(s,v){ return s+v; }, 0) || 1;
      links.forEach(function(l, i){
        ribbonPx[l.source+'__'+l.target] = MIN_RH + sqrts[i] / sqrSum * budget;
      });
    });
    function ribbonH(l) { return ribbonPx[l.source+'__'+l.target] || MIN_RH; }

    // ── Position nodes column by column, center vertically ───────────────
    var nodePos = {};
    for (var dep = 0; dep <= maxDepth; dep++) {
      var col = byDepth[dep] || [];
      if (!col.length) continue;
      var xPos = PL + (maxDepth > 0 ? dep / maxDepth : 0) * plotW;
      var colH = col.reduce(function(s,n){ return s + nodePxH[n.id]; }, 0)
               + Math.max(col.length-1, 0) * NGAP;
      var colScale = colH > plotH ? plotH / colH : 1.0;
      var curY = PT + (plotH - colH * colScale) / 2;
      col.forEach(function(n) {
        var h = Math.max(nodePxH[n.id] * colScale, 4);
        nodePos[n.id] = { x: xPos, y: curY, h: h, color: n.color || '#4A90D9' };
        curY += h + NGAP;
      });
    }

    // ── Sort links to avoid crossings ────────────────────────────────────
    // Outgoing: order by target node Y (top→bottom)
    // Incoming: order by source node Y then by source's outgoing order so
    // ribbons at each node face stack in the same top-to-bottom direction.
    NODES.forEach(function(n){
      childLinks[n.id].sort(function(a,b){
        var ya = nodePos[a.target] ? nodePos[a.target].y : 0;
        var yb = nodePos[b.target] ? nodePos[b.target].y : 0;
        return ya - yb;
      });
    });
    // Build outgoing rank map for cross-free incoming sort
    var outRank = {};
    NODES.forEach(function(n){
      childLinks[n.id].forEach(function(l, i){ outRank[l.source+'__'+l.target] = i; });
    });
    NODES.forEach(function(n){
      parentLinks[n.id].sort(function(a,b){
        // Sort by source Y first, then by rank within source's outgoing stack
        var sya = nodePos[a.source] ? nodePos[a.source].y : 0;
        var syb = nodePos[b.source] ? nodePos[b.source].y : 0;
        if (sya !== syb) return sya - syb;
        return (outRank[a.source+'__'+a.target]||0) - (outRank[b.source+'__'+b.target]||0);
      });
    });

    // ── Drawing offsets — center ribbon stacks within each node face ──────
    var srcOff = {}, tgtOff = {};
    NODES.forEach(function(n){
      var pos = nodePos[n.id];
      if (!pos) { srcOff[n.id]=0; tgtOff[n.id]=0; return; }
      var outTotal = childLinks[n.id].reduce(function(s,l){ return s+ribbonH(l); }, 0);
      var inTotal  = parentLinks[n.id].reduce(function(s,l){ return s+ribbonH(l); }, 0);
      srcOff[n.id] = Math.max(pos.h - outTotal, 0) / 2;
      tgtOff[n.id] = Math.max(pos.h - inTotal,  0) / 2;
    });

    // ── Draw ribbons ─────────────────────────────────────────────────────
    var ordLinks = [];
    NODES.forEach(function(n){ childLinks[n.id].forEach(function(l){ ordLinks.push(l); }); });

    ribbonPaths = [];  // reset for hit-testing

    // Build a node-label lookup
    var nodeLabel = {};
    NODES.forEach(function(n){ nodeLabel[n.id] = n.label; });

    ordLinks.forEach(function(l) {
      var src = nodePos[l.source], tgt = nodePos[l.target];
      if (!src || !tgt) return;

      var rh = ribbonH(l);
      var x0 = src.x + NW, x1 = tgt.x;
      var y0t = src.y + srcOff[l.source];
      var y1t = tgt.y + tgtOff[l.target];
      var y0b = y0t + rh, y1b = y1t + rh;
      srcOff[l.source] += rh;
      tgtOff[l.target] += rh;

      var mx  = (x0 + x1) / 2;
      var rgb = hexToRgb(src.color);

      // Build Path2D for hit-testing
      var p = new Path2D();
      p.moveTo(x0, y0t);
      p.bezierCurveTo(mx, y0t, mx, y1t, x1, y1t);
      p.lineTo(x1, y1b);
      p.bezierCurveTo(mx, y1b, mx, y0b, x0, y0b);
      p.closePath();

      var isHovered = hoveredRibbon && hoveredRibbon.key === (l.source+'__'+l.target);
      ribbonPaths.push({ key: l.source+'__'+l.target, path: p, l: l,
                         srcLabel: nodeLabel[l.source]||l.source,
                         tgtLabel: nodeLabel[l.target]||l.target,
                         rgb: rgb });

      var alpha0 = isHovered ? 1.0  : 0.88;
      var alpha1 = isHovered ? 0.95 : 0.75;
      var alpha2 = isHovered ? 0.80 : 0.55;
      var grad = ctx.createLinearGradient(x0, 0, x1, 0);
      grad.addColorStop(0,   'rgba('+rgb+','+alpha0+')');
      grad.addColorStop(0.5, 'rgba('+rgb+','+alpha1+')');
      grad.addColorStop(1,   'rgba('+rgb+','+alpha2+')');
      ctx.fillStyle = grad;

      // Dim non-hovered ribbons when something is hovered
      if (hoveredRibbon && !isHovered) {
        ctx.fillStyle = 'rgba('+rgb+',0.18)';
      }

      ctx.fill(p);

      // Bright outline on hover
      if (isHovered) {
        ctx.strokeStyle = 'rgba(255,255,255,0.55)';
        ctx.lineWidth   = 1.2;
        ctx.stroke(p);
      }
    });

    // ── Draw node bars ────────────────────────────────────────────────────
    NODES.forEach(function(n) {
      var pos = nodePos[n.id];
      if (!pos) return;
      ctx.fillStyle = pos.color;
      ctx.fillRect(pos.x, pos.y, NW, pos.h);
      ctx.fillStyle = 'rgba(255,255,255,0.20)';
      ctx.fillRect(pos.x, pos.y, NW, Math.min(4, pos.h));
    });

    // ── Draw labels ───────────────────────────────────────────────────────
    NODES.forEach(function(n) {
      var pos = nodePos[n.id];
      if (!pos) return;
      var dep = n.depth || 0;
      var cy  = pos.y + pos.h / 2;
      var val = Math.max(n.value||0, 0);
      var vStr = fmtNum(val) + ' ' + (n.unit||'kW');

      if (dep === 0) {
        ctx.textAlign = 'right';
        ctx.fillStyle = '#f1f5f9'; ctx.font = 'bold 11px "Inter",sans-serif';
        ctx.fillText(n.label, pos.x - 10, cy - 7);
        ctx.fillStyle = '#7dd3fc'; ctx.font = '9px "Inter",sans-serif';
        ctx.fillText(n.mappingLabel||'', pos.x - 10, cy + 4);
        ctx.fillStyle = '#cbd5e1'; ctx.font = '10px "Inter",sans-serif';
        ctx.fillText(vStr, pos.x - 10, cy + 15);
      } else if (dep === maxDepth) {
        ctx.textAlign = 'left';
        // Always show label for terminal nodes — anchor to node top if bar is tiny
        var labelY = pos.h >= 18 ? cy - 3 : (pos.h >= 9 ? cy + 4 : pos.y + 8);
        ctx.fillStyle = '#f1f5f9'; ctx.font = 'bold 10px "Inter",sans-serif';
        ctx.fillText(n.label, pos.x + NW + 8, labelY);
        if (pos.h >= 18) {
          ctx.fillStyle = '#94a3b8'; ctx.font = '9px "Inter",sans-serif';
          ctx.fillText(vStr, pos.x + NW + 8, labelY + 11);
        }
      } else {
        ctx.textAlign = 'left';
        ctx.fillStyle = '#e2e8f0'; ctx.font = 'bold 10px "Inter",sans-serif';
        if (pos.h >= 18) {
          ctx.fillText(n.label, pos.x + NW + 6, cy - 4);
          ctx.fillStyle = '#94a3b8'; ctx.font = '9px "Inter",sans-serif';
          ctx.fillText(vStr, pos.x + NW + 6, cy + 8);
        } else if (pos.h >= 9) {
          ctx.fillText(n.label, pos.x + NW + 6, cy + 4);
        }
      }
    });

    // ── Title ─────────────────────────────────────────────────────────────
    ctx.textAlign = 'left';
    ctx.fillStyle = '#dbeafe'; ctx.font = 'bold 13px "Inter",sans-serif';
    ctx.fillText(TITLE, 18, 24);
    if (SUBTITLE) {
      ctx.fillStyle = '#93c5fd'; ctx.font = '10px "Inter",sans-serif';
      ctx.fillText(SUBTITLE, 18, 40);
    }
  }

  render();

  // ── Mouse interaction ─────────────────────────────────────────────────────
  canvas.addEventListener('mousemove', function(e) {
    var rect = canvas.getBoundingClientRect();
    var mx = (e.clientX - rect.left) * dpr;
    var my = (e.clientY - rect.top)  * dpr;

    var hit = null;
    // Check last ribbon first (drawn on top)
    for (var i = ribbonPaths.length - 1; i >= 0; i--) {
      var ctx2 = canvas.getContext('2d');
      if (ctx2.isPointInPath(ribbonPaths[i].path, mx, my)) {
        hit = ribbonPaths[i]; break;
      }
    }

    var prevKey = hoveredRibbon ? hoveredRibbon.key : null;
    var newKey  = hit ? hit.key : null;
    if (prevKey !== newKey) {
      hoveredRibbon = hit;
      render();
    }

    if (hit) {
      canvas.style.cursor = 'pointer';
      var lv   = hit.l.value || 0;
      var unit = lv > 500 ? 'kWh' : 'kW';
      var html = '<b style="color:#7dd3fc">' + hit.srcLabel + '</b>'
               + ' <span style="color:#64748b">→</span> '
               + '<b style="color:#86efac">' + hit.tgtLabel + '</b><br>'
               + '<span style="color:#94a3b8">Power flow: </span>'
               + '<b style="color:#fbbf24">' + Number(lv).toLocaleString('en-US',{minimumFractionDigits:1,maximumFractionDigits:1}) + ' ' + unit + '</b>';
      tip.innerHTML = html;
      tip.style.display = 'block';
      var tx = e.clientX - rect.left + 14;
      var ty = e.clientY - rect.top  - 10;
      if (tx + 200 > rect.width)  tx = e.clientX - rect.left - 210;
      if (ty + 60  > rect.height) ty = e.clientY - rect.top  - 70;
      tip.style.left = tx + 'px';
      tip.style.top  = ty + 'px';
    } else {
      canvas.style.cursor = 'default';
      tip.style.display = 'none';
    }
  });

  canvas.addEventListener('mouseleave', function() {
    if (hoveredRibbon) { hoveredRibbon = null; render(); }
    tip.style.display = 'none';
    canvas.style.cursor = 'default';
  });

  // Re-render on container resize
  if (typeof ResizeObserver !== 'undefined') {
    var ro = new ResizeObserver(function() { render(); });
    ro.observe(el);
  }

  el.dataset.echartsSankeyInited = '1';
  el.dataset.echartsReady = '1';
})();
''';
    html.document.body?.append(script);
    script.remove();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: widget.height,
          child: HtmlElementView(viewType: _viewType),
        ),
        if (_showFallback)
          Positioned.fill(
            child: Center(
              child: Text(
                'Canvas renderer failed.\nPlease hard refresh (Ctrl+F5).',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ),
          ),
      ],
    );
  }

  String _hex(Color c) {
    final r = c.red.toRadixString(16).padLeft(2, '0');
    final g = c.green.toRadixString(16).padLeft(2, '0');
    final b = c.blue.toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  Map<String, String> _primaryAncestorByNode(List<SankeyNode> nodes, List<SankeyLink> links) {
    final nodeById = {for (final n in nodes) n.id: n};
    final byDepth = <int, List<SankeyNode>>{};
    for (final n in nodes) byDepth.putIfAbsent(n.column, () => []).add(n);
    final depths = byDepth.keys.toList()..sort();
    if (depths.isEmpty) return {};
    final inc = <String, List<String>>{};
    for (final l in links) {
      final s = nodeById[l.sourceId], t = nodeById[l.targetId];
      if (s == null || t == null || t.column != s.column + 1) continue;
      inc.putIfAbsent(t.id, () => []).add(s.id);
    }
    byDepth[depths.first]!.sort((a, b) => b.value.compareTo(a.value));
    final col0List = byDepth[depths.first]!;
    final primaryAnc = <String, String>{for (final n in col0List) n.id: n.id};
    double linkWeight(String srcId, String tgtId) {
      for (final l in links) if (l.sourceId == srcId && l.targetId == tgtId) return l.value <= 0 ? 1.0 : l.value;
      return 1.0;
    }
    for (final depth in depths.skip(1)) {
      for (final n in byDepth[depth]!) {
        final parents = inc[n.id] ?? [];
        final counts = <String, double>{};
        for (final pid in parents) {
          final anc = primaryAnc[pid]; if (anc == null) continue;
          counts[anc] = (counts[anc] ?? 0) + linkWeight(pid, n.id);
        }
        if (counts.isNotEmpty) primaryAnc[n.id] = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      }
    }
    return primaryAnc;
  }

  List<SankeyNode> _orderedNodesForEcharts(List<SankeyNode> nodes, List<SankeyLink> links, int depthMax, int col0Count) {
    final base = _orderedNodes(nodes, links);
    if (base.isEmpty) return base;
    final byDepth = <int, List<SankeyNode>>{};
    for (final n in base) byDepth.putIfAbsent(n.column, () => []).add(n);
    final depths = byDepth.keys.toList()..sort();
    final lastCol = byDepth[depthMax];
    final roots = byDepth[depths.first];
    final singleRootMultiTier = col0Count == 1 && depthMax >= 2;
    if (!singleRootMultiTier && lastCol != null && lastCol.length > 1 && roots != null) {
      final rank = {for (int i = 0; i < roots.length; i++) roots[i].id: i};
      if (col0Count == 1) {
        lastCol.sort((a, b) { final c = b.value.compareTo(a.value); return c != 0 ? c : a.label.toLowerCase().compareTo(b.label.toLowerCase()); });
      } else {
        final anc = _primaryAncestorByNode(nodes, links);
        lastCol.sort((a, b) {
          final ra = rank[anc[a.id] ?? ''] ?? 999, rb = rank[anc[b.id] ?? ''] ?? 999;
          if (ra != rb) return ra.compareTo(rb);
          final cv = b.value.compareTo(a.value);
          return cv != 0 ? cv : a.label.toLowerCase().compareTo(b.label.toLowerCase());
        });
      }
    }
    final out = <SankeyNode>[];
    for (final d in depths) out.addAll(byDepth[d]!);
    return out;
  }

  List<SankeyNode> _orderedNodes(List<SankeyNode> nodes, List<SankeyLink> links) {
    if (nodes.isEmpty) return nodes;
    final byDepth = <int, List<SankeyNode>>{};
    for (final n in nodes) byDepth.putIfAbsent(n.column, () => <SankeyNode>[]).add(n);
    final depths = byDepth.keys.toList()..sort();
    final nodeById = {for (final n in nodes) n.id: n};
    final inc = <String, List<String>>{};
    for (final l in links) {
      final s = nodeById[l.sourceId], t = nodeById[l.targetId];
      if (s == null || t == null || t.column != s.column + 1) continue;
      inc.putIfAbsent(t.id, () => <String>[]).add(s.id);
    }
    byDepth[depths.first]!.sort((a, b) => b.value.compareTo(a.value));
    final col0List = byDepth[depths.first]!;
    final col0AncPos = <String, int>{for (int i = 0; i < col0List.length; i++) col0List[i].id: i};
    final primaryAnc = <String, String>{};
    for (final n in col0List) primaryAnc[n.id] = n.id;
    double linkWeight(String srcId, String tgtId) {
      for (final l in links) if (l.sourceId == srcId && l.targetId == tgtId) return l.value <= 0 ? 1.0 : l.value;
      return 1.0;
    }
    for (final depth in depths.skip(1)) {
      for (final n in byDepth[depth]!) {
        final parents = inc[n.id] ?? [];
        final counts = <String, double>{};
        for (final pid in parents) {
          final anc = primaryAnc[pid]; if (anc == null) continue;
          counts[anc] = (counts[anc] ?? 0) + linkWeight(pid, n.id);
        }
        if (counts.isNotEmpty) primaryAnc[n.id] = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      }
    }
    double? baryAdjacent(SankeyNode n, Map<String, int> prevOrder) {
      final incoming = links.where((l) { if (l.targetId != n.id) return false; final src = nodeById[l.sourceId]; return src != null && src.column == n.column - 1; }).toList();
      if (incoming.isEmpty) return null;
      double wSum = 0, pSum = 0;
      for (final l in incoming) { final pos = prevOrder[l.sourceId]; if (pos == null) continue; final w = l.value <= 0 ? 1.0 : l.value; wSum += w; pSum += pos * w; }
      return wSum == 0 ? null : pSum / wSum;
    }
    double? baryChildren(SankeyNode n, Map<String, int> nextOrder) {
      final outgoing = links.where((l) { if (l.sourceId != n.id) return false; final tgt = nodeById[l.targetId]; return tgt != null && tgt.column == n.column + 1; }).toList();
      if (outgoing.isEmpty) return null;
      double wSum = 0, pSum = 0;
      for (final l in outgoing) { final pos = nextOrder[l.targetId]; if (pos == null) continue; final w = l.value <= 0 ? 1.0 : l.value; wSum += w; pSum += pos * w; }
      return wSum == 0 ? null : pSum / wSum;
    }
    for (int iter = 0; iter < 3; iter++) {
      var prevOrder = <String, int>{for (int i = 0; i < col0List.length; i++) col0List[i].id: i};
      for (final depth in depths.skip(1)) {
        final cur = byDepth[depth]!;
      cur.sort((a, b) {
          final pa = col0AncPos[primaryAnc[a.id] ?? ''] ?? 999, pb = col0AncPos[primaryAnc[b.id] ?? ''] ?? 999;
          if (pa != pb) return pa.compareTo(pb);
          final ba = baryAdjacent(a, prevOrder), bb = baryAdjacent(b, prevOrder);
          if (ba == null && bb == null) return b.value.compareTo(a.value);
          if (ba == null) return 1; if (bb == null) return -1;
          final c = ba.compareTo(bb); return c != 0 ? c : b.value.compareTo(a.value);
      });
      prevOrder = {for (int i = 0; i < cur.length; i++) cur[i].id: i};
    }
      var nextOrder = prevOrder;
      for (final depth in depths.reversed.skip(1)) {
        final cur = byDepth[depth]!;
        cur.sort((a, b) {
          final pa = col0AncPos[primaryAnc[a.id] ?? ''] ?? 999, pb = col0AncPos[primaryAnc[b.id] ?? ''] ?? 999;
          if (pa != pb) return pa.compareTo(pb);
          final ba = baryChildren(a, nextOrder), bb = baryChildren(b, nextOrder);
          if (ba == null && bb == null) return b.value.compareTo(a.value);
          if (ba == null) return 1; if (bb == null) return -1;
          final c = ba.compareTo(bb); return c != 0 ? c : b.value.compareTo(a.value);
        });
        nextOrder = {for (int i = 0; i < cur.length; i++) cur[i].id: i};
      }
    }
    final flattened = <SankeyNode>[];
    for (final d in depths) flattened.addAll(byDepth[d]!);
    return flattened;
  }
}
