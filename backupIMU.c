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
float rollGyroSpeed, pitchGyroSpeed, yawGyroSpeed;
float pitchAngle, yawAngle, rollAngle; //true pitch roll yaw
float pitchAccel, yawAccel, rollAccel; //pitch roll yaw from accel;
float pitchGyro, yawGyro, rollGyro;
float pitchGyroCal, yawGyroCal, rollGyroCal;
int16_t accelXRaw = 0;
int16_t accelYRaw = 0;
int16_t accelZRaw = 0;
int16_t gyroRollSpeedRaw = 0;
int16_t gyroPitchSpeedRaw = 0;
int16_t gyroYawSpeedRaw = 0;
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