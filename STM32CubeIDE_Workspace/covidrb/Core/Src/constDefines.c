/*
 * constDefines.c
 *
 *  Created on: 10-Jul-2020
 *      Author: pveen
 */

#include "constDefines.h"
#include "gpio.h"


void blinkLED(int numberOn, int duration) {
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_SET);
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_RESET);
	if (numberOn == 0) {
		return;
	}
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_SET);
	int delay = (int) duration / numberOn;
	for (int i = 0; i < numberOn; i++) {
		HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_8);
		HAL_Delay((int) delay / 2);
		HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_8);
		HAL_Delay((int) delay / 2);
	}
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_SET);
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_RESET);

}
