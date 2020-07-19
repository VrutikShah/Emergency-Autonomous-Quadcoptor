import paho.mqtt.client as mqtt  #import the client1
import time
import serial
import random

ser = serial.Serial('COM9', 9600, timeout=1)

startTime = time.time()
def on_connect(client, userdata, flags, rc):
    print("Connected with code:",str(rc))
    #Subscribing the topic
    client.subscribe("pveenvenkatesh@gmail.com/drone")

def on_message(client, userdata, msg):
    print(str(msg.payload))

client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

client.username_pw_set("pveenvenkatesh@gmail.com", "embedded")
client.connect("maqiatto.com", 1883, 60)

sensors = [
["0", "sCO2", 407.4, (407.4, 0.5)],
["1", "sHUM", 52, (52, 2)],
["2", "sTMP", 60, (60, 5)],
["3", "hLDR", 60, (0, 0)]
]
def updateSensors(op):
    for sensor in sensors:
        sensor[2] = round(random.gauss(sensor[3][0], sensor[3][1]),2)
    sensors[3][2] = op


client.loop_start()
time.sleep(1)
while time.time() - startTime < 100:
    output = ser.readline()
    for sensor in sensors:
        payload = sensor[0] + ';' +  sensor[1] + ';' + str(sensor[2]) +';'
        print(payload)
        output = ser.readline()
        client.publish("pveenvenkatesh@gmail.com/sensor", payload = payload)
        time.sleep(1.66)
        updateSensors(output)
client.loop_stop()
client.disconnect
print("Task completed successfully")