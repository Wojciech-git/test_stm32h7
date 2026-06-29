# Makefile for STM32H753ZI (minimal CMSIS project)

TARGET = stm32h7
DEVICE = STM32H753xx

PREFIX = /opt/st/stm32cubeclt_1.20.0/GNU-tools-for-STM32/bin/arm-none-eabi-
CC = $(PREFIX)gcc
CXX = $(PREFIX)g++
AS = $(PREFIX)gcc
CP = $(PREFIX)objcopy
SZ = $(PREFIX)size
GDB = /home/wb/bin/xpack-arm-none-eabi-gcc-15.2.1-1.1/bin/arm-none-eabi-gdb

OPENOCD ?= /home/wb/bin/xpack-openocd-0.12.0-2/bin/openocd
OPENOCD_INTERFACE ?= interface/stlink.cfg
OPENOCD_TARGET ?= $(CURDIR)/openocd.cfg
OPENOCD_SPEED ?= 4000
OPENOCD_TRANSPORT ?= hla_swd

SRC_DIR = Core/Src
INC_DIR = Core/Inc

FREERTOS_DIR = $(CUBE_H7)/Middlewares/Third_Party/FreeRTOS/Source

C_SOURCES = $(SRC_DIR)/system_stm32h7xx.c \
$(FREERTOS_DIR)/tasks.c \
$(FREERTOS_DIR)/queue.c \
$(FREERTOS_DIR)/list.c \
$(FREERTOS_DIR)/timers.c \
$(FREERTOS_DIR)/event_groups.c \
$(FREERTOS_DIR)/stream_buffer.c \
$(FREERTOS_DIR)/portable/MemMang/heap_4.c \
$(FREERTOS_DIR)/portable/GCC/ARM_CM7/r0p1/port.c

CXX_SOURCES = $(SRC_DIR)/main.cpp

ASM_SOURCES = Core/Startup/startup_stm32h753xx.s

CUBE_H7 = /home/wb/STM32Cube/Repository/STM32Cube_FW_H7_V1.12.1

INCLUDES = -I$(INC_DIR)
INCLUDES += -I$(CUBE_H7)/Drivers/CMSIS/Include
INCLUDES += -I$(CUBE_H7)/Drivers/CMSIS/Device/ST/STM32H7xx/Include
INCLUDES += -I$(FREERTOS_DIR)/include
INCLUDES += -I$(FREERTOS_DIR)/portable/GCC/ARM_CM7/r0p1

CPU = -mcpu=cortex-m7 -mthumb -mfpu=fpv5-d16 -mfloat-abi=hard

DEBUG=1

ifneq ($(DEBUG),)
OPT   = -O0
DBG   = -ggdb
LTO   =
else
OPT   = -Os
DBG   =
LTO   = -flto
endif

CFLAGS = $(CPU) $(OPT) $(DBG) -Wall -fdata-sections -ffunction-sections
CFLAGS += $(INCLUDES) -std=gnu99 -fno-common -DSTM32H753xx

CXXFLAGS = $(CPU) $(OPT) $(DBG) -Wall -fdata-sections -ffunction-sections
CXXFLAGS += $(INCLUDES) -std=gnu++14 -fno-exceptions -fno-rtti -fno-threadsafe-statics -fno-common -DSTM32H753xx

ASFLAGS = $(CPU) -x assembler-with-cpp

LDSCRIPT = STM32H753ZITx_FLASH.ld
LDFLAGS = $(CPU) -T $(LDSCRIPT) -specs=nosys.specs -lc -lm
LDFLAGS += -Wl,--gc-sections -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref -Wl,--print-memory-usage $(LTO)

BUILD_DIR = build
OBJ = $(C_SOURCES:%.c=$(BUILD_DIR)/%.o)
OBJ += $(CXX_SOURCES:%.cpp=$(BUILD_DIR)/%.o)
OBJ += $(ASM_SOURCES:%.s=$(BUILD_DIR)/%.o)

all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).bin $(BUILD_DIR)/$(TARGET).hex

$(BUILD_DIR)/$(TARGET).elf: $(OBJ)
	$(CXX) $(OBJ) $(LDFLAGS) -o $@
	$(SZ) $@

$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.s
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) -c $< -o $@

$(BUILD_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf
	$(CP) -O binary $< $@

$(BUILD_DIR)/$(TARGET).hex: $(BUILD_DIR)/$(TARGET).elf
	$(CP) -O ihex $< $@

clean:
	rm -rf $(BUILD_DIR)

flash: $(BUILD_DIR)/$(TARGET).elf
	$(OPENOCD) -f $(OPENOCD_INTERFACE) \
		-f $(OPENOCD_TARGET) \
		-c "adapter speed $(OPENOCD_SPEED)" \
		-c "program $(BUILD_DIR)/$(TARGET).elf verify reset exit"

openocd:
	$(OPENOCD) -f $(OPENOCD_INTERFACE) \
		-f $(OPENOCD_TARGET) \
		-c "adapter speed $(OPENOCD_SPEED)"

gdb: $(BUILD_DIR)/$(TARGET).elf
	$(GDB) $(BUILD_DIR)/$(TARGET).elf \
		-ex "target extended-remote :3333" \
		-ex "monitor reset halt"

compile_commands.json:
	bear --output $@ -- $(MAKE) --no-print-directory clean all

update: compile_commands.json

.PHONY: all clean flash openocd gdb update
