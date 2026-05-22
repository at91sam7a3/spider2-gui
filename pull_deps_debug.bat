@echo off
REM Add CMake to PATH
set PATH=C:\Qt\Tools\CMake_64\bin;%PATH%

if not exist build mkdir build
cd build
if not exist debug mkdir debug
cd debug
conan2 install ../.. -s build_type=Debug --output-folder=. --build=missing --update
cd ../..