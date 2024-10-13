@echo off
setlocal enabledelayedexpansion

REM Check for Chrome executable in common locations
set "chrome_path="
for %%D in (
    "C:\Program Files\Google\Chrome\Application\chrome.exe"
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
) do (
    if exist "%%~D" (
        set "chrome_path=%%~D"
        goto chrome_found
    )
)

echo Chrome executable not found. Please install Chrome or set the path manually.
pause
exit /b

:chrome_found
set "user_data_path=%LOCALAPPDATA%\Google\Chrome\User Data"

echo WELCOME TO THE BING SEARCH AUTOMATION SCRIPT!
echo.

REM Detect profiles
set "profile_count=0"
set "temp_file=%TEMP%\profiles.txt"
if exist "%temp_file%" del "%temp_file%"

if exist "%user_data_path%\Default" (
    echo Default >> "%temp_file%"
)

for /D %%F in ("%user_data_path%\Profile*") do (
    echo %%~nxF >> "%temp_file%"
)

for /F "delims=" %%A in (%temp_file%) do (
    set "profile[!profile_count!]=%%A"
    set /A profile_count+=1
)

echo Detected profiles: !profile_count!
set profile_index=0
for /F "delims=" %%A in (%temp_file%) do (
    echo [!profile_index!] %%A
    set "profile[!profile_index!]=%%A"
    set /A profile_index+=1
)

echo.
set /p search_all=Do you want to search all profiles? (Y/N): 
if /I "%search_all%"=="Y" (
    goto perform_all_searches
) else if /I "%search_all%"=="N" (
    goto get_profile
) else (
    echo Invalid input.
    goto search_all_prompt
)

:perform_all_searches
REM First, perform mobile searches for all profiles
echo Performing mobile searches for all profiles...
set /A max_index=!profile_count!-1
for /L %%i in (0,1,!max_index!) do (
    echo Mobile search for profile [%%i] !profile[%%i]!
    taskkill /F /IM chrome.exe >nul 2>&1
    call :mobilesearch %%i
)

REM After completing all mobile searches, perform desktop searches
echo.
echo Performing desktop searches for all profiles...
for /L %%i in (0,1,!max_index!) do (
    echo Desktop search for profile [%%i] !profile[%%i]!
    taskkill /F /IM chrome.exe >nul 2>&1
    call :desktopsearch %%i
)
goto end_script

:get_profile
set /A max_index=!profile_count!-1
echo Enter profile number (0-%max_index%): 
set /p profile_choice=

if !profile_choice! geq 0 if !profile_choice! leq !max_index! (
    goto get_user_agent
) else (
    echo Invalid profile number.
    goto get_profile
)

:get_user_agent
echo.
echo Select user agent:
echo [1] Desktop
echo [2] Mobile
echo [3] Both
set /p user_agent=Enter user agent (1/2/3): 

taskkill /F /IM chrome.exe >nul 2>&1

if /I "%user_agent%"=="1" (
    call :desktopsearch !profile_choice!
) else if /I "%user_agent%"=="2" (
    call :mobilesearch !profile_choice!
) else if /I "%user_agent%"=="3" (
    call :mobilesearch !profile_choice!
    call :desktopsearch !profile_choice!
) else (
    echo Invalid selection.
    goto get_user_agent
)

:end_script
pause
goto :eof

:desktopsearch
set "selected_profile=!profile[%1]!"
if "!selected_profile!"=="" (
    echo Error: No valid profile selected.
    goto :eof
)

REM Close Chrome before running desktop search
taskkill /F /IM chrome.exe >nul 2>&1

echo Running desktop search for profile "!selected_profile!"
bing-rewards --desktop --count=31 --profile "!selected_profile!" --search-delay "10" --exe "%chrome_path%"
if errorlevel 1 (
    echo Error occurred during desktop search.
)
timeout /t 5
goto :eof

:mobilesearch
set "selected_profile=!profile[%1]!"
if "!selected_profile!"=="" (
    echo Error: No valid profile selected.
    goto :eof
)

REM Close Chrome before running mobile search
taskkill /F /IM chrome.exe >nul 2>&1

echo Running mobile search for profile "!selected_profile!"
bing-rewards --mobile --count=22 --profile "!selected_profile!" --search-delay "10" --exe "%chrome_path%"
if errorlevel 1 (
    echo Error occurred during mobile search.
)
timeout /t 5
goto :eof
