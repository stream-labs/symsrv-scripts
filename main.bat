@echo on
echo Running symbol script test
dir
cd %1

if "%~9"=="" goto blank
powershell.exe -ExecutionPolicy Bypass -Command ".\main.ps1 -localSourceDir %2 -outputFolder %3 -repo_userId %4 -repo_name %5 -repo_branch %6 -AWS_ACCESS_KEY_ID %7 -AWS_SECRET_ACCESS_KEY %8 -ignoreArray %9"
GOTO done

:blank
powershell.exe -ExecutionPolicy Bypass -Command ".\main.ps1 -localSourceDir %2 -outputFolder %3 -repo_userId %4 -repo_name %5 -repo_branch %6 -AWS_ACCESS_KEY_ID %7 -AWS_SECRET_ACCESS_KEY %8"

:done