import 'dart:io';
import 'dart:math';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

Future<void> main() async {
  print('--- MQTT WS TEST (WITH PREFIX) START ---');
  final String clientId = 'mj_test_${Random().nextInt(999)}';
  
  // WAJIB pakai ws:// agar library tidak error
  final client = MqttServerClient.withPort('ws://broker.hivemq.com', clientId, 8000);
  
  client.useWebSocket = true;
  client.keepAlivePeriod = 60;
  client.logging(on: true);

  final connMess = MqttConnectMessage()
      .withClientIdentifier(clientId)
      .startClean()
      .withWillQos(MqttQos.atLeastOnce);
  client.connectionMessage = connMess;

  try {
    print('Connecting to ws://broker.hivemq.com:8000...');
    await client.connect();
    
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('✅✅✅ YES! CONNECTED VIA WEBSOCKET! ✅✅✅');
      client.disconnect();
    } else {
      print('❌ FAILED: State is ${client.connectionStatus?.state}');
    }
  } catch (e) {
    print('❌ EXCEPTION: $e');
  }
  print('--- TEST END ---');
  exit(0);
}
