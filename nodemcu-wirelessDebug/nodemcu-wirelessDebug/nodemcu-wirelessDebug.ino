

#include <ESP8266WiFi.h>
#include <WiFiClient.h>
//#include <ESP8266WebServer.h>
#include <WebSocketsServer.h>
#include <Hash.h>
#include<SoftwareSerial.h>

SoftwareSerial SUART( D2, D1); //SRX  = DPin-D2; STX = DPin-D1

const char* ssid = "LMEE";
const char* password = "praveenv";

int x = 0;
String received = "";
String sending = "                 ";
WebSocketsServer webSocket = WebSocketsServer(81);
  int SUARTBaud = 9600;
  
void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length);

void setup() {
  Serial.begin(115200);
  Serial.setDebugOutput(true);
  Serial.printf("Starting UART with stm32 at %d\n", SUARTBaud);
  SUART.begin(SUARTBaud);   //NodeMCU prefers higher Bd to work
//  WiFi.mode(WIFI_STA);
//  WiFi.begin(ssid, password);
//
//  Serial.print(" Connecting...");
//  
//  while (WiFi.status() != WL_CONNECTED) {
//    Serial.print('.');
//    delay(500);
//   }
   
//    digitalWrite(LED_BUILTIN, HIGH);

    WiFi.mode(WIFI_AP);
    WiFi.softAP("ESP8266");
    IPAddress IP = WiFi.softAPIP();
    Serial.println("");
    Serial.print("Connected to ");
    Serial.println("ESP8266");
    Serial.print("IP address: ");
    Serial.println(IP);

    webSocket.begin();
    webSocket.onEvent(webSocketEvent);
    
}
int i = 0;
void loop() {
    webSocket.loop();

   while(SUART.available()){
    webSocket.loop();
    char c = SUART.read();
    if(c == '<'){
      i = 0;
      Serial.print("Receiving: ");
    }
    else if(c == '>'){ 
      received = received + '\n';
      Serial.print(received);
      webSocket.broadcastTXT( received);
      received = "";
      i = 1;
    }
    else {
      received = received + c;
    
    }
   }      
}

void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length){
    Serial.printf("webSocketEvent(%d, %d, ...)\r\n", num, type);
     int bytesSent;
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.printf("[%u] Disconnected!\r\n", num);
      
      break;
    case WStype_CONNECTED:
      {
        IPAddress ip = webSocket.remoteIP(num);
        webSocket.broadcastTXT("s2");
        Serial.printf("[%u] Connected from %d.%d.%d.%d url: %s\r\n", num, ip[0], ip[1], ip[2], ip[3], payload);
        // Send the current LED status
      }
      break;
    case WStype_TEXT:
      Serial.printf("[%u] get Text: %s\r\n", num, payload);
//      webSocket.broadcastTXT(payload + '\n');
      received = "";
      i = 0;

      bytesSent = SUART.write(payload, 30);
      Serial.print( bytesSent);
      Serial.print(" (");
      Serial.write(payload,20);
      Serial.println(") bytes were sent to stm32");
      break;
    case WStype_BIN:
      Serial.printf("[%u] get binary length: %u\r\n", num, length);
      hexdump(payload, length);
      webSocket.sendBIN(num, payload, length);
      break;
    default:
      Serial.printf("Invalid WStype [%d]\r\n", type);
      break;
  }
}
