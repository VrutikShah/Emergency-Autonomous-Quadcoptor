long starttime;
void setup() {
  // put your setup code here, to run once:
Serial.begin(9600);
pinMode(A0, INPUT);
starttime = millis();
}

void loop() {
  // put your main code here, to run repeatedly:
  if(millis() - starttime > 5000){
    Serial.println(analogRead(A0));
    starttime = millis();
  }

}
