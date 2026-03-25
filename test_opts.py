import os
import subprocess
import re

def run_tests(branch_name):
    print(f"\n--- Tests for {branch_name} ---")
    print(f"{'Opt':<5} | {'Text (ROM)':<10} | {'Data':<6} | {'BSS (RAM)':<10} | {'Total (Dec)':<10}")
    print("-" * 55)
    
    for opt in ['-O0', '-Os', '-O2', '-O3']:
        with open('Makefile', 'r') as f:
            content = f.read()
            
        # Replace existing -O flag with the current target optimization flag
        content = re.sub(r'-O[0s23]', opt, content)
        
        with open('Makefile', 'w') as f:
            f.write(content)
            
        # Clean and Build
        subprocess.run(['make', 'clean', 'all'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
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

# Ensure clean state for Makefile before starting
subprocess.run(['git', 'checkout', 'Makefile'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# C++ tests (master)
subprocess.run(['git', 'checkout', 'master'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
run_tests("C++ Version (Current Commit)")

# C tests (HEAD~1)
subprocess.run(['git', 'checkout', 'HEAD~1'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
run_tests("C Version (Previous Commit)")

# Restore original state
subprocess.run(['git', 'checkout', 'master'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
subprocess.run(['git', 'checkout', 'Makefile'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
