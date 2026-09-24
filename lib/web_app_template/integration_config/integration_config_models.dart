class InfluxConfig {
  final String host;
  final String org;
  final String bucketRaw;
  final String bucketPredictions;
  final String bucketOee;
  final bool tokenSet;
  // In-memory only — never written to main Firestore doc; stored in secrets sub-collection
  final String token;
  final bool connected;
  final int? latencyMs;
  final String lastCheck;
  final int retryAttempts;
  final int retryInterval;
  final String onFailure;
  // Schema config — defines the InfluxDB data structure for this client
  final String measurement;
  final String deviceIdTag;
  final String deviceTypeTag;
  final String deviceTypeVal;

  const InfluxConfig({
    this.host = '',
    this.org = '',
    this.bucketRaw = 'energy_raw',
    this.bucketPredictions = '',
    this.bucketOee = '',
    this.tokenSet = false,
    this.token = '',
    this.connected = false,
    this.latencyMs,
    this.lastCheck = 'Never checked',
    this.retryAttempts = 3,
    this.retryInterval = 5,
    this.onFailure = 'last_value',
    this.measurement = 'power_meter',
    this.deviceIdTag = 'device_name',
    this.deviceTypeTag = '',
    this.deviceTypeVal = '',
  });

  factory InfluxConfig.fromMap(Map<String, dynamic> m) => InfluxConfig(
        host: m['host'] ?? '',
        org: m['org'] ?? '',
        bucketRaw: m['bucketRaw'] ?? 'energy_raw',
        bucketPredictions: m['bucketPredictions'] ?? '',
        bucketOee: m['bucketOee'] ?? '',
        tokenSet: m['tokenSet'] ?? false,
        // token is never in the main doc map — loaded separately from secrets
        connected: m['connected'] ?? false,
        latencyMs: m['latencyMs'],
        lastCheck: m['lastCheck'] ?? 'Never checked',
        retryAttempts: m['retryAttempts'] ?? 3,
        retryInterval: m['retryInterval'] ?? 5,
        onFailure: m['onFailure'] ?? 'last_value',
        measurement: m['measurement'] ?? 'power_meter',
        deviceIdTag: m['deviceIdTag'] ?? 'device_name',
        deviceTypeTag: m['deviceTypeTag'] ?? '',
        deviceTypeVal: m['deviceTypeVal'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'host': host,
        'org': org,
        'bucketRaw': bucketRaw,
        'bucketPredictions': bucketPredictions,
        'bucketOee': bucketOee,
        'tokenSet': tokenSet,
        'connected': connected,
        'latencyMs': latencyMs,
        'lastCheck': lastCheck,
        'retryAttempts': retryAttempts,
        'retryInterval': retryInterval,
        'onFailure': onFailure,
        'measurement': measurement,
        'deviceIdTag': deviceIdTag,
        'deviceTypeTag': deviceTypeTag,
        'deviceTypeVal': deviceTypeVal,
      };

  InfluxConfig copyWith({
    String? host,
    String? org,
    String? bucketRaw,
    String? bucketPredictions,
    String? bucketOee,
    bool? tokenSet,
    String? token,
    bool? connected,
    int? latencyMs,
    String? lastCheck,
    int? retryAttempts,
    int? retryInterval,
    String? onFailure,
    String? measurement,
    String? deviceIdTag,
    String? deviceTypeTag,
    String? deviceTypeVal,
  }) =>
      InfluxConfig(
        host: host ?? this.host,
        org: org ?? this.org,
        bucketRaw: bucketRaw ?? this.bucketRaw,
        bucketPredictions: bucketPredictions ?? this.bucketPredictions,
        bucketOee: bucketOee ?? this.bucketOee,
        tokenSet: tokenSet ?? this.tokenSet,
        token: token ?? this.token,
        connected: connected ?? this.connected,
        latencyMs: latencyMs ?? this.latencyMs,
        lastCheck: lastCheck ?? this.lastCheck,
        retryAttempts: retryAttempts ?? this.retryAttempts,
        retryInterval: retryInterval ?? this.retryInterval,
        onFailure: onFailure ?? this.onFailure,
        measurement: measurement ?? this.measurement,
        deviceIdTag: deviceIdTag ?? this.deviceIdTag,
        deviceTypeTag: deviceTypeTag ?? this.deviceTypeTag,
        deviceTypeVal: deviceTypeVal ?? this.deviceTypeVal,
      );
}

class MysqlConfig {
  final String host;
  final String port;
  final String database;
  final String username;
  final bool passwordSet;
  final bool connected;
  final int? latencyMs;
  final String lastCheck;
  final int retryAttempts;
  final int retryInterval;
  final String onFailure;

  const MysqlConfig({
    this.host = '',
    this.port = '3306',
    this.database = '',
    this.username = '',
    this.passwordSet = false,
    this.connected = false,
    this.latencyMs,
    this.lastCheck = 'Never checked',
    this.retryAttempts = 3,
    this.retryInterval = 5,
    this.onFailure = 'last_value',
  });

  factory MysqlConfig.fromMap(Map<String, dynamic> m) => MysqlConfig(
        host: m['host'] ?? '',
        port: m['port'] ?? '3306',
        database: m['database'] ?? '',
        username: m['username'] ?? '',
        passwordSet: m['passwordSet'] ?? false,
        connected: m['connected'] ?? false,
        latencyMs: m['latencyMs'],
        lastCheck: m['lastCheck'] ?? 'Never checked',
        retryAttempts: m['retryAttempts'] ?? 3,
        retryInterval: m['retryInterval'] ?? 5,
        onFailure: m['onFailure'] ?? 'last_value',
      );

  Map<String, dynamic> toMap() => {
        'host': host,
        'port': port,
        'database': database,
        'username': username,
        'passwordSet': passwordSet,
        'connected': connected,
        'latencyMs': latencyMs,
        'lastCheck': lastCheck,
        'retryAttempts': retryAttempts,
        'retryInterval': retryInterval,
        'onFailure': onFailure,
      };

  MysqlConfig copyWith({
    String? host,
    String? port,
    String? database,
    String? username,
    bool? passwordSet,
    bool? connected,
    int? latencyMs,
    String? lastCheck,
    int? retryAttempts,
    int? retryInterval,
    String? onFailure,
  }) =>
      MysqlConfig(
        host: host ?? this.host,
        port: port ?? this.port,
        database: database ?? this.database,
        username: username ?? this.username,
        passwordSet: passwordSet ?? this.passwordSet,
        connected: connected ?? this.connected,
        latencyMs: latencyMs ?? this.latencyMs,
        lastCheck: lastCheck ?? this.lastCheck,
        retryAttempts: retryAttempts ?? this.retryAttempts,
        retryInterval: retryInterval ?? this.retryInterval,
        onFailure: onFailure ?? this.onFailure,
      );
}

class FirebaseConfig {
  final String projectId;
  final String clientEmail;
  final bool secretSet;

  const FirebaseConfig({
    this.projectId = '',
    this.clientEmail = '',
    this.secretSet = false,
  });

  factory FirebaseConfig.fromMap(Map<String, dynamic> m) => FirebaseConfig(
        projectId: m['projectId'] ?? '',
        clientEmail: m['clientEmail'] ?? '',
        secretSet: m['secretSet'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'projectId': projectId,
        'clientEmail': clientEmail,
        'secretSet': secretSet,
      };

  FirebaseConfig copyWith({
    String? projectId,
    String? clientEmail,
    bool? secretSet,
  }) =>
      FirebaseConfig(
        projectId: projectId ?? this.projectId,
        clientEmail: clientEmail ?? this.clientEmail,
        secretSet: secretSet ?? this.secretSet,
      );
}

class ChannelMapping {
  final String sf365Field;  // standard field key used by SF365 widgets
  final String influxField; // actual field name in client's InfluxDB
  final String label;       // human-readable label
  final String unit;        // e.g. kW, kWh, V, A

  ChannelMapping({
    required this.sf365Field,
    required this.influxField,
    this.label = '',
    this.unit = '',
  });

  factory ChannelMapping.fromMap(Map<String, dynamic> m) => ChannelMapping(
        sf365Field: m['sf365Field'] ?? '',
        influxField: m['influxField'] ?? '',
        label: m['label'] ?? '',
        unit: m['unit'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'sf365Field': sf365Field,
        'influxField': influxField,
        'label': label,
        'unit': unit,
      };

  ChannelMapping copyWith({String? sf365Field, String? influxField, String? label, String? unit}) =>
      ChannelMapping(
        sf365Field: sf365Field ?? this.sf365Field,
        influxField: influxField ?? this.influxField,
        label: label ?? this.label,
        unit: unit ?? this.unit,
      );

  // Default SF365 standard channel list
  static List<ChannelMapping> get defaults => [
        ChannelMapping(sf365Field: 'P_W',   influxField: 'P_W',   label: 'Active Power',    unit: 'kW'),
        ChannelMapping(sf365Field: 'kWh',   influxField: 'kWh',   label: 'Energy',          unit: 'kWh'),
        ChannelMapping(sf365Field: 'PF',    influxField: 'PF',    label: 'Power Factor',    unit: ''),
        ChannelMapping(sf365Field: 'V_L1',  influxField: 'V_L1',  label: 'Voltage L1',      unit: 'V'),
        ChannelMapping(sf365Field: 'V_L2',  influxField: 'V_L2',  label: 'Voltage L2',      unit: 'V'),
        ChannelMapping(sf365Field: 'V_L3',  influxField: 'V_L3',  label: 'Voltage L3',      unit: 'V'),
        ChannelMapping(sf365Field: 'I_A',   influxField: 'I_A',   label: 'Current A',       unit: 'A'),
        ChannelMapping(sf365Field: 'I_B',   influxField: 'I_B',   label: 'Current B',       unit: 'A'),
        ChannelMapping(sf365Field: 'I_C',   influxField: 'I_C',   label: 'Current C',       unit: 'A'),
        ChannelMapping(sf365Field: 'kVAR',  influxField: 'kVAR',  label: 'Reactive Power',  unit: 'kVAR'),
        ChannelMapping(sf365Field: 'kVA',   influxField: 'kVA',   label: 'Apparent Power',  unit: 'kVA'),
      ];
}

class SiteTag {
  final String tag;
  final String plant;
  SiteTag({required this.tag, required this.plant});
  factory SiteTag.fromMap(Map<String, dynamic> m) =>
      SiteTag(tag: m['tag'] ?? '', plant: m['plant'] ?? '');
  Map<String, dynamic> toMap() => {'tag': tag, 'plant': plant};
}

class HistoryEntry {
  final String ts;
  final String who;
  final String msg;
  final String? diffOld;
  final String? diffNew;
  HistoryEntry({required this.ts, required this.who, required this.msg, this.diffOld, this.diffNew});
  factory HistoryEntry.fromMap(Map<String, dynamic> m) => HistoryEntry(
        ts: m['ts'] ?? '',
        who: m['who'] ?? '',
        msg: m['msg'] ?? '',
        diffOld: m['diffOld'],
        diffNew: m['diffNew'],
      );
  Map<String, dynamic> toMap() =>
      {'ts': ts, 'who': who, 'msg': msg, 'diffOld': diffOld, 'diffNew': diffNew};
}

class HealthLogEntry {
  final String time;
  final String level; // ok | warn | err | info
  final String message;
  HealthLogEntry({required this.time, required this.level, required this.message});
  factory HealthLogEntry.fromMap(Map<String, dynamic> m) =>
      HealthLogEntry(time: m['time'] ?? '', level: m['level'] ?? 'info', message: m['message'] ?? '');
  Map<String, dynamic> toMap() => {'time': time, 'level': level, 'message': message};
}

class SetupChecklist {
  final bool created;
  final bool influx;
  final bool mysql;
  final bool stag;
  final bool channel;
  final bool perms;
  final bool live;

  const SetupChecklist({
    this.created = false,
    this.influx = false,
    this.mysql = false,
    this.stag = false,
    this.channel = false,
    this.perms = false,
    this.live = false,
  });

  factory SetupChecklist.fromMap(Map<String, dynamic> m) => SetupChecklist(
        created: m['created'] ?? false,
        influx: m['influx'] ?? false,
        mysql: m['mysql'] ?? false,
        stag: m['stag'] ?? false,
        channel: m['channel'] ?? false,
        perms: m['perms'] ?? false,
        live: m['live'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'created': created,
        'influx': influx,
        'mysql': mysql,
        'stag': stag,
        'channel': channel,
        'perms': perms,
        'live': live,
      };

  int get pct {
    final vals = [created, influx, mysql, stag, channel, perms, live];
    return ((vals.where((v) => v).length / vals.length) * 100).round();
  }

  SetupChecklist copyWith({
    bool? created,
    bool? influx,
    bool? mysql,
    bool? stag,
    bool? channel,
    bool? perms,
    bool? live,
  }) =>
      SetupChecklist(
        created: created ?? this.created,
        influx: influx ?? this.influx,
        mysql: mysql ?? this.mysql,
        stag: stag ?? this.stag,
        channel: channel ?? this.channel,
        perms: perms ?? this.perms,
        live: live ?? this.live,
      );
}

class ClientConfig {
  final String id; // doc id = client code lowercase
  final String name;
  final String code;
  final String plan;
  final String domain;
  final String contact;
  final List<String> plants;
  final InfluxConfig influx;
  final MysqlConfig mysql;
  final FirebaseConfig firebase;
  final List<SiteTag> siteTags;
  final List<ChannelMapping> channelMappings;
  final SetupChecklist checklist;
  final List<HistoryEntry> history;
  final List<HealthLogEntry> healthLog;

  const ClientConfig({
    required this.id,
    required this.name,
    required this.code,
    this.plan = 'Trial',
    required this.domain,
    this.contact = '—',
    this.plants = const [],
    this.influx = const InfluxConfig(),
    this.mysql = const MysqlConfig(),
    this.firebase = const FirebaseConfig(),
    this.siteTags = const [],
    this.channelMappings = const [],
    this.checklist = const SetupChecklist(created: true),
    this.history = const [],
    this.healthLog = const [],
  });

  factory ClientConfig.fromMap(String id, Map<String, dynamic> m) {
    return ClientConfig(
      id: id,
      name: m['name'] ?? '',
      code: m['code'] ?? id.toUpperCase(),
      plan: m['plan'] ?? 'Trial',
      domain: m['domain'] ?? '',
      contact: m['contact'] ?? '—',
      plants: List<String>.from(m['plants'] ?? []),
      influx: InfluxConfig.fromMap(m['influx'] ?? {}),
      mysql: MysqlConfig.fromMap(m['mysql'] ?? {}),
      firebase: FirebaseConfig.fromMap(m['firebase'] ?? {}),
      siteTags: (m['siteTags'] as List? ?? [])
          .map((e) => SiteTag.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      channelMappings: (m['channelMappings'] as List? ?? [])
          .map((e) => ChannelMapping.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      checklist: SetupChecklist.fromMap(m['checklist'] ?? {}),
      history: (m['history'] as List? ?? [])
          .map((e) => HistoryEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      healthLog: (m['healthLog'] as List? ?? [])
          .map((e) => HealthLogEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }


  Map<String, dynamic> toMap() => {
        'name': name,
        'code': code,
        'plan': plan,
        'domain': domain,
        'contact': contact,
        'plants': plants,
        'influx': influx.toMap(),
        'mysql': mysql.toMap(),
        'firebase': firebase.toMap(),
        'siteTags': siteTags.map((s) => s.toMap()).toList(),
        'channelMappings': channelMappings.map((c) => c.toMap()).toList(),
        'checklist': checklist.toMap(),
        'history': history.map((h) => h.toMap()).toList(),
        'healthLog': healthLog.map((l) => l.toMap()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      };

  ClientConfig copyWith({
    String? name,
    String? code,
    String? plan,
    String? domain,
    String? contact,
    List<String>? plants,
    InfluxConfig? influx,
    MysqlConfig? mysql,
    FirebaseConfig? firebase,
    List<SiteTag>? siteTags,
    List<ChannelMapping>? channelMappings,
    SetupChecklist? checklist,
    List<HistoryEntry>? history,
    List<HealthLogEntry>? healthLog,
  }) =>
      ClientConfig(
        id: id,
        name: name ?? this.name,
        code: code ?? this.code,
        plan: plan ?? this.plan,
        domain: domain ?? this.domain,
        contact: contact ?? this.contact,
        plants: plants ?? this.plants,
        influx: influx ?? this.influx,
        mysql: mysql ?? this.mysql,
        firebase: firebase ?? this.firebase,
        siteTags: siteTags ?? this.siteTags,
        channelMappings: channelMappings ?? this.channelMappings,
        checklist: checklist ?? this.checklist,
        history: history ?? this.history,
        healthLog: healthLog ?? this.healthLog,
      );
}
