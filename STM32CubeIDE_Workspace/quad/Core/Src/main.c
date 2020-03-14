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

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
#define MPU6050_ADDR 0x68
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
I2C_HandleTypeDef hi2c2;

TIM_HandleTypeDef htim2;

UART_HandleTypeDef huart1;
DMA_HandleTypeDef hdma_usart1_tx;

/* Definitions for pidTask */
osThreadId_t pidTaskHandle;
const osThreadAttr_t pidTask_attributes = {
  .name = "pidTask",
  .priority = (osPriority_t) osPriorityNormal,
  .stack_size = 128 * 4
};
/* Definitions for gpsPoll */
osThreadId_t gpsPollHandle;
const osThreadAttr_t gpsPoll_attributes = {
  .name = "gpsPoll",
  .priority = (osPriority_t) osPriorityBelowNormal1,
  .stack_size = 128 * 4
};
/* USER CODE BEGIN PV */
//***********************VARIABLES*********************************
int16_t Accel_X_RAW = 0;
int16_t Accel_Y_RAW = 0;
int16_t Accel_Z_RAW = 0;

int16_t Gyro_X_RAW = 0;
int16_t Gyro_Y_RAW = 0;
int16_t Gyro_Z_RAW = 0;
uint8_t data[] = "HELLO WORLllllllD\n\r";
float Ax, Ay, Az, Gx, Gy, Gz;
int8_t transmissionComplete = 1;
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_DMA_Init(void);
static void MX_I2C2_Init(void);
static void MX_TIM2_Init(void);
static void MX_USART1_UART_Init(void);
void pidStart(void *argument);
void startGps(void *argument);

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
  osKernelInitialize();

  /* USER CODE BEGIN RTOS_MUTEX */
	/* add mutexes, ... */
  /* USER CODE END RTOS_MUTEX */

  /* USER CODE BEGIN RTOS_SEMAPHORES */
	/* add semaphores, ... */
  /* USER CODE END RTOS_SEMAPHORES */

  /* USER CODE BEGIN RTOS_TIMERS */
	/* start timers, add new ones, ... */
  /* USER CODE END RTOS_TIMERS */

  /* USER CODE BEGIN RTOS_QUEUES */
	/* add queues, ... */
  /* USER CODE END RTOS_QUEUES */

  /* Create the thread(s) */
  /* creation of pidTask */
  pidTaskHandle = osThreadNew(pidStart, NULL, &pidTask_attributes);

  /* creation of gpsPoll */
  gpsPollHandle = osThreadNew(startGps, NULL, &gpsPoll_attributes);

  /* USER CODE BEGIN RTOS_THREADS */
	/* add threads, ... */
  /* USER CODE END RTOS_THREADS */

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

