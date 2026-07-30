#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <PubSubClient.h>
#include <DHT.h>

// ================= SUPABASE =================
const char* supabase_url = "https://hpmicdhjyboyeofphgae.supabase.co";
const char* supabase_key = "sb_publishable_OB8e9y1OO0z3Y5xQ828YvA_T3jD16zT";

// ================= WIFI =================
const char* ssid = "Shanum_4G";
const char* password = "12345678";

// ================= MQTT =================
const char* mqtt_server = "broker.emqx.io";

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

// State Tracking for Upload
bool prevPump = false;
bool prevLight = false;
unsigned long lastPeriodicUpload = 0;

// ================= SUPABASE UPLOAD =================
void uploadToSupabase(float hum, String status, String lamp, String pump) {
  if (WiFi.status() == WL_CONNECTED) {
    WiFiClientSecure clientSecure;
    clientSecure.setInsecure(); 
    HTTPClient http;
    
    String url = String(supabase_url) + "/rest/v1/humidity";
    http.begin(clientSecure, url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("apikey", supabase_key);
    http.addHeader("Authorization", "Bearer " + String(supabase_key));
    http.addHeader("Prefer", "return=minimal");

    String json = "{\"kelembapan\":" + String(hum) + 
                  ",\"status\":\"" + status + "\"" +
                  ",\"status_lampu\":\"" + lamp + "\"" +
                  ",\"status_pompa\":\"" + pump + "\"}";

    Serial.println("[Supabase] Uploading data...");
    int httpCode = http.POST(json);
    if (httpCode > 0) {
      Serial.printf("[Supabase] POST success, code: %d\n", httpCode);
    } else {
      Serial.printf("[Supabase] POST failed, error: %s\n", http.errorToString(httpCode).c_str());
    }
    http.end();
  }
}

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

  if (String(topic) == "esp32/statusiqbal/mode") {
    isAutoMode = (message == "auto");
    Serial.println(isAutoMode ? "Mode: AUTO" : "Mode: MANUAL");
  } 
  else if (String(topic) == "esp32/statusiqbal/pump") {
    manualPump = (message == "on");
    Serial.println(manualPump ? "Manual Pump: ON" : "Manual Pump: OFF");
  }
  else if (String(topic) == "esp32/statusiqbal/light") {
    manualLight = (message == "on");
    Serial.println(manualLight ? "Manual Light: ON" : "Manual Light: OFF");
  }
}

// ================= MQTT RECONNECT =================
void reconnect() {
  while (!client.connected()) {
    Serial.print("Connecting MQTT...");
    
    if (client.connect("ESP32Client", "esp32/statusiqbal", 0, true, "offline")) {
      Serial.println("connected");
      client.publish("esp32/statusiqbal", "online", true);
      
      // Subscribe to control topics
      client.subscribe("esp32/statusiqbal/mode");
      client.subscribe("esp32/statusiqbal/pump");
      client.subscribe("esp32/statusiqbal/light");
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
      // Logic: <70% Pump ON, Lamp OFF | >90% Lamp ON, Pump OFF | 70-90% NORMAL (OFF/OFF)
      if (kelembapan < 70.0) {
        digitalWrite(RELAY1, RELAY_ON);  // Pompa Hidup
        digitalWrite(RELAY2, RELAY_OFF); // Lampu Mati
        statusRelay = "KERING / PENYIRAMAN";
      } 
      else if (kelembapan > 90.0) {
        digitalWrite(RELAY1, RELAY_OFF); // Pompa Mati
        digitalWrite(RELAY2, RELAY_ON);  // Lampu Nyala
        statusRelay = "TERLALU LEMBAB";
      } 
      else {
        digitalWrite(RELAY1, RELAY_OFF); // Pompa Mati
        digitalWrite(RELAY2, RELAY_OFF); // Lampu Mati
        statusRelay = "NORMAL";
      }
    } else {
      // Manual Mode (App Based)
      digitalWrite(RELAY1, manualPump ? RELAY_ON : RELAY_OFF);
      digitalWrite(RELAY2, manualLight ? RELAY_ON : RELAY_OFF);
      statusRelay = "MANUAL";
    }

    // ================= STATUS REPORTING =================
    bool currentPump = (digitalRead(RELAY1) == RELAY_ON);
    bool currentLight = (digitalRead(RELAY2) == RELAY_ON);

    // Upload logic: Action transition OR Periodic (30 mins) if Normal
    unsigned long nowMillis = millis();
    bool actionDetected = (currentPump != prevPump || currentLight != prevLight);
    // Interval 30 menit = 1800000 ms
    bool isPeriodicTime = (nowMillis - lastPeriodicUpload >= 1800000);

    if (actionDetected || (statusRelay == "NORMAL" && isPeriodicTime)) {
      String statusLampuUpload = currentLight ? (isAutoMode ? "MENYALA - OTOMATIS" : "MENYALA - MANUAL") : "MATI";
      String statusPompaUpload = currentPump ? (isAutoMode ? "MENYALA - OTOMATIS" : "MENYALA - MANUAL") : "MATI";

      uploadToSupabase(kelembapan, statusRelay, statusLampuUpload, statusPompaUpload);
      lastPeriodicUpload = nowMillis;
    }
    
    // MQTT Reporting
    client.publish("esp32/dht/suhu", String(suhu).c_str());
    client.publish("esp32/dht/kelembapan", String(kelembapan).c_str());
    client.publish("esp32/relay/status", statusRelay.c_str());
    client.publish("esp32/statusiqbal/pump", currentPump ? "on" : "off", true);
    client.publish("esp32/statusiqbal/light", currentLight ? "on" : "off", true);
    client.publish("esp32/statusiqbal/mode", isAutoMode ? "auto" : "manual", true);

    // Save states
    prevPump = currentPump;
    prevLight = currentLight;

    // Serial Debug
    Serial.print("Mode: "); Serial.print(isAutoMode ? "AUTO" : "MANUAL");
    Serial.print(" | Hum: "); Serial.print(kelembapan);
    Serial.print("% | Pump: "); Serial.print(currentPump ? "ON" : "OFF");
    Serial.print(" | Light: "); Serial.println(currentLight ? "ON" : "OFF");
    Serial.print(" | Status: "); Serial.println(statusRelay);
  }
}