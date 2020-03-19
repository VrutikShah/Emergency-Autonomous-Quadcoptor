/* USER CODE BEGIN Header */
/**
 ******************************************************************************
 * @file           : main.c for quadcopterproject
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
#include "i2c.h"
#include "tim.h"
#include "gpio.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include "stdio.h"
#include "math.h"
#include "stdlib.h"
#include "IMU/imu.h"
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
#define MPU6500_ADDR 0xD0
#define MPU6050_ADDR 0xD0
#define SMPLRT_DIV_REG 0x19
#define GYRO_CONFIG_REG 0x1B
#define ACCEL_CONFIG_REG 0x1C
#define ACCEL_XOUT_H_REG 0x3B
#define TEMP_OUT_H_REG 0x41
#define GYRO_XOUT_H_REG 0x43
#define PWR_MGMT_1_REG 0x6B
#define WHO_AM_I_REG 0x75
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */
uint8_t receivedData[20] = "12345678901234567890";
int16_t accelXRaw = 0;
int16_t accelYRaw = 0;
int16_t accelZRaw = 0;
int16_t gyroRollSpeedRaw = 0;
int16_t gyroPitchSpeedRaw = 0;
int16_t gyroYawSpeedRaw = 0;
uint16_t pidLoopDelay = 50;
float rollGyroSpeed, pitchGyroSpeed, yawGyroSpeed;
float pitchAngle, yawAngle, rollAngle; //true pitch roll yaw
float pitchAccel, yawAccel, rollAccel; //pitch roll yaw from accel;
float pitchGyro, yawGyro, rollGyro;
float pitchGyroCal, yawGyroCal, rollGyroCal;
//float Ax, Ay, Az, Gx, Gy, Gz;
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
void MX_FREERTOS_Init(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
//void _write(int file, char *ptr, int len) {
//	int i = 0;
//	for (i = 0; i < len; i++) {
//		ITM_SendChar((*ptr++));
//
//	}
//	return len;
//}
void blinkLED(int numberOn, int duration) {
	if (numberOn == 0) {
		return;
	}
	HAL_GPIO_WritePin(GPIOC, GPIO_PIN_13, GPIO_PIN_SET);
	int delay = (int) duration / numberOn;
	for (int i = 0; i < numberOn; i++) {
		HAL_GPIO_TogglePin(GPIOC, GPIO_PIN_13);
		HAL_Delay((int) delay / 2);
		HAL_GPIO_TogglePin(GPIOC, GPIO_PIN_13);
		HAL_Delay((int) delay / 2);
	}
	HAL_GPIO_WritePin(GPIOC, GPIO_PIN_13, GPIO_PIN_SET);

}
void initUART(void) {
//	while (HAL_UART_Receive_DMA(&huart3, receivedData, 20) != HAL_OK) {
//		blinkLED(2, 25);
//	}
	blinkLED(0, 0);

}
void escSet(uint32_t channel, uint16_t value) {
	__HAL_TIM_SET_COMPARE(&htim1, channel, value);
}

void initIMU(void) {

	uint8_t Data;

	blinkLED(5, 1000);
	HAL_Delay(1000);
	uint8_t check1 = 9;

	// next two lines are to force reset the HAL STATE coz of some software glitch.
	__HAL_RCC_I2C1_FORCE_RESET();
	HAL_Delay(2);
	__HAL_RCC_I2C1_RELEASE_RESET();

	//	prints("initializing4567890");
	while (check1 != 104) {
		if (HAL_I2C_Mem_Read(&hi2c1, MPU6500_ADDR, WHO_AM_I_REG, 1, &check1, 1,
				1000) == HAL_BUSY) {
			blinkLED(10, 500);
		}

	}

	if (check1 == 104) // 0x73 will be returned by the sensor if everything goes well
			{
		// power management register 0X6B we should write all 0's to wake the sensor up
		// power management register 0X6B we should write all 0's to wake the sensor up
		Data = 0;
		HAL_I2C_Mem_Write(&hi2c1, MPU6050_ADDR, PWR_MGMT_1_REG, 1, &Data, 1,
				1000);

		// Set DATA RATE of 1KHz by writing SMPLRT_DIV register
		Data = 0x07;
		HAL_I2C_Mem_Write(&hi2c1, MPU6050_ADDR, SMPLRT_DIV_REG, 1, &Data, 1,
				1000);

		// Set accelerometer configuration in ACCEL_CONFIG Register
		// 8g scale. 0x10
		Data = 0x10;
		HAL_I2C_Mem_Write(&hi2c1, MPU6050_ADDR, ACCEL_CONFIG_REG, 1, &Data, 1,
				1000);

		// Set Gyroscopic configuration in GYRO_CONFIG Register
		// XG_ST=0,YG_ST=0,ZG_ST=0, FS_SEL=0 -> � 250 �/s
		Data = 0x01;
		HAL_I2C_Mem_Write(&hi2c1, MPU6050_ADDR, GYRO_CONFIG_REG, 1, &Data, 1,
				1000);
		//MAGNETOMETER STUFF
//		Data = 0x02;
//		HAL_I2C_Mem_Write(&hi2c1, MPU6500_ADDR, INT_BYPASS_CONFIG_AD, 1, &Data,
//				1, 1000);
//
//		Data = 0x00;
//		HAL_I2C_Mem_Write(&hi2c1, MPU6500_ADDR, INT_BYPASS_CONFIG_AD, 1, &Data,
//				1, 1000);
//
//		Data = 0x1F;
//				HAL_I2C_Mem_Write(&hi2c1, MPU6500_ADDR, CNTL1_AD, 1, &Data,
//						1, 1000);
		//		prints("Successful Init67890");

	} else {
		blinkLED(2, 2000);
	}

}
void calibrateGyro(void) {
	uint8_t Rec_Data_gyro[6];
	int iterations = 500;
	for (int i = 0; i < iterations; i++) {
		while (HAL_I2C_Mem_Read(&hi2c1, MPU6500_ADDR, GYRO_XOUT_H_REG, 1,
				Rec_Data_gyro, 6, 1000) != HAL_OK)
			;

		rollGyroCal += ((int16_t) (Rec_Data_gyro[0] << 8 | Rec_Data_gyro[1]))
				/ 65.5;
		pitchGyroCal += ((int16_t) (Rec_Data_gyro[2] << 8 | Rec_Data_gyro[3]))
				/ 65.5;
		yawGyroCal += ((int16_t) (Rec_Data_gyro[4] << 8 | Rec_Data_gyro[5]))
				/ 65.5;
	}
	rollGyroCal /= iterations;
	pitchGyroCal /= iterations;
	yawGyroCal /= iterations;

}
void readIMUAccel(void) {
	uint8_t Rec_Data_accel[6];
	// Read 6 BYTES of receivedData starting from ACCEL_XOUT_H register
	while (HAL_I2C_Mem_Read(&hi2c1, MPU6500_ADDR, ACCEL_XOUT_H_REG, 1,
			Rec_Data_accel, 6, 1000) != HAL_OK)
		;

	accelXRaw = (int16_t) (Rec_Data_accel[0] << 8 | Rec_Data_accel[1]);
	accelYRaw = (int16_t) (Rec_Data_accel[2] << 8 | Rec_Data_accel[3]);
	accelZRaw = (int16_t) (Rec_Data_accel[4] << 8 | Rec_Data_accel[5]);

	int16_t netAccel = sqrt(
			pow(accelXRaw, 2) + pow(accelYRaw, 2) + pow(accelZRaw, 2));

	if (abs(accelYRaw) < netAccel) {
		pitchAccel = asin((float) accelYRaw / netAccel) * 57.296;
	}
	if (abs(accelXRaw) < netAccel) {
		rollAccel = asin((float) accelXRaw / netAccel) * 57.296;
	}

}
void readIMUGyro(void) {
	uint8_t Rec_Data_gyro[6];

	// Read 6 BYTES of receivedData starting from GYRO_XOUT_H register

	while (HAL_I2C_Mem_Read(&hi2c1, MPU6500_ADDR, GYRO_XOUT_H_REG, 1,
			Rec_Data_gyro, 6, 1000) != HAL_OK)
		;

	gyroRollSpeedRaw = (int16_t) (Rec_Data_gyro[0] << 8 | Rec_Data_gyro[1]);
	gyroPitchSpeedRaw = (int16_t) (Rec_Data_gyro[2] << 8 | Rec_Data_gyro[3]);
	gyroYawSpeedRaw = (int16_t) (Rec_Data_gyro[4] << 8 | Rec_Data_gyro[5]);

	//from docs - since choosing 1deg = 65.5 units, dividing by 65.5
	//gives speed in  degrees per second.
	pitchGyroSpeed = (gyroPitchSpeedRaw / 65.5) - pitchGyroCal;
	rollGyroSpeed = (gyroRollSpeedRaw / 65.5) - rollGyroCal;
	yawGyroSpeed = (gyroYawSpeedRaw / 65.5) - yawGyroCal;

	//integrate to find angles

	pitchGyro += pitchGyroSpeed * pidLoopDelay / 1000.0;
	yawGyro += yawGyroSpeed * pidLoopDelay / 1000.0;
	rollGyro += rollGyroSpeed * pidLoopDelay / 1000.0;

	rollGyro += pitchGyro * sin((float) yawGyro * 0.000001066);
	pitchGyro -= rollGyro * sin((float) yawGyro * 0.000001066);

}
void complementaryFilter(void) {
	pitchAngle = pitchGyro * 0.9996 + pitchAccel * 0.0004;
	rollAngle = rollGyro * 0.9996 + rollAccel * 0.0004;
	yawAngle = yawGyro * 0.9996 + yawAccel * 0.0004;
}

void initMotors(void) {
//	HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_1);
//	HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_2);
//	HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_3);
//	HAL_TIM_PWM_Start(&htim1, TIM_CHANNEL_4);
//	escSet(TIM_CHANNEL_1, 500);
//	escSet(TIM_CHANNEL_2, 500);
//	escSet(TIM_CHANNEL_3, 500);
//	escSet(TIM_CHANNEL_4, 500);
	blinkLED(0, 25);
}
void droneInit(void) {
	//initialize pwm signals.
	initMotors();
	initUART();
//	initIMU();
//	calibrateGyro();


	MPU6050_initialize();
	DMP_Init();

//	blinkLED(50,5000);

}

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
  MX_I2C1_Init();
  MX_TIM1_Init();
  /* USER CODE BEGIN 2 */
	droneInit();
  /* USER CODE END 2 */

  /* Init scheduler */
  osKernelInitialize();  /* Call init function for freertos objects (in freertos.c) */
  MX_FREERTOS_Init(); 
  /* Start scheduler */
  osKernelStart();
 
  /* We should never get here as control is now taken by the scheduler */
  /* Infinite loop */
  /* USER CODE BEGIN WHILE */

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
