
#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <Hash.h>
#include<SoftwareSerial.h>
#include "Credentials.h"
#include <PubSubClient.h>
SoftwareSerial SUART( D1, D2); //SRX  = DPin-D2; STX = DPin-D1
WiFiClient wifiClient;
PubSubClient mqttClient(wifiClient);
boolean mqttInitCompleted = false;
String clientId = "IoTPractice-" + String(ESP.getChipId());


int i = 0;
int flag = -1;
uint8_t number;
int datalength;
char datapayload[30] = "                 ";
int bytesSent;
int x = 0;
String received = "";


int SUARTBaud = 9600;

//void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length);
void beginUART();
void beginWIFI();


void dataCallback(char* topic, byte* payload, unsigned int length)
{
  char payloadStr[length + 1];
  memset(payloadStr, 0, length + 1);
  strncpy(payloadStr, (char*)payload, length);
  flag = 2;
  Serial.printf("Data    : dataCallback. Topic : [%s]\n", topic);
  Serial.printf("Data    : dataCallback. Payload : %s\n", payloadStr);
}

void performConnect()
{
  uint16_t connectionDelay = 5000;
  while (!mqttClient.connected())
  {
    Serial.printf("Trace   : Attempting MQTT connection...\n");
    if (mqttClient.connect(clientId.c_str(), MQTT_USERNAME, MQTT_KEY))
    {
      Serial.printf("Trace   : Connected to Broker.\n");

      /* Subscription to your topic after connection was succeeded.*/
      MQTTSubscribe(TOPIC);
    }
    else
    {
      Serial.printf("Error!  : MQTT Connect failed, rc = %d\n", mqttClient.state());
      Serial.printf("Trace   : Trying again in %d msec.\n", connectionDelay);
      delay(connectionDelay);
    }
  }
}

boolean MQTTPublish(const char* topic, char* payload)
{
  boolean retval = false;
  if (mqttClient.connected())
  {
    retval = mqttClient.publish(topic, payload);
  }
  return retval;
}

boolean MQTTSubscribe(const char* topicToSubscribe)
{
  boolean retval = false;
  if (mqttClient.connected())
  {
    retval = mqttClient.subscribe(topicToSubscribe);
  }
  return retval;
}

boolean MQTTIsConnected()
{
  return mqttClient.connected();
}

void MQTTBegin()
{
  mqttClient.setServer(MQTT_BROKER, MQTT_BROKER_PORT);
  mqttClient.setCallback(dataCallback);
  mqttInitCompleted = true;
}

void MQTTLoop()
{
  if(mqttInitCompleted)
  {
    if (!MQTTIsConnected())
    {
      performConnect();
    }
    mqttClient.loop();
  }
}

void setup() {
  beginUART();
  beginWIFI();
  MQTTBegin();
}
void beginUART() {
  Serial.begin(9600);
  Serial.setDebugOutput(true);
  Serial.printf("\nStarting UART with stm32 at %d\n", SUARTBaud);
  SUART.begin(SUARTBaud);   //NodeMCU prefers higher Bd to work
}
void beginWIFI() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(STA_SSID, STA_PASS);
  Serial.print(" Connecting...");

  while (WiFi.status() != WL_CONNECTED) {
    Serial.print('.');
    delay(500);
  }
  IPAddress ip = WiFi.localIP();
  Serial.printf("\nConnected to WiFi. IP : %d.%d.%d.%d\n",
                ip[0], ip[1], ip[2], ip[3]);
}

void loop() {
  MQTTLoop();
  flagExecute();
  while (SUART.available()) {
    MQTTLoop();
    if (flag != 0) {
      flagExecute();
      break;
    }

    char c = SUART.read();
    Serial.write(c);
    if (c == '<') {
      i = 0;
      Serial.print("Receiving: ");
      received = "";
    }
    else if (c == '>') {
      received = received + '\n';
      Serial.print(received);
      received = "";
      i = 1;
    }
    else {
      received = received + c;

    }
  }
}
void flagExecute() {
  if (flag == 2) {
    Serial.printf("[%u] get Text: %s\r\n", number, datapayload);
    received = "";
    i = 1;
    bytesSent = SUART.write(datapayload, 30);
    Serial.print( bytesSent);
    Serial.print(" (");
    Serial.write(datapayload, 30);
    Serial.println(") bytes were sent to stm32");
    flag = 0;
  }
}
