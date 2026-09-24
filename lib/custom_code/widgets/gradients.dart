// Automatic FlutterFlow imports
// Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

class Gradients extends StatefulWidget {
  const Gradients({
    super.key,
    this.width,
    this.height,
    this.gradientStyle,
    this.animationDuration,
    this.containerColor,
    this.borderWidth,
    this.borderRadius,
    this.text,
  });

  final double? width;
  final double? height;
  final String? gradientStyle;
  final int? animationDuration;
  final Color? containerColor;
  final double? borderWidth;
  final double? borderRadius;
  final String? text;
  static const Map<String, List<Color>> gradientSets = {
    'Rainbow': [
      Color(0XFF2AA8F2),
      Color(0XFF9C4F96),
      Color(0xFFFF6355),
      Color(0XFFFBA949),
      Color(0XFFFAE442),
      Color(0XFF8BD448),
      Color(0XFF2AA8F2),
    ],
    'Trident': [
      Colors.blue,
      Colors.purple,
      Colors.green,
    ],
    'Beach': [
      Color(0XFF016698),
      Color(0XFF269CA9),
      Color(0xFF3EC1A8),
      Color(0XFFEAD7A5),
      Color(0XFFE1BBA7),
      Color(0XFFA7A5A0),
    ],
    'PastelDreams': [
      Color(0xFFFFCCCC),
      Color(0xFFCC99FF),
      Color(0xFF99CCFF),
      Color(0xFF99FF99),
      Color(0xFFFFFF99),
    ],
    'LushMeadow': [
      Color(0xFF228B22),
      Color(0xFF556B2F),
      Color(0xFF8FBC8F),
      Color(0xFF00FA9A),
      Color(0xFF32CD32),
    ],
    'SunriseRadiance': [
      Color(0xFFFFDAB9),
      Color(0xFFFF6347),
      Color(0xFFFF4500),
      Color(0xFFFFD700),
      Color(0xFFFFFF00),
      Color(0xFFFFA500),
    ],
  };

  @override
  State<Gradients> createState() => _GradientsState();
}

class _GradientsState extends State<Gradients>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.animationDuration ?? 2),
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    List<Color> gradientColors =
        Gradients.gradientSets.containsKey(widget.gradientStyle)
            ? Gradients.gradientSets[widget.gradientStyle]!
            : Gradients.gradientSets['PastelDreams']!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final t = _animation.value;

        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment(
                  -2.0 + 2.0 * t,
                  -1.0,
                ),
                end: Alignment(
                  2.0 + 2.0 * t,
                  1.0,
                ),
              ),
            ),
            child: Container(
              width: widget.width,
              height: widget.height,
              margin: EdgeInsets.all(widget.borderWidth ?? 0),
              decoration: BoxDecoration(
                color: widget.containerColor,
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 0),
              ),
              child: Text(
                widget.text ?? "",
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
