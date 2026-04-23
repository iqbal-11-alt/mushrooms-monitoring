#include <WiFi.h>
#include <PubSubClient.h>
#include <DHT.h>

// ================= WIFI =================
const char* ssid = "Shanum_4G";
const char* password = "12345678";

// ================= MQTT =================
const char* mqtt_server = "broker.hivemq.com";

WiFiClient espClient;
PubSubClient client(espClient);

// ================= DHT =================
#define DHTPIN 4
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);

// ================= RELAY =================
#define RELAY1 27
#define RELAY2 26

// Relay aktif LOW
#define RELAY_ON  LOW
#define RELAY_OFF HIGH

// ================= THRESHOLD =================
float batasPanas = 70.0;
float batasLembab = 90.0;

// ================= GLOBAL STATE =================
unsigned long lastMsg = 0;
String statusRelay = "INIT";
bool isAutoMode = true;
bool manualPump = false;
bool manualLight = false;

// ================= WIFI =================
void setup_wifi() {
  delay(10);
  Serial.println("Connecting to WiFi...");
  
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi connected!");
}

// ================= MQTT CALLBACK =================
void callback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("] ");
  Serial.println(message);

  if (String(topic) == "esp32/control/mode") {
    isAutoMode = (message == "auto");
    Serial.println(isAutoMode ? "Mode: AUTO" : "Mode: MANUAL");
  } 
  else if (String(topic) == "esp32/control/pump") {
    manualPump = (message == "on");
    Serial.println(manualPump ? "Manual Pump: ON" : "Manual Pump: OFF");
  }
  else if (String(topic) == "esp32/control/light") {
    manualLight = (message == "on");
    Serial.println(manualLight ? "Manual Light: ON" : "Manual Light: OFF");
  }
}

// ================= MQTT RECONNECT =================
void reconnect() {
  while (!client.connected()) {
    Serial.print("Connecting MQTT...");
    
    if (client.connect("ESP32Client", "esp32/status", 0, true, "offline")) {
      Serial.println("connected");
      client.publish("esp32/status", "online", true);
      
      // Subscribe to control topics
      client.subscribe("esp32/control/mode");
      client.subscribe("esp32/control/pump");
      client.subscribe("esp32/control/light");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" coba lagi...");
      delay(2000);
    }
  }
}

void setup() {
  Serial.begin(115200);

  pinMode(RELAY1, OUTPUT);
  pinMode(RELAY2, OUTPUT);

  digitalWrite(RELAY1, RELAY_OFF);
  digitalWrite(RELAY2, RELAY_OFF);

  dht.begin();

  setup_wifi();
  client.setServer(mqtt_server, 1883);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  unsigned long now = millis();

  if (now - lastMsg > 2000) {
    lastMsg = now;

    float suhu = dht.readTemperature();
    float kelembapan = dht.readHumidity();

    if (isnan(suhu) || isnan(kelembapan)) {
      Serial.println("Gagal baca DHT!");
      return;
    }

    // ================= CONTROL LOGIC =================
    if (isAutoMode) {
      // Automatic Mode (Sensor Based)
      bool kondisiLembab = (kelembapan > batasLembab);
      bool kondisiPanas = (suhu > batasPanas);

      digitalWrite(RELAY1, kondisiLembab ? RELAY_ON : RELAY_OFF);
      digitalWrite(RELAY2, kondisiPanas ? RELAY_ON : RELAY_OFF);

      if (kondisiPanas && kondisiLembab) statusRelay = "PANAS+LEMBAB";
      else if (kondisiPanas) statusRelay = "PANAS";
      else if (kondisiLembab) statusRelay = "LEMBAB";
      else statusRelay = "NORMAL";
    } else {
      // Manual Mode (App Based)
      digitalWrite(RELAY1, manualPump ? RELAY_ON : RELAY_OFF);
      digitalWrite(RELAY2, manualLight ? RELAY_ON : RELAY_OFF);
      statusRelay = "MANUAL";
    }

    // ================= STATUS REPORTING =================
    bool currentPump = (digitalRead(RELAY1) == RELAY_ON);
    bool currentLight = (digitalRead(RELAY2) == RELAY_ON);

    client.publish("esp32/dht/suhu", String(suhu).c_str());
    client.publish("esp32/dht/kelembapan", String(kelembapan).c_str());
    client.publish("esp32/relay/status", statusRelay.c_str());
    client.publish("esp32/status/pump", currentPump ? "on" : "off", true);
    client.publish("esp32/status/light", currentLight ? "on" : "off", true);
    client.publish("esp32/status/mode", isAutoMode ? "auto" : "manual", true);

    // Serial Debug
    Serial.print("Mode: "); Serial.print(isAutoMode ? "AUTO" : "MANUAL");
    Serial.print(" | Hum: "); Serial.print(kelembapan);
    Serial.print("% | Pump: "); Serial.print(currentPump ? "ON" : "OFF");
    Serial.print(" | Light: "); Serial.println(currentLight ? "ON" : "OFF");
  }
}