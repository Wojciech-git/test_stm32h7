#include "main.h"
#include "FreeRTOS.h"
#include "task.h"

static void led_init(void) {
  RCC->AHB4ENR |= RCC_AHB4ENR_GPIOBEN;

  GPIOB->MODER &= ~(3U << (0U * 2U));
  GPIOB->MODER |= (1U << (0U * 2U));
  GPIOB->OTYPER &= ~(1U << 0U);
  GPIOB->OSPEEDR |= (2U << (0U * 2U));
  GPIOB->PUPDR &= ~(3U << (0U * 2U));
}

#define BLINK_PERIOD 200 // ms

void led_task(void *pvParameters) {
  while (1) {
    GPIOB->BSRR = GPIO_BSRR_BS0;
    vTaskDelay(pdMS_TO_TICKS(BLINK_PERIOD / 2));

    GPIOB->BSRR = GPIO_BSRR_BR0;
    vTaskDelay(pdMS_TO_TICKS(BLINK_PERIOD / 2));
  }
}

int main(void) {
  SystemCoreClockUpdate();
  led_init();

  xTaskCreate(led_task, "LED_Task", configMINIMAL_STACK_SIZE, NULL,
              tskIDLE_PRIORITY + 1, NULL);

  vTaskStartScheduler();

  while (1) {
  }
}
