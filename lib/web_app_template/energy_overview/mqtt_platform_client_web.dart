import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient createMqttClient(String brokerUrl, String clientId) {
  return MqttBrowserClient(brokerUrl, clientId);
}

