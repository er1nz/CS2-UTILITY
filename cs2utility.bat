@echo off
setlocal EnableDelayedExpansion

:: Set console colors and title
title CS2 Utility Tool
color 0A

:: Initialize variables
set "SCRIPT_VERSION=0.0.2"
set "TEMP_DIR=%TEMP%\CS2Utility"
set "CS2_DETECTED_PATH="
set "CS2_CFG_PATH="
set "CS2_BIN_PATH="

:: Create temporary directory if it doesn't exist
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%" >nul 2>&1

:mainMenu
cls
echo.
echo ===============================================================================
echo                          CS2 UTILITY v%SCRIPT_VERSION% by @er1nz
echo                          https://www.github.com/er1nz
echo ===============================================================================
echo.
echo   IMPORTANT: Perform options 1-3 after every game update for optimal performance
echo.
echo        [1] Clear DirectX Shader Cache
echo        [2] Clear NVIDIA DXCache Files
echo        [3] Launch Steam Console and Send Command (shader_build 730)
echo        [4] Add autoexec.cfg file
echo        [5] Configure launch parameters
echo        [6] Add cs2.ini file
echo        [7] Test CS2 Installation Detection
echo        [8] Exit
echo.
echo ===============================================================================
set /p "choice=Select an option (1-8): "

:: Input validation
if not defined choice (
    call :showError "No option selected. Please try again."
    goto :mainMenu
)

:: Remove any spaces and validate input
set "choice=%choice: =%"
if "%choice%"=="1" goto :clearShaderCache
if "%choice%"=="2" goto :clearNvidiaCache
if "%choice%"=="3" goto :launchConsole
if "%choice%"=="4" goto :addAutoexec
if "%choice%"=="5" goto :LaunchSettings
if "%choice%"=="6" goto :addCs2Ini
if "%choice%"=="7" goto :testCS2Detection
if "%choice%"=="8" goto :exitScript

call :showError "Invalid choice '%choice%'. Please select a number between 1-8."
goto :mainMenu

:: ============================================================================
:: FUNCTION: Test CS2 Installation Detection
:: ============================================================================
:testCS2Detection
cls
echo ===============================================================================
echo                        CS2 INSTALLATION DETECTION TEST
echo ===============================================================================
echo.
echo Testing automatic CS2 installation detection...
echo.

call :detectCS2Installation
if defined CS2_DETECTED_PATH (
    echo [SUCCESS] CS2 installation detected at:
    echo !CS2_DETECTED_PATH!
    echo.
    echo Configuration path: !CS2_CFG_PATH!
    echo Binary path: !CS2_BIN_PATH!
) else (
    echo [WARNING] CS2 installation could not be automatically detected.
    echo You will need to manually specify paths when using options 4 and 6.
)

echo.
echo ===============================================================================
echo                           DEBUG PAUSE POINT
echo ===============================================================================
echo.
echo [DEBUG] CS2 detection process completed. Script paused for debugging.
echo This pause was added to prevent crashes during multi-drive scanning.
echo.
echo Current detection results:
if defined CS2_DETECTED_PATH (
    echo   CS2_DETECTED_PATH: !CS2_DETECTED_PATH!
    echo   CS2_CFG_PATH: !CS2_CFG_PATH!
    echo   CS2_BIN_PATH: !CS2_BIN_PATH!
) else (
    echo   CS2_DETECTED_PATH: [NOT SET]
    echo   CS2_CFG_PATH: [NOT SET]
    echo   CS2_BIN_PATH: [NOT SET]
)
echo.
echo Press any key to continue to main menu...
pause >nul
goto :mainMenu

:: ============================================================================
:: FUNCTION: Detect CS2 Installation
:: ============================================================================
:detectCS2Installation
echo ===============================================================================
echo                        DEBUG: STARTING CS2 DETECTION
echo ===============================================================================
echo.
echo [DEBUG] Beginning CS2 installation detection process...
echo.

