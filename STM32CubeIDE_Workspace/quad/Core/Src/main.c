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
#include "cmsis_os.h"
#include "dma.h"
#include "i2c.h"
#include "tim.h"
#include "usart.h"
#include "gpio.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
//#define MPU6050_ADDR 0x68
//#define SMPLRT_DIV_REG 0x19
//#define GYRO_CONFIG_REG 0x1B
//#define ACCEL_CONFIG_REG 0x1C
//#define ACCEL_XOUT_H_REG 0x3B
//#define TEMP_OUT_H_REG 0x41
//#define GYRO_XOUT_H_REG 0x43
//#define PWR_MGMT_1_REG 0x6B
//#define WHO_AM_I_REG 0x75
#include "stdio.h"
#include "math.h"
#include "stdlib.h"
#include "IMU/imu.h"
#include "constDefines.h"
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */
//***********************VARIABLES*********************************
//int16_t Accel_X_RAW = 0;
//int16_t Accel_Y_RAW = 0;
//int16_t Accel_Z_RAW = 0;
//
//int16_t Gyro_X_RAW = 0;
//int16_t Gyro_Y_RAW = 0;
//int16_t Gyro_Z_RAW = 0;
//uint8_t data[] = "HELLO WORLllllllD\n\r";
//float Ax, Ay, Az, Gx, Gy, Gz;
//int8_t transmissionComplete = 1;
uint8_t receivedData[30] = "012345678901234567890123456789";
uint8_t dataTypeToReturn = 255;
int motorsInit = 0;
int x = 0;
int initComplete = 0;

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
void MX_FREERTOS_Init(void);
/* USER CODE BEGIN PFP */

void initIMU(void);
void debugLED(uint8_t);
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
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
  MX_I2C2_Init();
  MX_TIM2_Init();
  MX_USART1_UART_Init();
  /* USER CODE BEGIN 2 */
	initIMU();
	HAL_TIM_Base_Start(&htim2);
	HAL_TIM_PWM_Start(&htim2, TIM_CHANNEL_2);
	htim2.Instance->CCR1 = 50;

  /* USER CODE END 2 */

  /* Init scheduler */
  osKernelInitialize();  /* Call init function for freertos objects (in freertos.c) */
  MX_FREERTOS_Init(); 
  /* Start scheduler */
  osKernelStart();
 
  /* We should never get here as control is now taken by the scheduler */
  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
	int counter = 0;
	while (1) {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */

	}
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Initializes the CPU, AHB and APB busses clocks 
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.HSEPredivValue = RCC_HSE_PREDIV_DIV1;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLMUL = RCC_PLL_MUL9;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }
  /** Initializes the CPU, AHB and APB busses clocks 
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
  {
    Error_Handler();
  }
}

/* USER CODE BEGIN 4 */
void initIMU(void) {
	uint8_t check;
	uint8_t Data;

	HAL_I2C_Mem_Read(&hi2c2, 0x68, WHO_AM_I_REG, 1, &check, 1, 1000);
	Data = 0;
	if (check == 0x68) {
		Data = 0;
		HAL_I2C_Mem_Write(&hi2c2, MPU6050_ADDR, PWR_MGMT_1_REG, 1, &Data, 1,
				1000);

		// Set DATA RATE of 1KHz by writing SMPLRT_DIV register
		Data = 0x07;
		HAL_I2C_Mem_Write(&hi2c2, MPU6050_ADDR, SMPLRT_DIV_REG, 1, &Data, 1,
				1000);

		// Set accelerometer configuration in ACCEL_CONFIG Register
		// XA_ST=0,YA_ST=0,ZA_ST=0, FS_SEL=0 -> � 2g
		Data = 0x00;
		HAL_I2C_Mem_Write(&hi2c2, MPU6050_ADDR, ACCEL_CONFIG_REG, 1, &Data, 1,
				1000);

		// Set Gyroscopic configuration in GYRO_CONFIG Register
		// XG_ST=0,YG_ST=0,ZG_ST=0, FS_SEL=0 -> � 250 �/s
		Data = 0x00;
		HAL_I2C_Mem_Write(&hi2c2, MPU6050_ADDR, GYRO_CONFIG_REG, 1, &Data, 1,
				1000);
		HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_SET);

	} else {

	}
	debugLED(check);
}
void debugLED(uint8_t check) {

	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_RESET);
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_RESET);
	HAL_Delay(1000);
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_SET);
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_SET);
	HAL_Delay(1000);
	for (int i = 0; i < 8; i++) {
		HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_8);
		if (((check >> i) & 1) == 0) {
			HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_SET);
		} else {
			HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, GPIO_PIN_RESET);
		}
		HAL_Delay(150);

	}
	//SIGNAL COMPLETE
	for (int i = 0; i < 15; i++) {
		HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_8);

		HAL_Delay(25);
	}
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, GPIO_PIN_SET);

}

void readIMUAccel(void) {

	uint8_t dataReceived[6];
	// Read 6 BYTES of data starting from ACCEL_XOUT_H register
	uint16_t accelScaleFactor = 16384.0;
	HAL_I2C_Mem_Read(&hi2c2, MPU6050_ADDR, ACCEL_XOUT_H_REG, 1, dataReceived, 6,
			1000);

	Accel_X_RAW = (int16_t) (dataReceived[0] << 8 | dataReceived[1]);
	Accel_Y_RAW = (int16_t) (dataReceived[2] << 8 | dataReceived[3]);
	Accel_Z_RAW = (int16_t) (dataReceived[4] << 8 | dataReceived[5]);

	/*** convert the RAW values into acceleration in 'g'
	 we have to divide according to the Full scale value set in FS_SEL
	 I have configured FS_SEL = 0. So I am dividing by 16384.0
	 for more details check ACCEL_CONFIG Register              ****/

	Ax = Accel_X_RAW / accelScaleFactor;
	Ay = Accel_Y_RAW / accelScaleFactor;
	Az = Accel_Z_RAW / accelScaleFactor;

}

void readIMUGyro(void) {
	uint8_t dataReceived[6];
	uint16_t gryoScaleFactor = 131.0;
	// Read 6 BYTES of data starting from GYRO_XOUT_H register

	HAL_I2C_Mem_Read(&hi2c2, MPU6050_ADDR, GYRO_XOUT_H_REG, 1, dataReceived, 6,
			1000);

	Gyro_X_RAW = (int16_t) (dataReceived[0] << 8 | dataReceived[1]);
	Gyro_Y_RAW = (int16_t) (dataReceived[2] << 8 | dataReceived[3]);
	Gyro_Z_RAW = (int16_t) (dataReceived[4] << 8 | dataReceived[5]);

	/*** convert the RAW values into dps (�/s)
	 we have to divide according to the Full scale value set in FS_SEL
	 I have configured FS_SEL = 0. So I am dividing by 131.0
	 for more details check GYRO_CONFIG Register              ****/

	Gx = Gyro_X_RAW / gryoScaleFactor;
	Gy = Gyro_Y_RAW / gryoScaleFactor;
	Gz = Gyro_Z_RAW / gryoScaleFactor;

}

void HAL_UART_TxCpltCallback(UART_HandleTypeDef *huart) {
	transmissionComplete = 1;
}
/* USER CODE END 4 */

 /**
  * @brief  Period elapsed callback in non blocking mode
  * @note   This function is called  when TIM4 interrupt took place, inside
  * HAL_TIM_IRQHandler(). It makes a direct call to HAL_IncTick() to increment
  * a global variable "uwTick" used as application time base.
  * @param  htim : TIM handle
  * @retval None
  */
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim)
{
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
void Error_Handler(void)
{
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
