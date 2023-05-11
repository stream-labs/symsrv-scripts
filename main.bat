@echo on
cd %1
powershell.exe -ExecutionPolicy Bypass -Command %2

:: Exit with non-zero so GitHub action knows there was an issue
if %errorlevel% neq 0 exit /b %errorlevel%