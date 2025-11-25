@echo off
set bin_path=E:/App/Professional/modelsim/path/modeltech64_10.4/win64
cd E:/User/Files/project_self/OPHW_25H/OPHW_25H_TEST/1_Demo/Basic/04_rom_test/project/sim/behav
call "%bin_path%/modelsim"   -do "do {run_behav_compile.tcl};do {run_behav_simulate.tcl}" -l run_behav_simulate.log
if "%errorlevel%"=="1" goto END
if "%errorlevel%"=="0" goto SUCCESS
:END
exit 1
:SUCCESS
exit 0
