cmake_minimum_required(VERSION 3.20)

# Allow setting CUBE_H7 from command line or environment, default to Makefile value
if(NOT DEFINED CUBE_H7)
    if(DEFINED ENV{CUBE_H7})
        set(CUBE_H7 $ENV{CUBE_H7})
    else()
        set(CUBE_H7 "/home/wb/STM32Cube/Repository/STM32Cube_FW_H7_V1.12.1")
    endif()
endif()

project(stm32h7 C CXX ASM)

# Add the executable
add_executable(${PROJECT_NAME})
set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".elf")

# Device and CPU flags
set(CPU_FLAGS 
    -mcpu=cortex-m7 
    -mthumb 
    -mfpu=fpv5-d16 
    -mfloat-abi=hard
)

# Allow optimization level to be configured
set(OPT_LEVEL "-O0" CACHE STRING "Optimization level (e.g. -O0, -Os, -O2, -O3)")

# Compile Options
# Use target_compile_options and target_link_options to apply flags
target_compile_options(${PROJECT_NAME} PRIVATE
    $<$<COMPILE_LANGUAGE:C>:${CPU_FLAGS} ${OPT_LEVEL} -ggdb -Wall -fdata-sections -ffunction-sections -std=gnu99 -fno-common>
    $<$<COMPILE_LANGUAGE:CXX>:${CPU_FLAGS} ${OPT_LEVEL} -ggdb -Wall -fdata-sections -ffunction-sections -std=gnu++14 -fno-exceptions -fno-rtti -fno-threadsafe-statics -fno-common>
    $<$<COMPILE_LANGUAGE:ASM>:${CPU_FLAGS} -x assembler-with-cpp>
)

# Compile Definitions
target_compile_definitions(${PROJECT_NAME} PRIVATE
    STM32H753xx
)

# Include Directories
set(FREERTOS_DIR "${CUBE_H7}/Middlewares/Third_Party/FreeRTOS/Source")

target_include_directories(${PROJECT_NAME} PRIVATE
    Core/Inc
    ${CUBE_H7}/Drivers/CMSIS/Include
    ${CUBE_H7}/Drivers/CMSIS/Device/ST/STM32H7xx/Include
    ${FREERTOS_DIR}/include
    ${FREERTOS_DIR}/portable/GCC/ARM_CM7/r0p1
)

# Source Files
target_sources(${PROJECT_NAME} PRIVATE
    Core/Src/system_stm32h7xx.c
    Core/Src/main.cpp
    Core/Startup/startup_stm32h753xx.s
    ${FREERTOS_DIR}/tasks.c
    ${FREERTOS_DIR}/queue.c
    ${FREERTOS_DIR}/list.c
    ${FREERTOS_DIR}/timers.c
    ${FREERTOS_DIR}/event_groups.c
    ${FREERTOS_DIR}/stream_buffer.c
    ${FREERTOS_DIR}/portable/MemMang/heap_4.c
    ${FREERTOS_DIR}/portable/GCC/ARM_CM7/r0p1/port.c
)

# Linker script
set(LDSCRIPT "${CMAKE_CURRENT_SOURCE_DIR}/STM32H753ZITx_FLASH.ld")

# Link Options
# Using list for CMake options
target_link_options(${PROJECT_NAME} PRIVATE
    -mcpu=cortex-m7 
    -mthumb 
    -mfpu=fpv5-d16 
    -mfloat-abi=hard
    -T${LDSCRIPT}
    -specs=nosys.specs
    -lc
    -lm
    -Wl,--gc-sections
    -Wl,-Map=${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.map,--cref
    -Wl,--print-memory-usage
)

# Generate bin and hex files
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${PROJECT_NAME}> ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.bin
    COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${PROJECT_NAME}> ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.hex
    COMMAND ${CMAKE_SIZE} $<TARGET_FILE:${PROJECT_NAME}>
    BYPRODUCTS 
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.bin
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.hex
)

# OpenOCD target for flashing
set(OPENOCD_INTERFACE "interface/stlink.cfg")
set(OPENOCD_TARGET "target/stm32h7x.cfg")
set(OPENOCD_SPEED 4000)
set(OPENOCD_TRANSPORT "hla_swd")
find_program(OPENOCD_PROGRAM openocd)

if(OPENOCD_PROGRAM)
    add_custom_target(flash
        COMMAND ${OPENOCD_PROGRAM} 
            -f ${OPENOCD_INTERFACE}
            -c "transport select ${OPENOCD_TRANSPORT}"
            -f ${OPENOCD_TARGET}
            -c "adapter speed ${OPENOCD_SPEED}"
            -c "program $<TARGET_FILE:${PROJECT_NAME}> verify reset exit"
        DEPENDS ${PROJECT_NAME}
        COMMENT "Flashing ${PROJECT_NAME} using OpenOCD"
        USES_TERMINAL
    )

    add_custom_target(openocd
        COMMAND ${OPENOCD_PROGRAM} 
            -f ${OPENOCD_INTERFACE}
            -c "transport select ${OPENOCD_TRANSPORT}"
            -f ${OPENOCD_TARGET}
            -c "adapter speed ${OPENOCD_SPEED}"
        COMMENT "Starting OpenOCD server"
        USES_TERMINAL
    )
endif()

# GDB target
set(GDB_PROGRAM "/home/wb/bin/xpack-arm-none-eabi-gcc-15.2.1-1.1/bin/arm-none-eabi-gdb")
if(EXISTS ${GDB_PROGRAM})
    add_custom_target(gdb
        COMMAND ${GDB_PROGRAM} $<TARGET_FILE:${PROJECT_NAME}>
            -ex "target extended-remote :3333"
            -ex "monitor reset halt"
        DEPENDS ${PROJECT_NAME}
        COMMENT "Starting GDB"
        USES_TERMINAL
    )
endif()

# Export compile commands for language servers
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Add custom clean target to remove map, bin, and hex files alongside standard clean
set_property(DIRECTORY PROPERTY ADDITIONAL_CLEAN_FILES
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.bin"
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.hex"
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.map"
)
