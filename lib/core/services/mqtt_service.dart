import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

enum AppMqttStatus { disconnected, connecting, connected, error }

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  MqttService._internal();

  MqttServerClient? client;
  StreamSubscription? _subscription;
  bool _isInitializing = false;

  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  final ValueNotifier<AppMqttStatus> connectionState =
      ValueNotifier(AppMqttStatus.disconnected);
  final ValueNotifier<bool> isHardwareOnline = ValueNotifier(false);
  final ValueNotifier<double> humidity = ValueNotifier(1.0);
  final ValueNotifier<String> relayStatus = ValueNotifier("NORMAL");
  final ValueNotifier<bool> isAutoMode = ValueNotifier(true);
  final ValueNotifier<bool> isPumpOn = ValueNotifier(false);
  final ValueNotifier<bool> isLightOn = ValueNotifier(false);

  Future<void> init() async {
    if (_isInitializing) return;

    _isInitializing = true;
    connectionState.value = AppMqttStatus.connecting;

    final clientId = 'mj_debug_${Random().nextInt(999999)}';

    // FINAL ROBUST CONFIG: Back to EMQX Port 1883
    client = MqttServerClient('broker.emqx.io', clientId);
    client!.port = 1883;
    client!.setProtocolV311();
    client!.keepAlivePeriod = 60;
    client!.autoReconnect = true;
    client!.resubscribeOnAutoReconnect = true;
    client!.logging(on: true);

    client!.onConnected = _onConnected;
    client!.onDisconnected = _onDisconnected;
    client!.onSubscribed = _onSubscribed;
    client!.onAutoReconnect = () => debugPrint('MQTT: Attempting auto-reconnect...');
    client!.onAutoReconnected = () => debugPrint('MQTT: Auto-reconnect successful!');

    client!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();

    try {
      debugPrint('MQTT: Connecting as $clientId');

      final status = await client!.connect();

      if (status?.state != MqttConnectionState.connected) {
        debugPrint('MQTT: FAILED -> ${status?.state}');
        connectionState.value = AppMqttStatus.error;
        client!.disconnect();
        return;
      }

      debugPrint('MQTT: CONNECTED OK');
    } catch (e) {
      debugPrint('MQTT: EXCEPTION $e');
      connectionState.value = AppMqttStatus.error;
      client?.disconnect();
    } finally {
      _isInitializing = false;
    }
  }

  void _onConnected() {
    debugPrint('MQTT: Connected ✅');

    isConnected.value = true;
    connectionState.value = AppMqttStatus.connected;

    _subscribeAll();

    _subscription?.cancel();

    _subscription = client!.updates!.listen((events) {
      final recMess = events[0].payload as MqttPublishMessage;
      final topic = events[0].topic;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );

      debugPrint('MQTT RX [$topic] -> $payload');

      _processMessage(topic, payload);
    });
  }

  void _subscribeAll() {
    const topics = [
      "esp32/dht/kelembapan",
      "esp32/relay/status",
      "esp32/status",
      "esp32/status/mode",
      "esp32/status/pump",
      "esp32/status/light",
    ];

    for (final t in topics) {
      debugPrint('MQTT: Subscribing $t');
      client!.subscribe(t, MqttQos.atLeastOnce);
    }
  }

  void _processMessage(String topic, String payload) {
    final pt = payload.trim().toLowerCase();
    debugPrint('MQTT RX DEBUG: Topic=$topic, Payload=$pt');

    switch (topic) {
      case "esp32/dht/kelembapan":
        double val = double.tryParse(payload) ?? humidity.value;
        humidity.value = val < 1.0 ? 1.0 : val;
        break;

      case "esp32/relay/status":
        relayStatus.value = payload.toUpperCase();
        break;

      case "esp32/status":
        isHardwareOnline.value = (pt == "online");
        debugPrint('MQTT: Hardware -> ${isHardwareOnline.value}');
        break;

      case "esp32/status/mode":
        isAutoMode.value = (pt == "auto");
        break;

      case "esp32/status/pump":
        isPumpOn.value = (pt == "on");
        break;

      case "esp32/status/light":
        isLightOn.value = (pt == "on");
        break;
    }
  }

  void publishControl(String subTopic, String value) {
    if (client == null ||
        client!.connectionStatus?.state != MqttConnectionState.connected) {
      debugPrint('MQTT: publish blocked (not connected)');
      return;
    }

    final builder = MqttClientPayloadBuilder()..addString(value);
    final topic = "esp32/status/$subTopic";

    client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: true,
    );

    debugPrint('MQTT TX [$topic] -> $value');
  }

  void _onDisconnected() {
    debugPrint('MQTT: Disconnected ❌');

    isConnected.value = false;
    isHardwareOnline.value = false;

    if (connectionState.value != AppMqttStatus.error) {
      connectionState.value = AppMqttStatus.disconnected;
    }
  }


  void _onSubscribed(String topic) {
    debugPrint('MQTT: Subscribed $topic');
  }

  void disconnect() {
    _subscription?.cancel();
    client?.disconnect();
  }
}