:: First, try to get Steam path from registry
echo [STEP 1] Checking Windows Registry for Steam installation...
call :getSteamPathFromRegistry
if defined STEAM_PATH (
    echo [SUCCESS] Found Steam installation at: !STEAM_PATH!
    echo [DEBUG] Testing main Steam directory for CS2...
    set "test_path=!STEAM_PATH!\steamapps\common\Counter-Strike Global Offensive"
    call :validateCS2PathDirect
    if defined CS2_DETECTED_PATH (
        echo [DEBUG] CS2 found in main Steam directory! Returning to caller...
        exit /b 0
    )

    :: Check Steam library folders from libraryfolders.vdf
    echo [STEP 2] Checking Steam library folders from libraryfolders.vdf...
    call :checkSteamLibraryFolders "!STEAM_PATH!"
    if defined CS2_DETECTED_PATH (
        echo [DEBUG] CS2 found in Steam library folder! Displaying results...
        echo.
        echo ===============================================================================
        echo                    DEBUG: CS2 FOUND IN STEAM LIBRARY
        echo ===============================================================================
        echo.
        echo [SUCCESS] CS2 installation found in Steam library!
        echo.
        echo Detection Details:
        echo   Detected Path: !CS2_DETECTED_PATH!
        echo   Config Path:   !CS2_CFG_PATH!
        echo   Binary Path:   !CS2_BIN_PATH!
        echo.
        echo [DEBUG] Steam library detection completed successfully.
        echo Press any key to continue and return to test function...
        pause >nul
        exit /b 0
    )
) else (
    echo [WARNING] Steam installation not found in Windows Registry
)

:: If registry and library folders failed, try common Steam locations on C: drive
echo [STEP 3] Checking common Steam installation directories on C: drive...

echo [DEBUG] Testing: C:\Program Files (x86)\Steam\...
set "test_path=C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive"
call :validateCS2PathDirect
if defined CS2_DETECTED_PATH (
    echo [DEBUG] CS2 found in Program Files (x86)! Returning to caller...
    exit /b 0
)

echo [DEBUG] Testing: C:\Steam\...
set "test_path=C:\Steam\steamapps\common\Counter-Strike Global Offensive"
call :validateCS2PathDirect
if defined CS2_DETECTED_PATH (
    echo [DEBUG] CS2 found in C:\Steam! Returning to caller...
    exit /b 0
)

echo [DEBUG] Testing: C:\Program Files\Steam\...
set "test_path=C:\Program Files\Steam\steamapps\common\Counter-Strike Global Offensive"
call :validateCS2PathDirect
if defined CS2_DETECTED_PATH (
    echo [DEBUG] CS2 found in Program Files! Returning to caller...
    exit /b 0
)

:: If still not found, scan all available drives
echo [STEP 4] Scanning all available drives for CS2 installation...
echo [DEBUG] About to start multi-drive scanning process...
echo [WARNING] This is where crashes have been reported - adding debug pauses...
echo.
echo Press any key to continue with multi-drive scanning...
pause >nul

call :scanAllDrivesForCS2
if defined CS2_DETECTED_PATH (
    echo [DEBUG] CS2 found during multi-drive scan! Returning to caller...
    exit /b 0
)

echo [WARNING] Could not automatically detect CS2 installation.
echo [DEBUG] All detection methods exhausted - no CS2 installation found.
exit /b 1

:: ============================================================================
:: FUNCTION: Get Steam Path from Registry
:: ============================================================================
:getSteamPathFromRegistry
setlocal EnableDelayedExpansion
set "STEAM_PATH="

echo Checking Windows Registry for Steam installation...

:: Try to get Steam path from registry (64-bit)
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Valve\Steam" /v InstallPath 2^>nul') do (
    set "STEAM_PATH=%%b"
)

:: If not found, try 32-bit registry
if not defined STEAM_PATH (
    for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Valve\Steam" /v InstallPath 2^>nul') do (
        set "STEAM_PATH=%%b"
    )
)

:: Try current user registry as fallback
if not defined STEAM_PATH (
    for /f "tokens=2*" %%a in ('reg query "HKEY_CURRENT_USER\SOFTWARE\Valve\Steam" /v SteamPath 2^>nul') do (
        set "STEAM_PATH=%%b"
    )
)

endlocal & set "STEAM_PATH=%STEAM_PATH%"
exit /b 0

:: ============================================================================
:: FUNCTION: Check Steam Library Folders
:: ============================================================================
:checkSteamLibraryFolders
setlocal EnableDelayedExpansion
set "steam_path=%~1"
set "vdf_file=!steam_path!\config\libraryfolders.vdf"

echo Checking Steam library configuration file: !vdf_file!

if not exist "!vdf_file!" (
    echo Steam library configuration file not found.
    endlocal
    exit /b 1
)

echo Parsing Steam library folders...
set "library_count=0"

