/* USER CODE BEGIN Header */
/**
 ******************************************************************************
 * @file           : main.c
 * @brief          : Main program body
 ******************************************************************************
 * @attention
 *
 * <h2><center>&copy; Copyright (c) 2020 STMicroelectronics.
 * All rights reserved.</center></h2>
 *
 * This software component is licensed by ST under BSD 3-Clause license,
 * the "License"; You may not use this file except in compliance with the
 * License. You may obtain a copy of the License at:
 *                        opensource.org/licenses/BSD-3-Clause
 *
 ******************************************************************************
 */
/* USER CODE END Header */

/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "dma.h"
#include "i2c.h"
#include "tim.h"
#include "usart.h"
#include "gpio.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "stdio.h"
#include "math.h"
#include "stdlib.h"
#include "IMU/imu.h"
#include "constDefines.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
uint8_t receivedData[30] = "012345678901234567890123456789";
uint8_t dataTypeToReturn = 255;
int motorsInit = 0;
int x = 0;
int initComplete = 0;

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
void initUART(void) {
	while (HAL_UART_Receive_DMA(&huart3, receivedData, 30) != HAL_OK) {
		blinkLED(2, 25);
	}
	blinkLED(2, 1000);

}

void escSet(uint32_t channel, uint16_t value) {
	__HAL_TIM_SET_COMPARE(&htim1, channel, value);
}
void initMotors(void) {
	HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_1);
	HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_2);
	HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_3);
	HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_4);
	escSet(TIM_CHANNEL_1, 500);
	escSet(TIM_CHANNEL_2, 500);
	escSet(TIM_CHANNEL_3, 500);
	escSet(TIM_CHANNEL_4, 500);
	uint8_t debugData[] = MOTORS_INIT;
	HAL_UART_Transmit_DMA(&huart3, debugData, sizeof(debugData));
//	HAL_Delay(2000);
}

void initIMU() {
	uint8_t debugData[] = IMU_INIT;
	HAL_UART_Transmit_DMA(&huart3, debugData, sizeof(debugData));
	MPU6050_initialize();
	DMP_Init();

}

void shutMotors(void) {
	HAL_TIM_PWM_Stop(&htim1, TIM_CHANNEL_1);
	HAL_TIM_PWM_Stop(&htim1, TIM_CHANNEL_2);
	HAL_TIM_PWM_Stop(&htim1, TIM_CHANNEL_3);
	HAL_TIM_PWM_Stop(&htim1, TIM_CHANNEL_4);
}
void setMotorsAcro(void) {

	for (int i = 0; i < 20; i++) {
		escSet(TIM_CHANNEL_1, 500 + 100 * i);
		escSet(TIM_CHANNEL_2, 500 + 100 * i);
		escSet(TIM_CHANNEL_3, 500 + 100 * i);
		escSet(TIM_CHANNEL_4, 500 + 100 * i);
		HAL_Delay(1500);
//		setTrim();
	}
}
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart) {

	if (receivedData[1] == ARM[0]) {
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_RESET);
		initMotors();

		motorsInit = 1;
	} else if (receivedData[1] == DISARM[0]) {
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_SET);
		shutMotors();

		motorsInit = 0;
	} else if (receivedData[1] == PID_KP_SEND[0]) {
		shutMotors();
		setPidValues(receivedData,PID_KP_SEND[0]);
		blinkLED(2, 500);
		initMotors();

	} else if (receivedData[1] == PID_KI_SEND[0]) {
		shutMotors();
		setPidValues(receivedData,PID_KI_SEND[0]);
		blinkLED(2, 500);
		initMotors();

	} else if (receivedData[1] == PID_KD_SEND[0]) {
		shutMotors();
		setPidValues(receivedData,PID_KD_SEND[0]);
		blinkLED(2, 500);
		initMotors();

	} else if (receivedData[1] == TRIM_SEND[0]) {

		shutMotors();
		setTrimValues(receivedData);
		blinkLED(2, 1000);
		initMotors();

	} else if (receivedData[1] == ACROMODE[0]) {
		motorsInit = 2;
		setMotorsAcro();
	}
	HAL_UART_Receive_DMA(huart, receivedData, 30);
