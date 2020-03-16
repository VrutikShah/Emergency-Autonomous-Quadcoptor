#include <ESP8266WiFi.h>
#include <WiFiClient.h>
#include <ESP8266WebServer.h>
#include <WebSocketsServer.h>
#include <Hash.h>
#include<SoftwareSerial.h>

SoftwareSerial SUART( D2, D1); //SRX  = DPin-D2; STX = DPin-D1


const char* ssid = "LMEE";
const char* password = "praveenv";

String WebPage = "<!DOCTYPE html><html><style>input[type=\"text\"]{width: 90%; height: 3vh;}input[type=\"button\"]{width: 9%; height: 3.6vh;}.rxd{height: 90vh;}textarea{width: 99%; height: 100%; resize: none;}</style><script>var Socket;function start(){Socket=new WebSocket('ws://' + window.location.hostname + ':81/'); Socket.onmessage=function(evt){document.getElementById(\"rxConsole\").value +=evt.data;}}function enterpressed(){Socket.send(document.getElementById(\"txbuff\").value); document.getElementById(\"txbuff\").value=\"\";}</script><body onload=\"javascript:start();\"> <div><input class=\"txd\" type=\"text\" id=\"txbuff\" onkeydown=\"if(event.keyCode==13) enterpressed();\"><input class=\"txd\" type=\"button\" onclick=\"enterpressed();\" value=\"Send\" > </div><br><div class=\"rxd\"> <textarea id=\"rxConsole\" readonly></textarea> </div></body></html>";

WebSocketsServer webSocket = WebSocketsServer(81);
ESP8266WebServer server(80);
int clientID = -1;
void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length);
void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);

  Serial.println(" Connecting...");
  SUART.begin(9600);   //NodeMCU prefers higher Bd to work
  while (WiFi.status() != WL_CONNECTED) {
    delay(25);
    digitalWrite(LED_BUILTIN, HIGH);
    delay(25);
    digitalWrite(LED_BUILTIN, LOW);
    
   }
    digitalWrite(LED_BUILTIN, HIGH);
    Serial.println("");
    Serial.print("Connected to ");
    Serial.println(ssid);
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
    
    server.on("/", [](){
    server.send(200, "text/html", WebPage);
    });
    
    server.begin();
    
    webSocket.begin();
    webSocket.onEvent(webSocketEvent);
    
}

void loop() {
    webSocket.loop();
    server.handleClient();
    
      while(SUART.available()>0 && clientID == -1){
        Serial.println(SUART.readString());
      }
   
    if (SUART.available() > 0 && clientID != -1){
      String s = SUART.readString();
      s = s + "\n";
      Serial.print(" Received string from device: ");
      
      char a[40];
      s.toCharArray(a,40);
      Serial.println(a);
      webSocket.broadcastTXT( a, sizeof(s)-1); //String has a null terminator that we subtract 1 for.

      digitalWrite(LED_BUILTIN, HIGH);
    }
    else{
      digitalWrite(LED_BUILTIN, LOW);
    }
}

void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length){
    Serial.printf("webSocketEvent(%d, %d, ...)\r\n", num, type);
     int bytesSent;
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.printf("[%u] Disconnected!\r\n", num);
      clientID = num;
      break;
    case WStype_CONNECTED:
      {
        IPAddress ip = webSocket.remoteIP(num);
        Serial.printf("[%u] Connected from %d.%d.%d.%d url: %s\r\n", num, ip[0], ip[1], ip[2], ip[3], payload);
        // Send the current LED status
       clientID = num;
      }
      break;
    case WStype_TEXT:
      Serial.printf("[%u] get Text: %s\r\n", num, payload);
      

      webSocket.broadcastTXT(payload, length);
      
      bytesSent = SUART.write(payload, 20);
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
