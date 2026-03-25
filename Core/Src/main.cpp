#include "main.h"

static void delay_ms(uint32_t ms)
{
  SysTick->LOAD = (SystemCoreClock / 1000U) - 1U;
  SysTick->VAL = 0U;
  SysTick->CTRL = SysTick_CTRL_CLKSOURCE_Msk | SysTick_CTRL_ENABLE_Msk;

  while (ms--)
  {
    while ((SysTick->CTRL & SysTick_CTRL_COUNTFLAG_Msk) == 0U)
    {
    }
  }

  SysTick->CTRL = 0U;
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

#define BLINK_PERIOD 100  //ms

int main(void)
{
  SystemCoreClockUpdate();
  led_init();

  while (1)
  {
    GPIOB->BSRR = GPIO_BSRR_BS0;
    delay_ms(BLINK_PERIOD/2);

    GPIOB->BSRR = GPIO_BSRR_BR0;
    delay_ms(BLINK_PERIOD/2);
  }
}
