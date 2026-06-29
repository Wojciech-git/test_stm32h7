# test_stm32h7

STM32H753ZI (NUCLEO-H743ZI) minimal CMSIS project with FreeRTOS.

## Prerequisites

- `arm-none-eabi-gcc` (GNU Tools for STM32)
- `openocd` (xPack OpenOCD 0.12.0+)

## Build & Flash

```sh
make          # build elf, bin, hex
make flash    # program target via ST-Link
make openocd  # start GDB server on :3333
make gdb      # connect GDB to running OpenOCD
```

## Notes

- The target requires `connect_assert_srst` — the board's application
  disables the debug interface, so OpenOCD must hold the target in reset
  during initial connection.
- `examine-end` event errors during connect are harmless (memory
  inaccessible while SRST is asserted, the chip resets properly after).
