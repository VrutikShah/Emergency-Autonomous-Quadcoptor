#include "comms.h"
#include "IMU/imu.h"
#include "usart.h"
#include "gpio.h"
//uint8_t sendTransmit = 1;
uint8_t transmitComplete = 0;

void uartTransmit(char *buf) {
	if (transmitComplete == 1) {
		HAL_UART_Transmit_DMA(&huart3, buf, 30);
		transmitComplete = 0;
	}

}

void HAL_UART_TxCpltCallback(UART_HandleTypeDef *huart) {

	transmitComplete = 1;

}

