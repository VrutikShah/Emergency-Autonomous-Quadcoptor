#include<SPI.h>

char buff[]="Hello Slave\n";
SPISettings SPIsetting(8000000, MSBFIRST, SPI_MODE0);
uint8_t receive[40];

//master nodemcu
//protocol:
//1) master begins transaction and sends transaction type data (send or receive, 1 byte, contains info of what data to send back)
//2) if master send, then slave waits for data reception.
//3) if master receive, and slave send, slave sends corresponding data.

void setup() {
  Serial.begin(115200);
 SPI.begin();
}

void loop() {
 for(int i=0; i < 40; i++)
 {
  receive[i] = SPI.transfer(buff[i]);
  Serial.print(receive[i]);
 }
 Serial.println();
 
 delay(1000);  
}
