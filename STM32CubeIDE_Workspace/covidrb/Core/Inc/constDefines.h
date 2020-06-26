/*
 * constDefines.h
 *
 *  Created on: Mar 19, 2020
 *      Author: pveen
 */

#ifndef INC_CONSTDEFINES_H_
#define INC_CONSTDEFINES_H_

#define pidLoopDelay 25
#define imuLoopDelay pidLoopDelay - 10

//drone states
#define IDLE	"<s0>"
#define NETWORK_DISCONNECTED	"<s1>"
#define NETWORK_CONNECTED	"<s2>"
#define DRONE_INIT	"<s3>"
#define MOTORS_INIT	"<s4>"
#define IMU_CALIBRATING	"<s5>"
#define IMU_INIT "<s6>"
#define IMU_READY "<s9>"
#define DISARMED	"<s7>"
#define ARMED	"<s8>"
#define ESC_CALIBRATE "<sA>"
#define ARMED_ACRO "<sB>"


//requested state
#define ARM	"0"
#define DISARM	"1"
#define ACROMODE "2"
#define PID_KP_SEND "3"
#define TRIM_SEND "4"
#define PID_KD_SEND "5"
#define PID_KI_SEND "6"


#endif /* INC_CONSTDEFINES_H_ */