:: Use a safer approach to read the VDF file
for /f "usebackq delims=" %%a in ("!vdf_file!") do (
    set "line=%%a"
    :: Look for lines containing "path" (case insensitive)
    echo "!line!" | findstr /i /c:"path" >nul 2>&1
    if !errorlevel! equ 0 (
        :: Extract path using a more robust method
        set "temp_line=!line!"
        :: Remove tabs and extra spaces
        set "temp_line=!temp_line:	= !"

        :: Look for the path value after "path"
        for /f "tokens=1,2,3,4,5,6,7,8,9" %%i in ("!temp_line!") do (
            set "potential_path=%%j"
            if not "!potential_path!"=="" (
                :: Clean up the path (remove quotes)
                set "potential_path=!potential_path:"=!"
                :: Replace forward slashes with backslashes
                set "potential_path=!potential_path:/=\!"

                :: Validate this looks like a real path
                if exist "!potential_path!" (
                    set /a "library_count=!library_count!+1" 2>nul
                    if errorlevel 1 (
                        echo [WARNING] Arithmetic error in library counting, using fallback
                        set "library_count=1"
                    )
                    echo Found Steam library !library_count!: !potential_path!

                    :: Check if CS2 exists in this library
                    set "test_path=!potential_path!\steamapps\common\Counter-Strike Global Offensive"
                    call :validateCS2PathDirectSafe
                    if defined CS2_DETECTED_PATH (
                        echo [SUCCESS] CS2 found in Steam library: !potential_path!
                        :: Properly preserve variables across endlocal using individual for loops
                        for %%a in ("!CS2_DETECTED_PATH!") do (
                            for %%b in ("!CS2_CFG_PATH!") do (
                                for %%c in ("!CS2_BIN_PATH!") do (
                                    endlocal
                                    set "CS2_DETECTED_PATH=%%~a"
                                    set "CS2_CFG_PATH=%%~b"
                                    set "CS2_BIN_PATH=%%~c"
                                )
                            )
                        )
                        exit /b 0
                    )
                )
            )
        )
    )
)

if !library_count! equ 0 (
    echo No valid Steam library folders found in configuration file.
) else (
    echo Checked !library_count! Steam library folders - no CS2 installation found.
)
endlocal
exit /b 1

:: ============================================================================
:: FUNCTION: Scan All Drives for CS2
:: ============================================================================
:scanAllDrivesForCS2
:: Don't use setlocal here to avoid variable scope issues

echo ===============================================================================
echo                      DEBUG: MULTI-DRIVE SCANNING STARTED
echo ===============================================================================
echo.
echo [DEBUG] Starting multi-drive scanning process...
echo [DEBUG] This function has been identified as a potential crash point.
echo.

echo [DEBUG] Detecting available drives...
set "drive_list="
set "drive_count=0"

:: Use a more reliable method to get drive letters with better error handling
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%d:\" (
        echo Checking drive %%d: for type...
        :: Check if it's a fixed drive (not CD-ROM, network, etc.) with error handling
        set "is_fixed_drive=0"
        for /f "skip=1 tokens=2" %%t in ('wmic logicaldisk where "DeviceID='%%d:'" get DriveType 2^>nul ^| findstr /r "^[0-9]"') do (
            if "%%t"=="3" (
                set "is_fixed_drive=1"
            )
        )

        :: Fallback method if wmic fails - assume it's a fixed drive if it exists and is accessible
        if "!is_fixed_drive!"=="0" (
            dir "%%d:\" >nul 2>&1
            if not errorlevel 1 (
                echo Drive %%d: appears to be accessible, treating as fixed drive
                set "is_fixed_drive=1"
            )
        )

        if "!is_fixed_drive!"=="1" (
            set "drive_list=!drive_list! %%d:"
            set /a "drive_count=!drive_count!+1" 2>nul
            if errorlevel 1 (
                echo [WARNING] Arithmetic error in drive counting, using fallback method
                set "drive_count=1"
                for %%x in (!drive_list!) do set /a "drive_count=!drive_count!+1" 2>nul
            )
            echo Added drive %%d: to scan list ^(count: !drive_count!^)
        )
    )
)

if !drive_count! equ 0 (
    echo No fixed drives found for scanning.
    echo Attempting fallback scan of common drives...
    :: Fallback - scan C, D, E drives regardless
    set "drive_list= C: D: E:"
    set "drive_count=3"
    echo Using fallback drive list: !drive_list!
)

echo [DEBUG] Found !drive_count! drives to scan: !drive_list!
echo.
echo [DEBUG] About to start scanning each drive individually...
echo [WARNING] If the script crashes, it will likely happen during this loop.
echo.
echo Press any key to start drive-by-drive scanning...
pause >nul

