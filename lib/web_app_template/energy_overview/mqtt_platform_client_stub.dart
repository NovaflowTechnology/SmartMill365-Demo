import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createMqttClient(String brokerUrl, String clientId) {
  final uri = Uri.tryParse(brokerUrl);
  final host = (uri?.host.isNotEmpty == true) ? uri!.host : brokerUrl;
  final port = (uri?.hasPort == true) ? uri!.port : 1883;
  return MqttServerClient.withPort(host, clientId, port);
}