//	else if (motorsInit == 0) {
//		initMotors();
//
//		motorsInit = 1;
//	} else if (motorsInit == 1) {
//		shutMotors();
//		motorsInit = 0;
//	}

}
void calibrateESC(void) {
	initMotors();
	HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_8);
	escSet(TIM_CHANNEL_1, 2500);
	escSet(TIM_CHANNEL_2, 2500);
	escSet(TIM_CHANNEL_3, 2500);
	escSet(TIM_CHANNEL_4, 2500);
	HAL_Delay(5000);
	HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_8);
	escSet(TIM_CHANNEL_1, 500);
	escSet(TIM_CHANNEL_2, 500);
	escSet(TIM_CHANNEL_3, 500);
	escSet(TIM_CHANNEL_4, 500);
	HAL_Delay(5000);
	HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_8);
	shutMotors();
}
void droneInit(void) {
	//initialize pwm signals.
//	sendInitValues();
	initUART();
	initIMU();
	calibrateIMU();

//	if (initComplete == 2) {

//		uint8_t debugData[] = ESC_CALIBRATE	;
//		HAL_UART_Transmit_DMA(&huart3, debugData, sizeof(debugData));

//	calibrateESC();
//	}

	uint8_t debugData[] = DISARMED;
	HAL_UART_Transmit_DMA(&huart3, debugData, sizeof(debugData));

	blinkLED(50, 1000);

}

/* USER CODE END 0 */

/**
 * @brief  The application entry point.
 * @retval int
 */
int main(void) {
	/* USER CODE BEGIN 1 */

	/* USER CODE END 1 */

	/* MCU Configuration--------------------------------------------------------*/

	/* Reset of all peripherals, Initializes the Flash interface and the Systick. */
	HAL_Init();

	/* USER CODE BEGIN Init */

	/* USER CODE END Init */

	/* Configure the system clock */
	SystemClock_Config();

	/* USER CODE BEGIN SysInit */

	/* USER CODE END SysInit */

	/* Initialize all configured peripherals */
	MX_GPIO_Init();
	MX_DMA_Init();
	MX_I2C1_Init();
	MX_TIM1_Init();
	MX_USART3_UART_Init();
	/* USER CODE BEGIN 2 */
//  blinkLED(10, 8000);
	droneInit();
	/* USER CODE END 2 */

	/* Infinite loop */
	/* USER CODE BEGIN WHILE */
	while (1) {
		/* USER CODE END WHILE */

		/* USER CODE BEGIN 3 */
		if (motorsInit == 1) {
			Read_DMP();
			computePID();
			setMotors();
			debugIMU();
//			HAL_Delay(pidLoopDelay);
		} else if (motorsInit == 0) {
			uint8_t debugData[] = DISARMED;
			HAL_UART_Transmit_DMA(&huart3, debugData, sizeof(debugData));
			HAL_Delay(1000);
		} else if (motorsInit == 2) { //Acro mode
			uint8_t debugData[] = ACROMODE;
			HAL_UART_Transmit_DMA(&huart3, debugData, sizeof(debugData));
			HAL_Delay(pidLoopDelay);
		}

	}
	/* USER CODE END 3 */
}

/**
 * @brief System Clock Configuration
 * @retval None
 */
void SystemClock_Config(void) {
	RCC_OscInitTypeDef RCC_OscInitStruct = { 0 };
	RCC_ClkInitTypeDef RCC_ClkInitStruct = { 0 };

	/** Initializes the CPU, AHB and APB busses clocks
	 */
	RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
	RCC_OscInitStruct.HSEState = RCC_HSE_ON;
	RCC_OscInitStruct.HSEPredivValue = RCC_HSE_PREDIV_DIV1;
	RCC_OscInitStruct.HSIState = RCC_HSI_ON;
	RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
	RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
	RCC_OscInitStruct.PLL.PLLMUL = RCC_PLL_MUL9;
	if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK) {
		Error_Handler();
	}
	/** Initializes the CPU, AHB and APB busses clocks
	 */
	RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_SYSCLK
			| RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2;
	RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
	RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
	RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
	RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

	if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK) {
		Error_Handler();
	}
}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/**
 * @brief  Period elapsed callback in non blocking mode
 * @note   This function is called  when TIM4 interrupt took place, inside
 * HAL_TIM_IRQHandler(). It makes a direct call to HAL_IncTick() to increment
 * a global variable "uwTick" used as application time base.
 * @param  htim : TIM handle
 * @retval None
 */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim) {
	/* USER CODE BEGIN Callback 0 */

	/* USER CODE END Callback 0 */
	if (htim->Instance == TIM4) {
		HAL_IncTick();
	}
	/* USER CODE BEGIN Callback 1 */

	/* USER CODE END Callback 1 */
}

/**
 * @brief  This function is executed in case of error occurrence.
 * @retval None
 */
void Error_Handler(void) {
	/* USER CODE BEGIN Error_Handler_Debug */
	/* User can add his own implementation to report the HAL error return state */

	/* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{ 
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     tex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */

/************************ (C) COPYRIGHT STMicroelectronics *****END OF FILE****/