:: Check each drive with timeout protection
set "scanned_count=0"
echo [DEBUG] Starting drive scanning loop...
for %%d in (!drive_list!) do (
    set "drive=%%d"
    set /a "scanned_count=!scanned_count!+1" 2>nul
    if errorlevel 1 set "scanned_count=1"
    echo.
    echo ===============================================================================
    echo [!scanned_count!/!drive_count!] SCANNING DRIVE !drive! FOR CS2
    echo ===============================================================================
    echo [DEBUG] Current drive: !drive!
    echo [DEBUG] Scan progress: !scanned_count! of !drive_count! drives

    :: Check common Steam library locations with error handling
    echo [DEBUG] Checking 6 common Steam locations on drive !drive!...

    :: Priority 1: SteamLibrary (most common for secondary drives)
    echo [DEBUG] [1/6] Checking: !drive!\SteamLibrary\...
    call :checkDriveLocation "!drive!" "SteamLibrary"
    if defined CS2_DETECTED_PATH (
        echo [SUCCESS] CS2 found on drive !drive! in SteamLibrary folder!
        echo [DEBUG] Exiting multi-drive scan - CS2 found!
        exit /b 0
    )

    :: Priority 2: Games\SteamLibrary (alternative common pattern)
    echo [DEBUG] [2/6] Checking: !drive!\Games\SteamLibrary\...
    call :checkDriveLocation "!drive!" "Games\SteamLibrary"
    if defined CS2_DETECTED_PATH (
        echo [SUCCESS] CS2 found on drive !drive! in Games\SteamLibrary folder!
        echo [DEBUG] Exiting multi-drive scan - CS2 found!
        exit /b 0
    )

    :: Priority 3: Steam (root Steam folder)
    echo [DEBUG] [3/6] Checking: !drive!\Steam\...
    call :checkDriveLocation "!drive!" "Steam"
    if defined CS2_DETECTED_PATH (
        echo [SUCCESS] CS2 found on drive !drive! in Steam folder!
        echo [DEBUG] Exiting multi-drive scan - CS2 found!
        exit /b 0
    )

    :: Priority 4: Program Files (x86)\Steam (standard Windows location)
    echo [DEBUG] [4/6] Checking: !drive!\Program Files (x86)\Steam\...
    call :checkDriveLocation "!drive!" "Program Files (x86)\Steam"
    if defined CS2_DETECTED_PATH (
        echo [SUCCESS] CS2 found on drive !drive! in Program Files (x86)!
        echo [DEBUG] Exiting multi-drive scan - CS2 found!
        exit /b 0
    )

    :: Priority 5: Program Files\Steam (64-bit Steam installation)
    echo [DEBUG] [5/6] Checking: !drive!\Program Files\Steam\...
    call :checkDriveLocation "!drive!" "Program Files\Steam"
    if defined CS2_DETECTED_PATH (
        echo [SUCCESS] CS2 found on drive !drive! in Program Files!
        echo [DEBUG] Exiting multi-drive scan - CS2 found!
        exit /b 0
    )

    :: Priority 6: Games\Steam (alternative Games folder pattern)
    echo [DEBUG] [6/6] Checking: !drive!\Games\Steam\...
    call :checkDriveLocation "!drive!" "Games\Steam"
    if defined CS2_DETECTED_PATH (
        echo [SUCCESS] CS2 found on drive !drive! in Games\Steam folder!
        echo [DEBUG] Exiting multi-drive scan - CS2 found!
        exit /b 0
    )

    echo [DEBUG] Drive !drive! scan completed - no CS2 installation found
    echo [DEBUG] Moving to next drive...
    echo.
)

echo ===============================================================================
echo                    DEBUG: MULTI-DRIVE SCANNING COMPLETED
echo ===============================================================================
echo.
echo [DEBUG] Multi-drive scanning process completed successfully!
echo [DEBUG] Scanned !scanned_count! drives - no CS2 installation found.
echo [DEBUG] No crashes occurred during the scanning process.
echo.
echo [DEBUG] Returning to main detection function...
exit /b 1

:: ============================================================================
:: FUNCTION: Check Drive Location (Helper for drive scanning)
:: ============================================================================
:checkDriveLocation
:: Don't use setlocal here to avoid variable scope issues
set "drive=%~1"
set "location=%~2"
set "full_path=%drive%\%location%\steamapps\common\Counter-Strike Global Offensive"

:: Quick existence check first
if exist "%full_path%" (
    set "test_path=%full_path%"
    call :validateCS2PathDirectSafe
    if defined CS2_DETECTED_PATH (
        exit /b 0
    )
)

exit /b 1

:: ============================================================================
:: FUNCTION: Safe CS2 Path Validation (with error handling)
:: ============================================================================
:validateCS2PathDirectSafe
:: Don't use setlocal here to avoid variable scope issues
:: The calling function will handle the scope

:: Don't echo every check to reduce noise
if not exist "!test_path!" (
    exit /b 1
)

