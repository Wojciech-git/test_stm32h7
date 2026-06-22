Note: first version of the project based on Makefile.

How to use the new build system                                                                  
                                                                                                      
     Configure the project (one-time or when adding files):                                           
                                                                                                      
     cmake --preset default                                                                           
                                                                                                      
     Build the project:                                                                               
                                                                                                      
     cmake --build --preset default                                                                   
                                                                                                      
     Flash to your board:                                                                             
                                                                                                      
     cmake --build --preset default --target flash                                                    
                                                      

      If you use the command cmake --preset default, it generates Ninja build files inside the build/  
      directory.                                                                                      
                                                                                                      
     I set up the CMakePresets.json with two different profiles:                                      
                                                                                                      
     1. default: This uses "generator": "Ninja". Ninja is highly recommended for CMake C/C++          
     projects because it evaluates dependencies much faster than standard Make, resulting in          
     quicker compile times.                                                                           
     2. make: This uses "generator": "Unix Makefiles". If for some reason you don't have Ninja        
     installed on a different machine, or you strictly prefer Make, you can run cmake --preset make   
     and it will generate a Makefile inside the build/ directory instead.                             
                                                                                                      
     When you run cmake --build --preset default, CMake abstracts this away—it knows it needs to      
     call ninja under the hood.                  


To build the project from scratch, you run two commands sequentially.        
                                                                                  
     1. Configure the project:                                                    
     This step reads the CMakeLists.txt file and generates the build system (     
     Ninja files) in the build/ directory. You only need to run this once, or     
     when you add/remove files to your project:                                   
                                                                                  
     cmake --preset default                                                       
                                                                                  
     2. Build the project:                                                        
     This step actually compiles your .c/.cpp files and links them into the       
     final .elf, .hex, and .bin artifacts:                                        
                                                                                  
     cmake --build --preset default                                               
                                                                                  
     (Note: If you change code inside an existing .c or .cpp file, you only       
     need to run the second command. CMake is smart enough to know what needs     
     to be recompiled!)                    