/**
  * @brief I2C2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_I2C2_Init(void)
{

  /* USER CODE BEGIN I2C2_Init 0 */

  /* USER CODE END I2C2_Init 0 */

  /* USER CODE BEGIN I2C2_Init 1 */

  /* USER CODE END I2C2_Init 1 */
  hi2c2.Instance = I2C2;
  hi2c2.Init.ClockSpeed = 100000;
  hi2c2.Init.DutyCycle = I2C_DUTYCYCLE_2;
  hi2c2.Init.OwnAddress1 = 0;
  hi2c2.Init.AddressingMode = I2C_ADDRESSINGMODE_7BIT;
  hi2c2.Init.DualAddressMode = I2C_DUALADDRESS_DISABLE;
  hi2c2.Init.OwnAddress2 = 0;
  hi2c2.Init.GeneralCallMode = I2C_GENERALCALL_DISABLE;
  hi2c2.Init.NoStretchMode = I2C_NOSTRETCH_DISABLE;
  if (HAL_I2C_Init(&hi2c2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN I2C2_Init 2 */

  /* USER CODE END I2C2_Init 2 */

}

/**
  * @brief TIM2 Initialization Function
  * @param None
  * @retval None
  */
static void timerPostInit(void)
{
    GPIO_InitTypeDef GPIO_InitStruct;

    /**TIM3 GPIO Configuration
    PB0     ------> TIM3_CH3
    PB1     ------> TIM3_CH4
    PB4     ------> TIM3_CH1
    PB5     ------> TIM3_CH2
    */
    GPIO_InitStruct.Pin = GPIO_PIN_1;
    GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

}
static void MX_TIM2_Init(void)
{

  /* USER CODE BEGIN TIM2_Init 0 */

  /* USER CODE END TIM2_Init 0 */

  TIM_ClockConfigTypeDef sClockSourceConfig = {0};
  TIM_MasterConfigTypeDef sMasterConfig = {0};
  TIM_OC_InitTypeDef sConfigOC = {0};

  /* USER CODE BEGIN TIM2_Init 1 */

  /* USER CODE END TIM2_Init 1 */
  htim2.Instance = TIM2;
  htim2.Init.Prescaler = 72-1;
  htim2.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim2.Init.Period = 100-1;
  htim2.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim2.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_Base_Init(&htim2) != HAL_OK)
  {
    Error_Handler();
  }
  sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
  if (HAL_TIM_ConfigClockSource(&htim2, &sClockSourceConfig) != HAL_OK)
  {
    Error_Handler();
  }
  if (HAL_TIM_PWM_Init(&htim2) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim2, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  sConfigOC.OCMode = TIM_OCMODE_PWM1;
  sConfigOC.Pulse = 0;
  sConfigOC.OCPolarity = TIM_OCPOLARITY_HIGH;
  sConfigOC.OCFastMode = TIM_OCFAST_DISABLE;
  if (HAL_TIM_PWM_ConfigChannel(&htim2, &sConfigOC, TIM_CHANNEL_2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM2_Init 2 */

  /* USER CODE END TIM2_Init 2 */
  timerPostInit();

}

/**
  * @brief USART1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART1_UART_Init(void)
{

  /* USER CODE BEGIN USART1_Init 0 */

  /* USER CODE END USART1_Init 0 */

  /* USER CODE BEGIN USART1_Init 1 */

  /* USER CODE END USART1_Init 1 */
  huart1.Instance = USART1;
  huart1.Init.BaudRate = 115200;
  huart1.Init.WordLength = UART_WORDLENGTH_8B;
  huart1.Init.StopBits = UART_STOPBITS_1;
  huart1.Init.Parity = UART_PARITY_NONE;
  huart1.Init.Mode = UART_MODE_TX_RX;
  huart1.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart1.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart1) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART1_Init 2 */

  /* USER CODE END USART1_Init 2 */

}

/** 
  * Enable DMA controller clock
  */
static void MX_DMA_Init(void) 
{

  /* DMA controller clock enable */
  __HAL_RCC_DMA1_CLK_ENABLE();

  /* DMA interrupt init */
  /* DMA1_Channel4_IRQn interrupt configuration */
  HAL_NVIC_SetPriority(DMA1_Channel4_IRQn, 5, 0);
  HAL_NVIC_EnableIRQ(DMA1_Channel4_IRQn);

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOD_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8|GPIO_PIN_9, GPIO_PIN_RESET);

  /*Configure GPIO pins : PB8 PB9 */
  GPIO_InitStruct.Pin = GPIO_PIN_8|GPIO_PIN_9;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

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

/* USER CODE BEGIN Header_pidStart */
/**
 * @brief  Function implementing the pidTask thread.
 * @param  argument: Not used
 * @retval None
 */
/* USER CODE END Header_pidStart */
void pidStart(void *argument)
{
  /* USER CODE BEGIN 5 */
	/* Infinite loop */
//	HAL_UART_Transmit_IT(&huart1, data, sizeof (data));
	int counter = 0;
	for (;;) {

//		if(transmissionComplete == 1){
//			transmissionComplete = 0;

//			HAL_UART_Transmit_IT(&huart1, data, sizeof (data));
//
//		}
//		readIMUGyro();
//		readIMUAccel();
		if (counter <= 100) {
			htim2.Instance->CCR1 = counter;
			counter = counter + 10;
			HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_8);
			osDelay(100);
		} else {
			counter = 0;
			HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_9);
		}

	}
	osThreadTerminate(NULL);
  /* USER CODE END 5 */ 
}

/* USER CODE BEGIN Header_startGps */
/**
 * @brief Function implementing the gpsPoll thread.
 * @param argument: Not used
 * @retval None
 */
/* USER CODE END Header_startGps */
void startGps(void *argument)
{
  /* USER CODE BEGIN startGps */
	/* Infinite loop */
	for (;;) {

//		HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_8);
//		osDelay(500);

	}
	osThreadTerminate(NULL);
  /* USER CODE END startGps */
}

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