:: Check for key CS2 files/directories with error handling
if not exist "!test_path!\game" (
    exit /b 1
)
if not exist "!test_path!\game\csgo" (
    exit /b 1
)
if not exist "!test_path!\game\bin\win64" (
    exit /b 1
)

:: Path is valid - set variables in current scope
set "CS2_DETECTED_PATH=!test_path!"
set "CS2_CFG_PATH=!test_path!\game\csgo\cfg"
set "CS2_BIN_PATH=!test_path!\game\bin\win64"
echo [SUCCESS] Valid CS2 installation found at: !test_path!
echo [DEBUG] CS2 paths set - returning to calling function
exit /b 0

:: ============================================================================
:: FUNCTION: Validate CS2 Path (Direct - uses test_path variable)
:: ============================================================================
:validateCS2PathDirect
echo Checking path: !test_path!

if not exist "!test_path!" (
    echo Path does not exist: !test_path!
    exit /b 1
)

:: Check for key CS2 files/directories
if not exist "!test_path!\game" (
    echo Missing 'game' directory in: !test_path!
    exit /b 1
)
if not exist "!test_path!\game\csgo" (
    echo Missing 'game\csgo' directory in: !test_path!
    exit /b 1
)
if not exist "!test_path!\game\bin\win64" (
    echo Missing 'game\bin\win64' directory in: !test_path!
    exit /b 1
)

:: Path is valid - set global variables
set "CS2_DETECTED_PATH=!test_path!"
set "CS2_CFG_PATH=!test_path!\game\csgo\cfg"
set "CS2_BIN_PATH=!test_path!\game\bin\win64"
echo [SUCCESS] Valid CS2 installation found at: !test_path!
echo.
echo ===============================================================================
echo                        DEBUG: CS2 INSTALLATION FOUND
echo ===============================================================================
echo.
echo [DEBUG] CS2 installation successfully detected and validated!
echo.
echo Detection Details:
echo   Detected Path: !test_path!
echo   Config Path:   !CS2_CFG_PATH!
echo   Binary Path:   !CS2_BIN_PATH!
echo.
echo Validation Status:
echo   - Main directory exists: YES
echo   - game folder exists: YES
echo   - game\csgo folder exists: YES
echo   - game\bin\win64 folder exists: YES
echo.
echo [DEBUG] Pausing to prevent automatic script closure...
echo Press any key to continue with detection process...
pause >nul
exit /b 0

:: ============================================================================
:: FUNCTION: Validate CS2 Path (Parameter-based)
:: ============================================================================
:validateCS2Path
set "test_path=%*"

echo Checking path: %test_path%

if not exist "%test_path%" (
    echo Path does not exist: %test_path%
    exit /b 1
)

:: Check for key CS2 files/directories
if not exist "%test_path%\game" (
    echo Missing 'game' directory in: %test_path%
    exit /b 1
)
if not exist "%test_path%\game\csgo" (
    echo Missing 'game\csgo' directory in: %test_path%
    exit /b 1
)
if not exist "%test_path%\game\bin\win64" (
    echo Missing 'game\bin\win64' directory in: %test_path%
    exit /b 1
)

:: Path is valid - set global variables
set "CS2_DETECTED_PATH=%test_path%"
set "CS2_CFG_PATH=%test_path%\game\csgo\cfg"
set "CS2_BIN_PATH=%test_path%\game\bin\win64"
echo [SUCCESS] Valid CS2 installation found at: %test_path%
exit /b 0

:: ============================================================================
:: FUNCTION: Prompt for Path Selection
:: ============================================================================
:promptPathSelection
set "path_type=%~1"
set "return_var=%~2"

echo ===============================================================================
echo                          CS2 PATH SELECTION
echo ===============================================================================
echo.
echo Choose how to specify your CS2 %path_type% directory:
echo.
echo   [1] Auto-detect CS2 installation (Recommended)
echo   [2] Manually enter path
echo.
set /p "path_choice=Select option (1-2): "

