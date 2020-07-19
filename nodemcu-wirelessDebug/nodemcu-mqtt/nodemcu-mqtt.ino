
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
String clientId = "drone-" + String(ESP.getChipId());

int i = 0;
int flag = -1;
uint8_t number;
int datalength;
char datapayload[30] = "                 ";
int bytesSent;
int x = 0;
char received[30] = "                 ";
int SUARTBaud = 9600;
void beginUART();
void beginWIFI();


void dataCallback(char* topic, byte* payload, unsigned int length)
{
  char payloadStr[length + 1];
  memset(payloadStr, 0, length + 1);
  strncpy(payloadStr, (char*)payload, length);
  //  flag = 2;
  //TOPIC CHOOSER
  for (int i = 0; i < 50; i++) {
    if (topic[i] == '\0') {
      break;
    }
    if (topic[i] == '/') {
      if (topic[i + 1] == 'c' && topic[i + 2] == 'm' && topic[i + 3] == 'd'  && topic[i + 4] == 's') { //topic for cmds
        flag = 2;
        strncpy(datapayload, (char*)payloadStr, length);
      }
      else if (topic[i + 1] == 'o' && topic[i + 2] == 'p' && topic[i + 3] == 'e'  && topic[i + 4] == 'n' && topic[i + 5] == 'm' && topic[i + 6] == 'v') { //topic for openmv
        
        char *ptr = payloadStr;
        const char s[2] = ";";
        ptr = strtok(ptr, s);
        ptr = strtok(NULL, ptr);
        Serial.printf( ptr);
        double distance = atof(ptr);
        Serial.printf( "%f", distance);
        if(distance < 5){
          flag = 2;
          strncpy(datapayload, "t7;0.0;0.0;0.0;                  ", 30);
        }
      }
      break;
    }
  }
  Serial.printf("Data    : %s. Topic : [%s]\n", payloadStr,  topic);
  
}

void performConnect()
{
  uint16_t connectionDelay = 5000;
  digitalWrite(LED_BUILTIN, HIGH);
  while (!mqttClient.connected())
  {
    Serial.printf("Trace   : Attempting MQTT connection...\n");
    if (mqttClient.connect(clientId.c_str(), MQTT_USERNAME, MQTT_KEY))
    {
      Serial.printf("Trace   : Connected to Broker.\n");

      /* Subscription to your topic after connection was succeeded.*/
      MQTTSubscribe("pveenvenkatesh@gmail.com/gps");
      MQTTSubscribe("pveenvenkatesh@gmail.com/openmv");
      MQTTSubscribe("pveenvenkatesh@gmail.com/cmds");
      digitalWrite(LED_BUILTIN, LOW);

    }
    else
    {
      Serial.printf("Error!  : MQTT Connect failed, rc = %d\n", mqttClient.state());
      Serial.printf("Trace   : Trying again in %d msec.\n", connectionDelay);
      delay(connectionDelay);
    }
  }
}

boolean MQTTPublish(char* topic, char* payload)
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
  Serial.println("Subscribed to " + String(topicToSubscribe));
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
  if (mqttInitCompleted)
  {
    if (!MQTTIsConnected())
    {
      performConnect();
    }
    mqttClient.loop();
  }
}

void setup() {
  Serial.begin(9600);
  beginWIFI();
  beginUART();
  MQTTBegin();
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(2, OUTPUT);
}
void beginUART() {

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
int len = 0;
void resetReceived() {
  for (int i = 0; i < 29; i++) {
    received[i] = ' ';
  }
  received[29] = '\0';
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
      len = 0;
      Serial.print("Receiving: ");

    }
    else if (c == '>') {
      //      received = received + '\n';
      len += 1;
      received[len] = '\n';
      received[len + 1] = '\0';
      Serial.println(received);
      MQTTPublish(PUBTOPIC, received);
      resetReceived();
      i = 1;
    }
    else {
      //      received = received + c;

      received[len] = c;
      len += 1;
    }
  }
}

void flagExecute() {
  if (flag == 2) {

    Serial.printf("[%u] get Text: %s\r\n", number, datapayload);
    resetReceived();
    i = 1;
    bytesSent = SUART.write(datapayload, 30);
    Serial.print( bytesSent);
    Serial.print(" (");
    Serial.write(datapayload, 30);
    Serial.println(") bytes were sent to stm32");
    flag = 0;
  }
}
