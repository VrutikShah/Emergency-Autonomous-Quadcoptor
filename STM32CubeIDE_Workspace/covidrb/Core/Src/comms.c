#include "comms.h"
#include "IMU/imu.h"
#include "usart.h"
#include "gpio.h"
//uint8_t sendTransmit = 1;
uint8_t transmitComplete = 0;

void uartTransmit(char *buf) {
//	int x = sizeof(buf);
//	for (int i = 0; i < x; i++) {
//		imudebug[i] = buf[i];
//	}
//	for (int i = x; i < 29; i++) {
//		buf[i] = ' ';
//	}
	if (transmitComplete == 1) {
//		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_RESET);
		HAL_UART_Transmit_DMA(&huart3, buf, 30);
		transmitComplete = 0;
	} else {
//		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_SET);
	}
//	transmitComplete = 0;

//	sendTransmit = 1;
//	if(transmitComplete == 1){
//		HAL_UART_Transmit_DMA(&huart3, imudebug, strlen(imudebug));
//		transmitComplete == 0;
//	}

}

void HAL_UART_TxCpltCallback(UART_HandleTypeDef *huart) {
//	HAL_UART_Transmit_DMA(&huart3, imudebug, sizeof(imudebug));
//	if(sendTransmit == 1){
//		HAL_UART_Transmit_DMA(&huart3, imudebug, strlen(imudebug));
//	}
//	else{
//		transmitComplete = 1;
//	}
//	sendTransmit = 0;
	transmitComplete = 1;

}

