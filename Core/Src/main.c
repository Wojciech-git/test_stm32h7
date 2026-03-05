#include "main.h"

static void delay_cycles(volatile uint32_t cycles)
{
  while (cycles--)
  {
    __NOP();
  }
}

static void led_init(void)
{
  RCC->AHB4ENR |= RCC_AHB4ENR_GPIOBEN;

  GPIOB->MODER &= ~(3U << (0U * 2U));
  GPIOB->MODER |=  (1U << (0U * 2U));
  GPIOB->OTYPER &= ~(1U << 0U);
  GPIOB->OSPEEDR |= (2U << (0U * 2U));
  GPIOB->PUPDR &= ~(3U << (0U * 2U));
}

int main(void)
{
  SystemCoreClockUpdate();
  led_init();

  while (1)
  {
    GPIOB->BSRR = GPIO_BSRR_BS0;
    delay_cycles(SystemCoreClock / 8U);

    GPIOB->BSRR = GPIO_BSRR_BR0;
    delay_cycles(SystemCoreClock / 8U);
  }
}
