//#include "controlInput.h"
//#include "tim.h"
//
//uint32_t startTim[4] = { 0, 0, 0, 0 };
//uint32_t endTim[4] = { 0, 0, 0, 0 };
//uint32_t inputs[4] = { 0, 0, 0, 0 };
//
//void HAL_TIM_IC_CaptureCallback(TIM_HandleTypeDef *htim) {
//	uint32_t value = 0;
//	if (htim == &htim2) {
//		if (htim->Channel == HAL_TIM_ACTIVE_CHANNEL_1) {
//			value = HAL_TIM_ReadCapturedValue(htim, TIM_CHANNEL_1); //rising edge
//
//			if (value != 0) {
//				IC_Val2 = HAL_TIM_ReadCapturedValue(htim, TIM_CHANNEL_1); // falling edge value
//				Duty_Cycle = (IC_Val2 * 100 / IC_Val1);
//				Frequency = (2 * HAL_RCC_GetPCLK1Freq() / IC_Val1);
//			}
//			else{
//				__HAL_TIM_SET_CAPTUREPOLARITY(htim, TIM_CHANNEL_1, TIM_INPUTCHANNELPOLARITY_FALLING);
//			}
//		}
//
//	}
//
//}