if "%path_choice%"=="1" (
    echo.
    echo Attempting auto-detection...
    call :detectCS2Installation
    if defined CS2_DETECTED_PATH (
        if "%path_type%"=="configuration" (
            set "selected_path=!CS2_CFG_PATH!"
        ) else if "%path_type%"=="binary" (
            set "selected_path=!CS2_BIN_PATH!"
        )
        echo.
        echo [SUCCESS] Auto-detected path: !selected_path!
        echo.
        set /p "confirm=Use this path? (y/n): "
        if /i "!confirm!"=="y" (
            set "%return_var%=!selected_path!"
            exit /b 0
        )
    ) else (
        echo [WARNING] Auto-detection failed. Falling back to manual entry.
    )
) else if "%path_choice%"=="2" (
    echo.
    echo Manual path entry selected.
) else (
    echo [WARNING] Invalid selection. Defaulting to auto-detection.
    echo.
    echo Attempting auto-detection...
    call :detectCS2Installation
    if defined CS2_DETECTED_PATH (
        if "%path_type%"=="configuration" (
            set "selected_path=!CS2_CFG_PATH!"
        ) else if "%path_type%"=="binary" (
            set "selected_path=!CS2_BIN_PATH!"
        )
        echo.
        echo [SUCCESS] Auto-detected path: !selected_path!
        echo.
        set /p "confirm=Use this path? (y/n): "
        if /i "!confirm!"=="y" (
            set "%return_var%=!selected_path!"
            exit /b 0
        )
    ) else (
        echo [WARNING] Auto-detection failed. Falling back to manual entry.
    )
)

:: Manual path entry
echo.
echo Enter the full path to your CS2 %path_type% directory:
echo.
if "%path_type%"=="configuration" (
    echo Example: C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg
) else if "%path_type%"=="binary" (
    echo Example: C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\bin\win64
)
echo.
set /p "manual_path=Enter path: "

if not defined manual_path (
    echo [ERROR] No path entered. Operation cancelled.
    exit /b 1
)

:: Remove quotes if present
set "manual_path=!manual_path:"=!"

set "%return_var%=!manual_path!"
exit /b 0

:: ============================================================================
:: FUNCTION: Validate and Create Directory
:: ============================================================================
:validateAndCreateDirectory
setlocal EnableDelayedExpansion
set "target_dir=%~1"
set "dir_type=%~2"

echo.
echo Validating !dir_type! directory: !target_dir!

:: Check if directory exists
if not exist "!target_dir!" (
    echo.
    echo [WARNING] Directory does not exist: !target_dir!
    set /p "create=Create directory? (y/n): "
    if /i "!create!"=="y" (
        echo Creating directory: !target_dir!
        mkdir "!target_dir!" 2>nul
        if errorlevel 1 (
            echo [ERROR] Failed to create directory: !target_dir!
            echo Please check permissions and try again.
            echo.
            echo Attempting to create parent directories...
            md "!target_dir!" 2>nul
            if errorlevel 1 (
                echo [ERROR] Still failed to create directory.
                echo Please manually create the directory or check permissions.
                endlocal
                exit /b 1
            )
        )
        echo [SUCCESS] Directory created: !target_dir!
    ) else (
        echo Operation cancelled.
        endlocal
        exit /b 1
    )
)

:: Additional validation for CS2 directories
if "!dir_type!"=="configuration" (
    :: Check if this looks like a valid CS2 cfg directory
    :: The cfg directory should be inside csgo folder, so parent should be named 'csgo'
    for %%i in ("!target_dir!\..") do set "parent_name=%%~ni"
    if not "!parent_name!"=="csgo" (
        echo [WARNING] This doesn't appear to be a valid CS2 configuration directory.
        echo Expected the cfg directory to be inside a 'csgo' folder.
        echo Current path: !target_dir!
        set /p "continue=Continue anyway? (y/n): "
        if /i not "!continue!"=="y" (
            endlocal
            exit /b 1
        )
    )
) else if "!dir_type!"=="binary" (
    :: Check if this looks like a valid CS2 binary directory
    :: The win64 directory should be inside bin folder, which is inside game folder
    :: So we check if game\csgo exists relative to the bin directory
    set "game_dir=!target_dir!\..\..\"
    if not exist "!game_dir!\csgo" (
        echo [WARNING] This doesn't appear to be a valid CS2 binary directory.
        echo Expected to find 'csgo' folder in the game directory.
        echo Current path: !target_dir!
        set /p "continue=Continue anyway? (y/n): "
        if /i not "!continue!"=="y" (
            endlocal
            exit /b 1
        )
    )
)

echo [SUCCESS] Directory validated: !target_dir!
endlocal
exit /b 0

:: ============================================================================
:: FUNCTION: Clear DirectX Shader Cache
:: ============================================================================
:clearShaderCache
cls
echo Clearing DirectX Shader Cache...
echo.

set "SHADER_CACHE_DIR=%LOCALAPPDATA%\D3DSCache"

if not exist "%SHADER_CACHE_DIR%" (
    echo DirectX Shader Cache directory not found at:
    echo %SHADER_CACHE_DIR%
    echo This is normal if you haven't run DirectX applications recently.
    pause
    goto :mainMenu
)

