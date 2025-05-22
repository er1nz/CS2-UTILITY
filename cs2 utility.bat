@echo off
setlocal EnableDelayedExpansion

:mainMenu
cls
echo.
echo               CS2 UTILITY by @er1nz
echo           https://www.github.com/er1nz           
echo  Do the first 3 options after every game update
echo.
echo        1. Clear DirectX Shader Cache 
echo        2. Clear NVIDIA DXCache Files
echo        3. Launch Steam Console and Send Command (shader_build 730)
echo        4. Add autoexec.cfg file
echo        5. Configure launch parameters
echo        6. Add cs2.ini file
echo        7. Exit
echo.
set /p choice="Select an option (1-7): "

if "%choice%"=="1" goto :clearShaderCache
if "%choice%"=="2" goto :clearNvidiaCache
if "%choice%"=="3" goto :launchConsole
if "%choice%"=="4" goto :addAutoexec
if "%choice%"=="5" goto :LaunchSettings
if "%choice%"=="6" goto :addCs2Ini
if "%choice%"=="7" goto :exitScript

echo.
echo Invalid choice. Please try again.
timeout /t 2 >nul
goto :mainMenu


:clearShaderCache
cls
echo Clearing DirectX Shader Cache...
:: Delete files from the DirectX Shader Cache directory (usually in %LOCALAPPDATA%\D3DSCache)
del /q /f "%LOCALAPPDATA%\D3DSCache\*" >nul 2>&1
for /d %%P in ("%LOCALAPPDATA%\D3DSCache\*") do (
    rmdir /s /q "%%P" >nul 2>&1
)
echo DirectX Shader Cache cleared.
pause
goto :mainMenu


:clearNvidiaCache
cls
echo Clearing NVIDIA DXCache...
:: Delete files from %USERPROFILE%\AppData\LocalLow\NVIDIA\PerDriverVersion\DXCache
del /q /f "%USERPROFILE%\AppData\LocalLow\NVIDIA\PerDriverVersion\DXCache\*" >nul 2>&1
for /d %%P in ("%USERPROFILE%\AppData\LocalLow\NVIDIA\PerDriverVersion\DXCache\*") do (
    rmdir /s /q "%%P" >nul 2>&1
)
echo NVIDIA DXCache cleared.
pause
goto :mainMenu


:launchConsole
cls
echo Launching Steam Console...
:: Open the Steam Console via its URI
start steam://open/console
timeout /t 5 >nul
echo Copying command "shader_build 730" to clipboard...
echo shader_build 730 | clip
echo.
echo Paste into Steam console.
pause
goto :mainMenu

:addAutoexec
cls
echo Warning:
echo Change your binds and custom values after adding the autoexec
pause

@echo off
rem Turn off delayed expansion just to avoid any conflicts with special characters.
setlocal DisableDelayedExpansion

rem Prompt for the destination directory
echo Enter the full path of the CS2 directory where you want to place autoexec.cfg file
echo Example: "Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg":
set /p dest="Destination: "

echo Creating cs2.ini in "%dest%" ...

powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/er1nz/CS2-UTILITY/refs/heads/main/autoexec.cfg' -OutFile '%temp%\autoexec.cfg'"

if not exist "%temp%\autoexec.cfg" (
    echo Failed to download the settings file. Please try again later...
    timeout 2 > nul 2>&1
    goto :mainMenu
)

move /Y "%temp%\autoexec.cfg" "%dest%\autoexec.cfg" >nul 2>&1

timeout 2 > nul 2>&1

echo autoexec.cfg Created!
pause in "%dest%".
goto :mainMenu

:LaunchSettings
cls
echo The following launch parameters should be added to your game launch options:
echo.
echo -exec autoexec -noreflex -language english -allow_third_party_software
echo.
echo These parameters ensure that:
echo   - your autoexec file is executed automatically,
echo   - reflex is disabled,
echo   - the game language is set to English,
echo   - third party software is allowed.
echo.
echo Copying these parameters to clipboard...
echo -exec autoexec -noreflex -language english -allow_third_party_software | clip
echo.
echo The launch parameters have been copied to your clipboard.
pause
goto :mainMenu


:addCs2Ini
cls
echo Warning:
echo This procedure launches game files with different parameters,
echo which cannot be set manually.
echo This file was recently ported to CS2.
echo There will definitely be no VAC:
pause

@echo off
rem Turn off delayed expansion just to avoid any conflicts with special characters.
setlocal DisableDelayedExpansion

rem Prompt for the destination directory
echo Enter the full path of the CS2 directory where you want to place cs2.ini file
echo Example: "Steam\steamapps\common\Counter-Strike Global Offensive\game\bin\win64":
set /p dest="Destination: "

echo Creating cs2.ini in "%dest%" ...

powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/er1nz/CS2-UTILITY/refs/heads/main/cs2.ini' -OutFile '%temp%\cs2.ini'"

if not exist "%temp%\cs2.ini" (
    echo Failed to download the settings file. Please try again later...
    timeout 2 > nul 2>&1
    goto :mainMenu
)

move /Y "%temp%\cs2.ini" "%dest%\cs2.ini" >nul 2>&1

timeout 2 > nul 2>&1

echo cs2.ini Created!
pause in "%dest%".
goto :mainMenu


:exitScript
echo.
echo Thank you for using CS2 Utility.
timeout /t 2 >nul
exit
