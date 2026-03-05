# Makefile for STM32H753ZI (minimal CMSIS project)

TARGET = stm32h7
DEVICE = STM32H753xx

PREFIX = /opt/st/stm32cubeclt_1.20.0/GNU-tools-for-STM32/bin/arm-none-eabi-
CC = $(PREFIX)gcc
AS = $(PREFIX)gcc
CP = $(PREFIX)objcopy
SZ = $(PREFIX)size
GDB = $(PREFIX)gdb

OPENOCD ?= openocd
OPENOCD_INTERFACE ?= interface/stlink.cfg
OPENOCD_TARGET ?= target/stm32h7x.cfg
OPENOCD_SPEED ?= 1000
OPENOCD_TRANSPORT ?= hla_swd

SRC_DIR = Core/Src
INC_DIR = Core/Inc

SOURCES = $(SRC_DIR)/main.c \
          $(SRC_DIR)/system_stm32h7xx.c

ASM_SOURCES = Core/Startup/startup_stm32h753xx.s

CUBE_H7 = /home/wb/STM32Cube/Repository/STM32Cube_FW_H7_V1.12.1

INCLUDES = -I$(INC_DIR)
INCLUDES += -I$(CUBE_H7)/Drivers/CMSIS/Include
INCLUDES += -I$(CUBE_H7)/Drivers/CMSIS/Device/ST/STM32H7xx/Include

CPU = -mcpu=cortex-m7 -mthumb -mfpu=fpv5-d16 -mfloat-abi=hard

CFLAGS = $(CPU) -O0 -ggdb -Wall -fdata-sections -ffunction-sections
CFLAGS += $(INCLUDES) -std=gnu99 -fno-common -DSTM32H753xx
ASFLAGS = $(CPU) -x assembler-with-cpp

LDSCRIPT = STM32H753ZITx_FLASH.ld
LDFLAGS = $(CPU) -T $(LDSCRIPT) -specs=nosys.specs -lc -lm
LDFLAGS += -Wl,--gc-sections -Wl,-Map=$(TARGET).map,--cref -Wl,--print-memory-usage

BUILD_DIR = build
OBJ = $(SOURCES:%.c=$(BUILD_DIR)/%.o)
OBJ += $(ASM_SOURCES:%.s=$(BUILD_DIR)/%.o)

all: $(BUILD_DIR)/$(TARGET).elf $(TARGET).bin $(TARGET).hex

$(BUILD_DIR)/$(TARGET).elf: $(OBJ)
	$(CC) $(OBJ) $(LDFLAGS) -o $@
	$(SZ) $@

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -c $< -o $@

$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf
	$(CP) -O binary $< $@

$(TARGET).hex: $(BUILD_DIR)/$(TARGET).elf
	$(CP) -O ihex $< $@

clean:
	rm -rf $(BUILD_DIR) $(TARGET).bin $(TARGET).hex $(TARGET).map

flash: $(BUILD_DIR)/$(TARGET).elf
	$(OPENOCD) -f $(OPENOCD_INTERFACE) \
		$(if $(OPENOCD_TRANSPORT),-c "transport select $(OPENOCD_TRANSPORT)") \
		-f $(OPENOCD_TARGET) \
		-c "adapter speed $(OPENOCD_SPEED)" \
		-c "program $(BUILD_DIR)/$(TARGET).elf verify reset exit"

openocd:
	$(OPENOCD) -f $(OPENOCD_INTERFACE) \
		$(if $(OPENOCD_TRANSPORT),-c "transport select $(OPENOCD_TRANSPORT)") \
		-f $(OPENOCD_TARGET) \
		-c "adapter speed $(OPENOCD_SPEED)"

gdb: $(BUILD_DIR)/$(TARGET).elf
	$(GDB) $(BUILD_DIR)/$(TARGET).elf \
		-ex "target extended-remote :3333" \
		-ex "monitor reset halt"

.PHONY: all clean flash openocd gdb