echo Deleting files from: %SHADER_CACHE_DIR%
del /q /f "%SHADER_CACHE_DIR%\*" >nul 2>&1

:: Remove subdirectories more reliably with PowerShell
echo Removing directories with PowerShell...
powershell -Command "Get-ChildItem -Path '%SHADER_CACHE_DIR%' -Recurse -Force | Remove-Item -Recurse -Force -ErrorAction Stop"

echo.
echo [SUCCESS] DirectX Shader Cache cleared successfully.
call :pressAnyKey
goto :mainMenu

:: ============================================================================
:: FUNCTION: Clear NVIDIA DXCache
:: ============================================================================
:clearNvidiaCache
cls
echo Clearing NVIDIA DXCache...
echo If you notice any errors, that's fine.
echo.

set "NVIDIA_CACHE_DIR=%USERPROFILE%\AppData\LocalLow\NVIDIA\PerDriverVersion\DXCache"

if not exist "%NVIDIA_CACHE_DIR%" (
    echo NVIDIA DXCache directory not found at:
    echo %NVIDIA_CACHE_DIR%
    echo This is normal if you don't have NVIDIA graphics or haven't run games recently.
    pause
    goto :mainMenu
)

echo Deleting files from: %NVIDIA_CACHE_DIR%
del /q /f "%NVIDIA_CACHE_DIR%\*" >nul 2>&1

:: Remove subdirectories using PowerShell for better reliability
echo Removing directories with PowerShell...
powershell -Command "Get-ChildItem -Path '%NVIDIA_CACHE_DIR%' -Recurse -Force | Remove-Item -Recurse -Force -ErrorAction Stop"

echo.
echo [SUCCESS] NVIDIA DXCache cleared successfully.
call :pressAnyKey
goto :mainMenu

:: ============================================================================
:: FUNCTION: Launch Steam Console
:: ============================================================================
:launchConsole
cls
echo Launching Steam Console...
echo.

:: Check if Steam is running
tasklist /FI "IMAGENAME eq steam.exe" 2>nul | find /I /N "steam.exe" >nul
if errorlevel 1 (
    echo [WARNING] Steam doesn't appear to be running.
    echo Please start Steam first, then try again.
    echo.
    set /p "continue=Continue anyway? (y/n): "
    if /i not "!continue!"=="y" goto :mainMenu
)

echo Opening Steam Console...
start steam://open/console

echo Waiting for Steam Console to load...
timeout /t 3 >nul

echo.
echo Copying command to clipboard: shader_build 730
echo shader_build 730 | clip

echo.
echo [INSTRUCTIONS]
echo 1. The Steam Console should now be open
echo 2. The command "shader_build 730" has been copied to your clipboard
echo 3. Paste it into the Steam Console and press Enter
echo.
call :pressAnyKey
goto :mainMenu

:: ============================================================================
:: FUNCTION: Add autoexec.cfg file
:: ============================================================================
:addAutoexec
cls
echo ===============================================================================
echo                            ADD AUTOEXEC.CFG FILE
echo ===============================================================================
echo.
echo [WARNING] Change your binds and custom values after adding the autoexec
echo.
call :pressAnyKey

:: Use new path selection system
call :promptPathSelection "configuration" "CS2_CFG_DIR"
if errorlevel 1 goto :mainMenu

:: Validate and create directory if needed
call :validateAndCreateDirectory "!CS2_CFG_DIR!" "configuration"
if errorlevel 1 goto :mainMenu

echo.
echo Downloading autoexec.cfg from GitHub...
call :downloadFile "https://raw.githubusercontent.com/er1nz/CS2-UTILITY/refs/heads/main/autoexec.cfg" "autoexec.cfg" "!CS2_CFG_DIR!"
if errorlevel 1 goto :mainMenu

echo.
echo [SUCCESS] autoexec.cfg has been created in "!CS2_CFG_DIR!"
call :pressAnyKey
goto :mainMenu

:: ============================================================================
:: FUNCTION: Configure Launch Parameters
:: ============================================================================
:LaunchSettings
cls
echo ===============================================================================
echo                         CONFIGURE LAUNCH PARAMETERS
echo ===============================================================================
echo.
echo The following launch parameters should be added to your CS2 launch options:
echo.
echo    -exec autoexec -noreflex -language english -allow_third_party_software
echo.
echo These parameters ensure:
echo   • Your autoexec file is executed automatically
echo   • Reflex is disabled (can improve performance on some systems)
echo   • Game language is set to English
echo   • Third party software is allowed
echo.
echo [INFO] Copying parameters to clipboard...
echo -exec autoexec -noreflex -language english -allow_third_party_software | clip
echo.
echo [SUCCESS] Launch parameters copied to clipboard.
echo.
echo [INSTRUCTIONS]
echo 1. Open Steam Library
echo 2. Right-click on Counter-Strike 2
echo 3. Select "Properties"
echo 4. In the "Launch Options" field, paste the copied parameters
echo 5. Close the Properties window
echo.
call :pressAnyKey
goto :mainMenu

