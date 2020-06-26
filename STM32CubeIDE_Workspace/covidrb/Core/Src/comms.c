#include "comms.h"


uint8_t transmitcomplete = 1;
void uartTransmit(char buf[]){
	if(transmitComplete == 1){
		HAL_UART_Transmit_DMA(&huart3, debugData, sizeof(debugData));
	}
	transmit = 0;
}

void HAL_UART_TxCpltCallback(UART_HandleTypeDef *huart) {
	transmit = 1;

}
