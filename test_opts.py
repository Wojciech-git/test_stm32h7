import os
import subprocess

def run_tests(branch_name):
    print(f"\n--- Tests for {branch_name} ---")
    print(f"{'Opt':<5} | {'Text (ROM)':<10} | {'Data':<6} | {'BSS (RAM)':<10} | {'Total (Dec)':<10}")
    print("-" * 55)
    
    for opt in ['-O0', '-Os', '-O2', '-O3']:
        
        # Clean build directory completely to ensure fresh configure
        subprocess.run(['rm', '-rf', 'build'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        # Configure with specific optimization level
        configure_cmd = ['cmake', '--preset', 'default', f'-DOPT_LEVEL={opt}']
        subprocess.run(configure_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            
        # Build
        build_cmd = ['cmake', '--build', '--preset', 'default']
        build_result = subprocess.run(build_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        if build_result.returncode != 0:
            print(f"{opt:<5} | Build failed")
            continue
        
        # Get memory footprint using size utility
        result = subprocess.run(
            ['/opt/st/stm32cubeclt_1.20.0/GNU-tools-for-STM32/bin/arm-none-eabi-size', 'build/stm32h7.elf'], 
            capture_output=True, text=True
        )
        
        # Parse and print result
        lines = result.stdout.strip().split('\n')
        if len(lines) >= 2:
            parts = lines[1].split()
            if len(parts) >= 4:
                print(f"{opt:<5} | {parts[0]:<10} | {parts[1]:<6} | {parts[2]:<10} | {parts[3]:<10}")
            else:
                print(f"{opt:<5} | Size output format unexpected")
        else:
            print(f"{opt:<5} | Build failed or no size output")

# Ensure clean state before starting
subprocess.run(['rm', '-rf', 'build'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# FreeRTOS tests (master)
subprocess.run(['git', 'checkout', 'master'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
run_tests("FreeRTOS Version (Current Commit)")

# Bare-Metal C++ tests (HEAD~1)
subprocess.run(['git', 'checkout', 'HEAD~1'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
run_tests("Bare-Metal C++ Version (Previous Commit)")

# Restore original state
subprocess.run(['git', 'checkout', 'master'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