:: ============================================================================
:: FUNCTION: Add cs2.ini file
:: ============================================================================
:addCs2Ini
cls
echo ===============================================================================
echo                              ADD CS2.INI FILE
echo ===============================================================================
echo.
echo [WARNING] This procedure modifies game launch parameters that cannot be
echo set manually. This file was recently ported to CS2.
echo.
echo [SECURITY] This will NOT trigger VAC (Valve Anti-Cheat) bans.
echo.
call :pressAnyKey

:: Use new path selection system
call :promptPathSelection "binary" "CS2_BIN_DIR"
if errorlevel 1 goto :mainMenu

:: Validate and create directory if needed
call :validateAndCreateDirectory "!CS2_BIN_DIR!" "binary"
if errorlevel 1 goto :mainMenu

echo.
echo Downloading cs2.ini from GitHub...
call :downloadFile "https://raw.githubusercontent.com/er1nz/CS2-UTILITY/refs/heads/main/cs2.ini" "cs2.ini" "!CS2_BIN_DIR!"
if errorlevel 1 goto :mainMenu

echo.
echo [SUCCESS] cs2.ini has been created in "!CS2_BIN_DIR!"
call :pressAnyKey
goto :mainMenu

:: ============================================================================
:: UTILITY FUNCTIONS
:: ============================================================================

:getCS2Directory
:: Parameters: %1=file type, %2=subdirectory, %3=return variable name
echo Enter the full path to your CS2 directory where you want to place the %~1 file.
echo.
echo Example path structure:
echo   Steam\steamapps\common\Counter-Strike Global Offensive\%~2
echo.
echo Common Steam locations:
echo   C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\%~2
echo   C:\Steam\steamapps\common\Counter-Strike Global Offensive\%~2
echo.
set /p "dest=Enter destination path: "

:: Validate input
if not defined dest (
    call :showError "No path entered. Operation cancelled."
    exit /b 1
)

:: Remove quotes if present
set "dest=%dest:"=%"

:: Check if directory exists
if not exist "%dest%" (
    echo.
    echo [WARNING] Directory does not exist: %dest%
    set /p "create=Create directory? (y/n): "
    if /i "%create%"=="y" (
        mkdir "%dest%" >nul 2>&1
        if errorlevel 1 (
            call :showError "Failed to create directory: %dest%"
            exit /b 1
        )
        echo [SUCCESS] Directory created: %dest%
    ) else (
        echo Operation cancelled.
        exit /b 1
    )
)

:: Set the return variable
set "%~3=%dest%"
exit /b 0

:downloadFile
:: Parameters: %1=URL, %2=filename, %3=destination directory
setlocal
set "url=%~1"
set "filename=%~2"
set "destdir=%~3"
set "tempfile=%TEMP_DIR%\%filename%"

echo Downloading from: %url%
echo Temporary file: %tempfile%

powershell -Command "try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%url%' -OutFile '%tempfile%' -UseBasicParsing } catch { exit 1 }"
if errorlevel 1 (
    call :showError "Failed to download %filename%. Please check your internet connection."
    exit /b 1
)

if not exist "%tempfile%" (
    call :showError "Download failed - file not found: %tempfile%"
    exit /b 1
)

echo Moving file to destination...
move /Y "%tempfile%" "%destdir%\%filename%" >nul 2>&1
if errorlevel 1 (
    call :showError "Failed to move %filename% to %destdir%"
    exit /b 1
)

echo [SUCCESS] %filename% downloaded and installed successfully.
exit /b 0

:showError
echo.
echo [ERROR] %~1
echo.
timeout /t 3 >nul
exit /b 0

:pressAnyKey
echo.
echo Press any key to continue...
pause >nul
exit /b 0

:: ============================================================================
:: EXIT SCRIPT
:: ============================================================================
:exitScript
cls
echo.
echo ===============================================================================
echo  [SUCCESS] CS2 Utility v%SCRIPT_VERSION% completed successfully
echo  All operations finished at %time% on %date%
echo  https://www.github.com/er1nz
echo ===============================================================================
echo.
echo Cleaning up temporary files...
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" >nul 2>&1

timeout /t 3 >nul
exit /b 0

