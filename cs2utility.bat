@echo off
setlocal EnableDelayedExpansion

:: Set console colors and title
title CS2 Utility Tool
color 0A

:: Initialize variables
set "SCRIPT_VERSION=0.0.3"
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
echo        [7] Apply Steam Tweaks (Performance Optimization)
echo        [8] Apply Network Tweaks
echo        [9] Run System Corruption Checker
echo        [10] Test CS2 Installation Detection
echo        [11] Exit
echo.
echo ===============================================================================
set /p "choice=Select an option (1-11): "

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
if "%choice%"=="7" goto :applySteamTweaks 
if "%choice%"=="8" goto :NetworkTweaks
if "%choice%"=="9" goto :runCorruptionChecker
if "%choice%"=="10" goto :testCS2Detection 
if "%choice%"=="11" goto :exitScript

call :showError "Invalid choice '%choice%'. Please select a number between 1-11."
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
        :: Replace forward slashes with backslashes if needed
        set "STEAM_PATH=!STEAM_PATH:/=\!"
    )
)

:: Return the value to the calling environment
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
:: FUNCTION: Get Manual CS2 Config Path
:: ============================================================================
:getManualCS2ConfigPath
echo.
echo Enter the full path to your CS2 configuration directory:
echo.
echo Example: C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg
echo.
set /p "CS2_CFG_PATH=Enter path: "

if not defined CS2_CFG_PATH (
    echo [ERROR] No path entered. Operation cancelled.
    exit /b 1
)

:: Remove quotes if present
set "CS2_CFG_PATH=!CS2_CFG_PATH:"=!"

:: Validate CS2 config path
if not exist "!CS2_CFG_PATH!" (
    echo.
    echo [WARNING] Directory does not exist: !CS2_CFG_PATH!
    set /p "create=Create directory? (y/n): "
    if /i "!create!"=="y" (
        echo Creating directory: !CS2_CFG_PATH!
        mkdir "!CS2_CFG_PATH!" 2>nul
        if errorlevel 1 (
            echo [ERROR] Failed to create directory: !CS2_CFG_PATH!
            echo Please check permissions and try again.
            exit /b 1
        )
        echo [SUCCESS] Directory created: !CS2_CFG_PATH!
    ) else (
        echo Operation cancelled.
        exit /b 1
    )
)

echo [SUCCESS] CS2 configuration path set to: !CS2_CFG_PATH!
exit /b 0

:: ============================================================================
:: FUNCTION: Get Manual CS2 Binary Path
:: ============================================================================
:getManualCS2BinaryPath
echo.
echo Enter the full path to your CS2 binary directory:
echo.
echo Example: C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive\game\bin\win64
echo.
set /p "CS2_BIN_PATH=Enter path: "

if not defined CS2_BIN_PATH (
    echo [ERROR] No path entered. Operation cancelled.
    exit /b 1
)

:: Remove quotes if present
set "CS2_BIN_PATH=!CS2_BIN_PATH:"=!"

:: Validate CS2 binary path
if not exist "!CS2_BIN_PATH!" (
    echo.
    echo [WARNING] Directory does not exist: !CS2_BIN_PATH!
    set /p "create=Create directory? (y/n): "
    if /i "!create!"=="y" (
        echo Creating directory: !CS2_BIN_PATH!
        mkdir "!CS2_BIN_PATH!" 2>nul
        if errorlevel 1 (
            echo [ERROR] Failed to create directory: !CS2_BIN_PATH!
            echo Please check permissions and try again.
            exit /b 1
        )
        echo [SUCCESS] Directory created: !CS2_BIN_PATH!
    ) else (
        echo Operation cancelled.
        exit /b 1
    )
)

echo [SUCCESS] CS2 binary path set to: !CS2_BIN_PATH!
exit /b 0

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

:: First try auto-detection
echo Attempting to auto-detect CS2 installation...
call :detectCS2Installation

if defined CS2_CFG_PATH (
    echo.
    echo [SUCCESS] Auto-detected CS2 configuration path: !CS2_CFG_PATH!
    echo.
    set /p "confirm=Use this path? (y/n): "
    if /i not "!confirm!"=="y" (
        :: If user doesn't want to use auto-detected path, use manual entry
        call :getManualCS2ConfigPath
        if errorlevel 1 goto :mainMenu
    )
) else (
    echo.
    echo [WARNING] Could not auto-detect CS2 installation.
    echo You will need to manually specify the configuration path.
    echo.
    call :getManualCS2ConfigPath
    if errorlevel 1 goto :mainMenu
)

echo.
echo Downloading autoexec.cfg from GitHub...
call :downloadFile "https://raw.githubusercontent.com/er1nz/CS2-UTILITY/refs/heads/main/autoexec.cfg" "autoexec.cfg" "!CS2_CFG_PATH!"
if errorlevel 1 goto :mainMenu

echo.
echo [SUCCESS] autoexec.cfg has been created in "!CS2_CFG_PATH!"
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

:: First try auto-detection
echo Attempting to auto-detect CS2 installation...
call :detectCS2Installation

if defined CS2_BIN_PATH (
    echo.
    echo [SUCCESS] Auto-detected CS2 binary path: !CS2_BIN_PATH!
    echo.
    set /p "confirm=Use this path? (y/n): "
    if /i not "!confirm!"=="y" (
        :: If user doesn't want to use auto-detected path, use manual entry
        call :getManualCS2BinaryPath
        if errorlevel 1 goto :mainMenu
    )
) else (
    echo.
    echo [WARNING] Could not auto-detect CS2 installation.
    echo You will need to manually specify the binary path.
    echo.
    call :getManualCS2BinaryPath
    if errorlevel 1 goto :mainMenu
)

echo.
echo Downloading cs2.ini from GitHub...
call :downloadFile "https://raw.githubusercontent.com/er1nz/CS2-UTILITY/refs/heads/main/cs2.ini" "cs2.ini" "!CS2_BIN_PATH!"
if errorlevel 1 goto :mainMenu

echo.
echo [SUCCESS] cs2.ini has been created in "!CS2_BIN_PATH!"
call :pressAnyKey
goto :mainMenu

:: ============================================================================
:: FUNCTION: Run System Corruption Checker
:: ============================================================================
:runCorruptionChecker
cls
echo ===============================================================================
echo                        SYSTEM CORRUPTION CHECKER
echo ===============================================================================
echo.
echo This tool will check and repair system files, clean up disk space,
echo and fix potential corruption issues on your system.
echo.
echo [WARNING] This process requires administrator privileges and may take some time.
echo Some operations will require system restart to complete.
echo.
set /p "confirm=Do you want to continue? (y/n): "
if /i not "%confirm%"=="y" goto :mainMenu

:: Check for admin rights
echo.
echo Checking for administrator privileges...
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Administrator privileges required.
    echo Attempting to restart with elevated permissions...
    
    powershell -Command "Start-Process cmd -ArgumentList '/c %~s0' -Verb RunAs"
    exit /b
)

echo [SUCCESS] Running with administrator privileges.
echo.
echo ===============================================================================
echo                        QUICK DISK CHECK
echo ===============================================================================
echo.
echo Running quick disk check on all drives...
echo This will identify but not repair any issues.
echo.

for %%D in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist %%D:\ (
        echo Checking drive %%D:...
        chkdsk %%D: /scan
    )
)

echo.
echo ===============================================================================
echo                        SYSTEM FILE REPAIR
echo ===============================================================================
echo.
echo Running DISM to check and repair system image...
echo.
dism.exe /Online /Cleanup-Image /CheckHealth
echo.
echo Running DISM scan health...
dism.exe /Online /Cleanup-Image /ScanHealth
echo.
echo Running DISM restore health (this may take some time)...
dism.exe /Online /Cleanup-Image /RestoreHealth
echo.
echo Running System File Checker (SFC)...
sfc /scannow

echo.
echo ===============================================================================
echo                        CLEANING TEMPORARY FILES
echo ===============================================================================
echo.
echo Clearing temporary files and system caches...

:: Grant permissions to temp folders
echo Granting permissions to temp folders...
icacls "%TEMP%" /Grant Everyone:(OI)(CI)F /T >nul 2>&1
icacls "%USERPROFILE%\AppData\Local\Temp" /grant Everyone:(OI)(CI)F /T >nul 2>&1
icacls "C:\Windows\Temp" /Grant Everyone:(OI)(CI)F /T >nul 2>&1
icacls "C:\Windows\Prefetch" /Grant Everyone:(OI)(CI)F /T >nul 2>&1

:: Clear temp folders
echo Clearing temporary folders...
for /D %%G in ("%TEMP%\*") do rd /S /Q "%%G" 2>nul
del /Q "%TEMP%\*" >nul 2>&1
for /D %%G in ("%USERPROFILE%\AppData\Local\Temp\*") do rd /S /Q "%%G" 2>nul
del /Q "%USERPROFILE%\AppData\Local\Temp\*" >nul 2>&1
for /D %%G in ("C:\Windows\Temp\*") do rd /S /Q "%%G" 2>nul
del /Q "C:\Windows\Temp\*" >nul 2>&1
for /D %%G in ("C:\Windows\Prefetch\*") do rd /S /Q "%%G" 2>nul
del /Q "C:\Windows\Prefetch\*" >nul 2>&1

:: Run disk cleanup
echo Running disk cleanup...
cleanmgr /sagerun:1 >nul 2>&1

:: Clear DNS cache
echo Clearing DNS cache...
ipconfig /flushdns >nul 2>&1

:: Clear event logs
echo Clearing event logs...
for /F "tokens=*" %%G in ('wevtutil el') do (
    wevtutil cl "%%G" >nul 2>&1
)

echo.
echo ===============================================================================
echo                        SYSTEM CORRUPTION CHECK COMPLETE
echo ===============================================================================
echo.
echo [SUCCESS] System corruption check and repair completed.
echo It's recommended to restart your computer to apply all changes.
echo.
set /p "restart=Would you like to restart your computer now? (y/n): "
if /i "%restart%"=="y" (
    echo Restarting computer in 10 seconds...
    shutdown /r /t 10 /c "Restarting to complete system repairs"
) else (
    echo Please remember to restart your computer later to complete the repairs.
)

call :pressAnyKey
goto :mainMenu

:: ============================================================================
:: FUNCTION: Apply Steam Tweaks
:: ============================================================================
:applySteamTweaks
setlocal EnableDelayedExpansion
cls
echo ===============================================================================
echo                       STEAM PERFORMANCE TWEAKS
echo ===============================================================================
echo.
echo This tool will apply various performance tweaks to Steam:
echo.
echo Available options:
echo.
echo  [1] Apply Steam Registry Tweaks (Disable unnecessary features)
echo  [2] Install NoSteamWebHelper (Disable Steam CEF/Chromium)
echo  [3] Apply Steam Launch Options (Single Account)
echo  [4] Apply Steam Launch Options (Multi Account)
echo  [5] Return to Main Menu
echo.
echo ===============================================================================
set /p "tweak_choice=Select an option (1-5): "

:: Input validation
if not defined tweak_choice (
    call :showError "No option selected. Please try again."
    goto :applySteamTweaks
)

:: Remove any spaces and validate input
set "tweak_choice=!tweak_choice: =!"
if "!tweak_choice!"=="1" goto :applySteamRegistryTweaks
if "!tweak_choice!"=="2" goto :installNoSteamWebHelper
if "!tweak_choice!"=="3" goto :applySteamLaunchSingle
if "!tweak_choice!"=="4" goto :applySteamLaunchMulti
if "!tweak_choice!"=="5" (
    endlocal
    goto :mainMenu
)

call :showError "Invalid choice '!tweak_choice!'. Please select a number between 1-5."
goto :applySteamTweaks

:: ============================================================================
:: FUNCTION: Apply Steam Registry Tweaks
:: ============================================================================
:applySteamRegistryTweaks
setlocal EnableDelayedExpansion
cls
echo ===============================================================================
echo                    APPLYING STEAM REGISTRY TWEAKS
echo ===============================================================================
echo.
echo This will apply registry tweaks to optimize Steam performance:
echo.
echo Benefits:
echo  • Disables unnecessary visual effects and animations
echo  • Reduces CPU usage from Steam browser components
echo  • Prevents Steam from starting with Windows
echo  • Sets lower process priority for Steam components
echo.
echo [WARNING] This will modify Windows Registry settings for Steam.
echo.
set /p "confirm=Do you want to continue? (y/n): "
if /i not "%confirm%"=="y" goto :mainMenu

echo.
echo Downloading Steam_Performance.reg from GitHub...
call :downloadFile "https://raw.githubusercontent.com/er1nz/CS2-UTILITY/refs/heads/main/Steam_Performance.reg" "Steam_Performance.reg" "%TEMP_DIR%"
if errorlevel 1 goto :applySteamTweaks

echo.
echo [SUCCESS] Registry file downloaded successfully.
echo Opening registry file for import...

:: Run the registry file
start "" "%TEMP_DIR%\Steam_Performance.reg"

echo.
echo [INSTRUCTIONS]
echo 1. A Registry Editor prompt will appear
echo 2. Click "Yes" to apply the registry changes
echo 3. Click "OK" when complete
echo.
echo [NOTE] You may need to restart Steam for all changes to take effect.
echo.
call :pressAnyKey
endlocal
goto :applySteamTweaks

:: ============================================================================
:: FUNCTION: Apply Steam Launch Options (Single Account)
:: ============================================================================
:applySteamLaunchSingle
setlocal EnableDelayedExpansion
cls
echo ===============================================================================
echo                STEAM LAUNCH OPTIONS (SINGLE ACCOUNT)
echo ===============================================================================
echo.
echo This will create a shortcut with optimized Steam launch options for single account use:
echo.
echo Launch options:
echo -dev -console -nofriendsui -no-dwrite -nointro -nobigpicture -nofasthtml 
echo -nocrashmonitor -noshaders -no-shared-textures -disablehighdpi -cef-single-process 
echo -cef-in-process-gpu -single_core -cef-disable-d3d11 -cef-disable-sandbox 
echo -disable-winh264 -no-cef-sandbox -vrdisable -cef-disable-breakpad 
echo +open steam://open/minigameslist
echo.
echo [INSTRUCTIONS]
echo 1. Copy the steam_run.bat file to your Steam directory
echo 2. Create a shortcut to this batch file
echo 3. Use this shortcut instead of the regular Steam shortcut
echo.
set /p "confirm=Do you want to continue? (y/n): "
if /i not "%confirm%"=="y" goto :mainMenu

:: Find Steam installation directory
echo.
echo Finding Steam installation directory...
set "STEAM_PATH="
call :getSteamPathFromRegistry
if not defined STEAM_PATH (
    echo [WARNING] Could not detect Steam installation.
    echo.
    call :getManualSteamPath
    if errorlevel 1 goto :applySteamTweaks
)

echo.
echo [INFO] Steam path: !STEAM_PATH!
echo.
echo Copying steam_run.bat to Steam directory...

:: Copy the batch file content to a new file
echo start steam.exe -dev -console -nofriendsui -no-dwrite -nointro -nobigpicture -nofasthtml -nocrashmonitor -noshaders -no-shared-textures -disablehighdpi -cef-single-process -cef-in-process-gpu -single_core -cef-disable-d3d11 -cef-disable-sandbox -disable-winh264 -no-cef-sandbox -vrdisable -cef-disable-breakpad +open steam://open/minigameslist > "%TEMP_DIR%\steam_run.bat"

:: Copy the file to Steam directory
copy /Y "%TEMP_DIR%\steam_run.bat" "!STEAM_PATH!\steam_run.bat" >nul 2>&1
if errorlevel 1 (
    call :showError "Failed to copy file to Steam directory. Check permissions."
    goto :applySteamTweaks
)

echo.
echo [SUCCESS] Steam launch options batch file created at:
echo !STEAM_PATH!\steam_run.bat
echo.
echo [INSTRUCTIONS]
echo 1. Create a shortcut to this batch file on your desktop
echo 2. Use this shortcut instead of the regular Steam shortcut
echo 3. This will launch Steam with optimized settings
echo.
call :pressAnyKey
endlocal
goto :applySteamTweaks

:: ============================================================================
:: FUNCTION: Apply Steam Launch Options (Multi Account)
:: ============================================================================
:applySteamLaunchMulti
setlocal EnableDelayedExpansion
cls
echo ===============================================================================
echo                STEAM LAUNCH OPTIONS (MULTI ACCOUNT)
echo ===============================================================================
echo.
echo This will create a shortcut with optimized Steam launch options for multi-account use:
echo.
echo Launch options:
echo -cef-single-process -cef-disable-gpu -no-dwrite -skipinitialbootstrap 
echo -quicklogin -oldtraymenu -silent -vgui +open steam://open/minigameslist exit
echo.
echo [INSTRUCTIONS]
echo 1. Copy the steam_run.bat file to your Steam directory
echo 2. Create a shortcut to this batch file
echo 3. Use this shortcut instead of the regular Steam shortcut
echo.
set /p "confirm=Do you want to continue? (y/n): "
if /i not "%confirm%"=="y" goto :mainMenu

:: Find Steam installation directory
echo.
echo Finding Steam installation directory...
set "STEAM_PATH="
call :getSteamPathFromRegistry
if not defined STEAM_PATH (
    echo [WARNING] Could not detect Steam installation.
    echo.
    call :getManualSteamPath
    if errorlevel 1 goto :applySteamTweaks
)

echo.
echo [INFO] Steam path: !STEAM_PATH!
echo.
echo Copying steam_run.bat to Steam directory...

:: Copy the batch file content to a new file
echo steam.exe -cef-single-process -cef-disable-gpu -no-dwrite -skipinitialbootstrap -quicklogin -oldtraymenu -silent -vgui +open steam://open/minigameslist exit > "%TEMP_DIR%\steam_run_multi.bat"

:: Copy the file to Steam directory
copy /Y "%TEMP_DIR%\steam_run_multi.bat" "!STEAM_PATH!\steam_run_multi.bat" >nul 2>&1
if errorlevel 1 (
    call :showError "Failed to copy file to Steam directory. Check permissions."
    goto :applySteamTweaks
)

echo.
echo [SUCCESS] Steam multi-account launch options batch file created at:
echo !STEAM_PATH!\steam_run_multi.bat
echo.
echo [INSTRUCTIONS]
echo 1. Create a shortcut to this batch file on your desktop
echo 2. Use this shortcut instead of the regular Steam shortcut
echo 3. This will launch Steam with optimized settings for multi-account use
echo.
call :pressAnyKey
endlocal
goto :applySteamTweaks

:: ============================================================================
:: FUNCTION: Get Manual Steam Path
:: ============================================================================
:getManualSteamPath
echo.
echo Enter the full path to your Steam directory:
echo.
echo Example: C:\Program Files (x86)\Steam
echo.
set /p "STEAM_PATH=Enter path: "

if not defined STEAM_PATH (
    echo [ERROR] No path entered. Operation cancelled.
    exit /b 1
)

:: Remove quotes if present
set "STEAM_PATH=!STEAM_PATH:"=!"

:: Validate Steam path
if not exist "!STEAM_PATH!" (
    echo.
    echo [WARNING] Directory does not exist: !STEAM_PATH!
    set /p "create=Create directory? (y/n): "
    if /i "!create!"=="y" (
        echo Creating directory: !STEAM_PATH!
        mkdir "!STEAM_PATH!" 2>nul
        if errorlevel 1 (
            echo [ERROR] Failed to create directory: !STEAM_PATH!
            echo Please check permissions and try again.
            exit /b 1
        )
        echo [SUCCESS] Directory created: !STEAM_PATH!
    ) else (
        echo Operation cancelled.
        exit /b 1
    )
)

echo [SUCCESS] Steam path set to: !STEAM_PATH!
exit /b 0

:: ============================================================================
:: FUNCTION: Install NoSteamWebHelper
:: ============================================================================
:installNoSteamWebHelper
setlocal EnableDelayedExpansion
cls
echo ===============================================================================
echo                       INSTALL NOSTEAMWEBHELPER
echo ===============================================================================
echo.
echo This tool will install NoSteamWebHelper (by Aetopia) which disables Steam's
echo CEF/Chromium Embedded Framework while games are running.
echo.
echo Benefits:
echo  • Reduces memory usage while gaming
echo  • Decreases CPU usage from unnecessary browser components
echo  • Steam UI still works normally when not gaming
echo.
echo [INSTRUCTIONS]
echo 1. Start Steam
echo 2. NoSteamWebHelper will automatically disable Steam's CEF when games are running
echo 3. You'll see a tray icon that allows you to manually toggle the CEF
echo.
echo [TIP] For best results, add -silent to your Steam shortcut to prevent
echo      the CEF from automatically showing when restored.
echo.
echo [INFO] The tool will download and install umpdc.dll to your Steam directory.
echo.
set /p "confirm=Do you want to continue? (y/n): "
if /i not "%confirm%"=="y" goto :mainMenu


:: Find Steam installation directory
echo.
echo ===============================================================================
echo                       STEAM INSTALLATION DETECTION
echo ===============================================================================
echo.
echo Choose how to specify your Steam installation directory:
echo.
echo   [1] Auto-detect Steam installation (Recommended)
echo   [2] Manually enter Steam path
echo.
set /p "steam_choice=Select option (1-2): "

if "!steam_choice!"=="1" (
    echo.
    echo Attempting auto-detection...
    echo Checking Windows Registry for Steam installation...

    :: Get Steam path
    echo Finding Steam path...
    set "STEAM_PATH="

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
            :: Replace forward slashes with backslashes if needed
            set "STEAM_PATH=!STEAM_PATH:/=\!"
        )
    )

    if not defined STEAM_PATH (
        echo [WARNING] Auto-detection failed. Falling back to manual entry.
        call :getManualSteamPath
        if errorlevel 1 goto :applySteamTweaks
    )
) else if "!steam_choice!"=="2" (
    echo.
    echo Manual path entry selected.
    call :getManualSteamPath
    if errorlevel 1 goto :applySteamTweaks
) else (
    echo [WARNING] Invalid selection. Defaulting to auto-detection.
    echo.
    echo Attempting auto-detection...
    
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
            :: Replace forward slashes with backslashes if needed
            set "STEAM_PATH=!STEAM_PATH:/=\!"
        )
    )

    if not defined STEAM_PATH (
        echo [WARNING] Auto-detection failed. Falling back to manual entry.
        call :getManualSteamPath
        if errorlevel 1 goto :applySteamTweaks
    )
)

echo [SUCCESS] Steam path detected: !STEAM_PATH!
goto :continueNoSteamWebHelper

:continueNoSteamWebHelper
:: Check if Steam is running
tasklist /FI "IMAGENAME eq steam.exe" 2>nul | find /I /N "steam.exe" >nul
if errorlevel 1 goto :startDownloadNoSteamWebHelper

:: Steam is running, so handle it
echo.
echo [WARNING] Steam is currently running.
echo NoSteamWebHelper requires Steam to be closed during installation.
echo.
set /p "close_steam=Would you like to close Steam now? (y/n): "
if /i "!close_steam!"=="y" (
    echo Closing Steam...
    taskkill /F /IM steam.exe >nul 2>&1
    timeout /t 3 >nul
) else (
    echo Please close Steam manually before continuing.
    echo.
    set /p "continue=Press Enter when Steam is closed to continue..."
)

:startDownloadNoSteamWebHelper
:: Download NoSteamWebHelper (umpdc.dll)
echo.
echo ===============================================================================
echo                       DOWNLOADING NOSTEAMWEBHELPER
echo ===============================================================================
echo.
echo Downloading umpdc.dll from Aetopia's GitHub repository...

:: Download file directly with curl
curl -L -o "%TEMP_DIR%\umpdc.dll" "https://github.com/Aetopia/NoSteamWebHelper/releases/latest/download/umpdc.dll"
if errorlevel 1 (
    echo [ERROR] Download failed. Attempting alternate download method...
    
    :: Try using PowerShell as fallback
    powershell -Command "try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/Aetopia/NoSteamWebHelper/releases/latest/download/umpdc.dll' -OutFile '%TEMP_DIR%\umpdc.dll' -UseBasicParsing } catch { exit 1 }"
    
    if errorlevel 1 (
        :: Try using bitsadmin as last resort
        bitsadmin /transfer "NoSteamWebHelperDownload" "https://github.com/Aetopia/NoSteamWebHelper/releases/latest/download/umpdc.dll" "%TEMP_DIR%\umpdc.dll" >nul
        
        if errorlevel 1 (
            call :showError "All download methods failed. Please check your internet connection and try again."
            goto :applySteamTweaks
        )
    )
)

echo.
echo Download successful!
echo Copying file to Steam directory: !STEAM_PATH!\umpdc.dll

:: Copy file to Steam directory with error handling
copy /Y "%TEMP_DIR%\umpdc.dll" "!STEAM_PATH!\umpdc.dll"
if errorlevel 1 (
    echo [WARNING] Failed to copy file. Attempting to run with elevated privileges...
    
    :: Create a temporary elevated script
    echo @echo off > "%TEMP_DIR%\elevate_copy.bat"
    echo copy /Y "%TEMP_DIR%\umpdc.dll" "!STEAM_PATH!\umpdc.dll" >> "%TEMP_DIR%\elevate_copy.bat"
    echo exit >> "%TEMP_DIR%\elevate_copy.bat"
    
    :: Run with elevated privileges
    powershell -Command "Start-Process cmd -ArgumentList '/c %TEMP_DIR%\elevate_copy.bat' -Verb RunAs"
    timeout /t 3 >nul
    
    :: Check if file was copied
    if not exist "!STEAM_PATH!\umpdc.dll" (
        call :showError "Failed to copy file to Steam directory. Please try running the script as administrator."
        goto :applySteamTweaks
    )
)

echo [SUCCESS] NoSteamWebHelper has been installed to: !STEAM_PATH!\umpdc.dll
echo.
echo [INSTRUCTIONS]
echo 1. Start Steam
echo 2. NoSteamWebHelper will automatically disable Steam's CEF when games are running
echo 3. You'll see a tray icon that allows you to manually toggle the CEF

call :pressAnyKey
endlocal
goto :applySteamTweaks

:: ============================================================================
:: FUNCTION: Apply Network Fixes
:: ============================================================================
:NetworkTweaks
:Network
cls
echo %z%Network Optimizations can cause better/worse results depending on the user, results may vary.%q%
echo.
echo %z%Would you like to Create a Restore Point before Optimizing your Network?%q%
echo.
echo %i%Yes = 1%q%
echo.
echo %i%No = 2%q%
echo.
echo %i%Go back to Menu = 3%q%
echo.
set choice=
set /p choice=
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' goto RP2
if '%choice%'=='2' goto NetworkTweaks
if '%choice%'=='3' goto :mainMenu

:RP2
:: Creating Restore Point
echo Creating Restore Point
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /t REG_DWORD /d "0" /f >> APB_Log.txt
powershell -ExecutionPolicy Bypass -Command "Checkpoint-Computer -Description 'Ancels Performance Batch' -RestorePointType 'MODIFY_SETTINGS'" >> APB_Log.txt

:NetworkTweaks
cls

:: Reset Internet
echo Resetting Internet
ipconfig /release
ipconfig /renew
ipconfig /flushdns
netsh int ip reset
netsh int ipv4 reset
netsh int ipv6 reset
netsh int tcp reset
netsh winsock reset
netsh advfirewall reset
netsh branchcache reset
netsh http flush logbuffer
timeout /t 3 /nobreak > NUL

cls
set z=[7m
set i=[1m
set q=[0m
echo %z%Are you on Windows 10 or Windows 11?%q%
echo.
echo %i%Windows 10 = 1%q%
echo.
echo %i%Windows 11 = 2%q%
echo.
set choice=
set /p choice=
if not '%choice%'=='' set choice=%choice:~0,1%
if '%choice%'=='1' goto Windows10Network
if '%choice%'=='2' goto Windows11Network

:Windows10Network
:: Enable CTCP
echo Enabling CTCP
netsh int tcp set supplemental Internet congestionprovider=ctcp
timeout /t 1 /nobreak > NUL

goto NetworkContinued

:Windows11Network
:: Enable BBR2
echo Enabling BBR2
netsh int tcp set supplemental Template=Compat CongestionProvider=bbr2
netsh int tcp set supplemental Template=Internet CongestionProvider=bbr2
netsh int tcp set supplemental Template=Datacenter CongestionProvider=bbr2
netsh int tcp set supplemental Template=InternetCustom CongestionProvider=bbr2
netsh int tcp set supplemental Template=DatacenterCustom CongestionProvider=bbr2
timeout /t 1 /nobreak > NUL

goto NetworkContinued

:NetworkContinued
:: Enable MSI Mode for Network Adapter
echo Enabling MSI Mode for Network Adapter
for /f %%l in ('wmic path win32_NetworkAdapter get PNPDeviceID ^| find "PCI\VEN_"') do (
reg add "HKEY_LOCAL_MACHINE\SYSTEM\SYSTEM\CurrentControlSet\Enum\%%l\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" /v "MSISupported" /t REG_DWORD /d "1" /f >> APB_Log.txt
reg add "HKEY_LOCAL_MACHINE\SYSTEM\SYSTEM\CurrentControlSet\Enum\%%l\Device Parameters\Interrupt Management\Affinity Policy" /v "DevicePriority" /t REG_DWORD /d "0" /f >> APB_Log.txt
)
timeout /t 1 /nobreak > NUL

:: Disable Network Throttling
echo Disabling Network Throttling
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d "4294967295" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Set Network Autotuning to Disabled
echo Setting Network AutoTuning to Disabled
netsh int tcp set global autotuninglevel=disabled
timeout /t 1 /nobreak > NUL

:: Disable ECN
echo Disabling Explicit Congestion Notification
netsh int tcp set global ecncapability=disabled
timeout /t 1 /nobreak > NUL

:: Enable DCA
echo Enabling Direct Cache Access
netsh int tcp set global dca=enabled
timeout /t 1 /nobreak > NUL

:: Enable NetDMA
echo Enabling Network Direct Memory Access
netsh int tcp set global netdma=enabled
timeout /t 1 /nobreak > NUL

:: Disable RSC
echo Disabling Recieve Side Coalescing
netsh int tcp set global rsc=disabled
timeout /t 1 /nobreak > NUL

:: Enable RSS
echo Enabling Recieve Side Scaling
netsh int tcp set global rss=enabled
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndis\Parameters" /v "RssBaseCpu" /t REG_DWORD /d "1" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Disable TCP Timestamps
echo Disabling TCP Timestamps
netsh int tcp set global timestamps=disabled
timeout /t 1 /nobreak > NUL

:: Set Initial RTO to 2ms
echo Setting Initial Retransmission Timer
netsh int tcp set global initialRto=2000
timeout /t 1 /nobreak > NUL

:: Set MTU Size to 1500
echo Setting MTU Size
netsh interface ipv4 set subinterface “Ethernet” mtu=1500 store=persistent
timeout /t 1 /nobreak > NUL

:: Disable NonSackRTTresiliency
echo Disabling Non Sack RTT Resiliency
netsh int tcp set global nonsackrttresiliency=disabled
timeout /t 1 /nobreak > NUL

:: Set Max Syn Retransmissions to 2
echo Setting Max Syn Retransmissions
netsh int tcp set global maxsynretransmissions=2
timeout /t 1 /nobreak > NUL

:: Disable MPP
echo Disabling Memory Pressure Protection
netsh int tcp set security mpp=disabled
timeout /t 1 /nobreak > NUL

:: Disable Security Profiles
echo Disabling Security Profiles
netsh int tcp set security profiles=disabled
timeout /t 1 /nobreak > NUL

:: Disable Heuristics
echo Disabling Windows Scaling Heuristics
netsh int tcp set heuristics disabled
timeout /t 1 /nobreak > NUL

:: Increase ARP Cache Size to 4096
echo Increasing ARP Cache Size
netsh int ip set global neighborcachelimit=4096
timeout /t 1 /nobreak > NUL

:: Enable CTCP
echo Enabling CTCP
netsh int tcp set supplemental Internet congestionprovider=ctcp
timeout /t 1 /nobreak > NUL

:: Disable Task Offloading
echo Disabling Task Offloading
netsh int ip set global taskoffload=disabled
timeout /t 1 /nobreak > NUL

:: Disable IPv6
echo Disabling IPv6
netsh int ipv6 set state disabled
timeout /t 1 /nobreak > NUL

:: Disable ISATAP
echo Disabling ISATAP
netsh int isatap set state disabled
timeout /t 1 /nobreak > NUL

:: Disable Teredo
echo Disabling Teredo
netsh int teredo set state disabled
timeout /t 1 /nobreak > NUL

:: Set TTL to 64
echo Configuring Time to Live
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "DefaultTTL" /t REG_DWORD /d "64" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Enable TCP Window Scaling
echo Enabling TCP Window Scaling
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "Tcp1323Opts" /t REG_DWORD /d "1" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Set TcpMaxDupAcks
echo Setting TcpMaxDupAcks to 2
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpMaxDupAcks" /t REG_DWORD /d "2" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Disable SackOpts
echo Disabling TCP Selective ACKs
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "SackOpts" /t REG_DWORD /d "0" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Increase Maximum Port Number
echo Increasing Maximum Port Number
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "MaxUserPort" /t REG_DWORD /d "65534" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Decrease Time to Wait in "TIME_WAIT" State
echo Decreasing Timed Wait Delay
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpTimedWaitDelay" /t REG_DWORD /d "30" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Set Network Priorities
echo Setting Network Priorities
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "LocalPriority" /t REG_DWORD /d "4" /f >> APB_Log.txt
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "HostsPriority" /t REG_DWORD /d "5" /f >> APB_Log.txt
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "DnsPriority" /t REG_DWORD /d "6" /f >> APB_Log.txt
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "NetbtPriority" /t REG_DWORD /d "7" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Adjust Sock Address Size
echo Configuring Sock Address Size
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Winsock" /v "MinSockAddrLength" /t REG_DWORD /d "16" /f >> APB_Log.txt
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Winsock" /v "MaxSockAddrLength" /t REG_DWORD /d "16" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Disable Nagle's Algorithm
echo Disabling Nagle's Algorithm
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v "TcpAckFrequency" /t REG_DWORD /d "1" /f >> APB_Log.txt
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v "TCPNoDelay" /t REG_DWORD /d "1" /f >> APB_Log.txt
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v "TcpDelAckTicks" /t REG_DWORD /d "0" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Disable Delivery Optimization
echo Disabling Delivery Optimization
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v "DODownloadMode" /t REG_DWORD /d "0" /f >> APB_Log.txt
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v "DownloadMode" /t REG_DWORD /d "0" /f >> APB_Log.txt
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings" /v "DownloadMode" /t REG_DWORD /d "0" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Disable Auto Disconnect for Idle Connections
echo Disabling Auto Disconnect
reg add "HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters" /v "autodisconnect" /t REG_DWORD /d "4294967295" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Limit Number of SMB Sessions
echo Limiting SMB Sessions
reg add "HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters" /v "Size" /t REG_DWORD /d "3" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Disable Oplocks
echo Disabling Oplocks
reg add "HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters" /v "EnableOplocks" /t REG_DWORD /d "0" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Set IRP Stack Size
echo Setting IRP Stack Size
reg add "HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters" /v "IRPStackSize" /t REG_DWORD /d "20" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Disable Sharing Violations
echo Disabling Sharing Violations
reg add "HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters" /v "SharingViolationDelay" /t REG_DWORD /d "0" /f >> APB_Log.txt
reg add "HKLM\SYSTEM\CurrentControlSet\services\LanmanServer\Parameters" /v "SharingViolationRetries" /t REG_DWORD /d "0" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Get the Sub ID of the Network Adapter
for /f %%n in ('Reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}" /v "*SpeedDuplex" /s ^| findstr  "HKEY"') do (

:: Disable NIC Power Savings
echo Disabling NIC Power Savings
reg add "%%n" /v "AutoPowerSaveModeEnabled" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "AutoDisableGigabit" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "AdvancedEEE" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "DisableDelayedPowerUp" /t REG_SZ /d "2" /f >> APB_Log.txt
reg add "%%n" /v "*EEE" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "EEE" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "EnablePME" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "EEELinkAdvertisement" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "EnableGreenEthernet" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "EnableSavePowerNow" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "EnablePowerManagement" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "EnableDynamicPowerGating" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "EnableConnectedPowerGating" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "EnableWakeOnLan" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "GigaLite" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "NicAutoPowerSaver" /t REG_SZ /d "2" /f >> APB_Log.txt
reg add "%%n" /v "PowerDownPll" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "PowerSavingMode" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "ReduceSpeedOnPowerDown" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "SmartPowerDownEnable" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "S5NicKeepOverrideMacAddrV2" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "S5WakeOnLan" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "ULPMode" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "WakeOnDisconnect" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "*WakeOnMagicPacket" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "*WakeOnPattern" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "WakeOnLink" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "WolShutdownLinkSpeed" /t REG_SZ /d "2" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Disable Jumbo Frame
echo Disabling Jumbo Frame
reg add "%%n" /v "JumboPacket" /t REG_SZ /d "1514" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Configure Receive/Transmit Buffers
echo Configuring Buffer Sizes
reg add "%%n" /v "ReceiveBuffers" /t REG_SZ /d "1024" /f >> APB_Log.txt
reg add "%%n" /v "TransmitBuffers" /t REG_SZ /d "4096" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Configure Offloads
echo Configuring Offloads
reg add "%%n" /v "IPChecksumOffloadIPv4" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "LsoV1IPv4" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "LsoV2IPv4" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "LsoV2IPv6" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "PMARPOffload" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "PMNSOffload" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "TCPChecksumOffloadIPv4" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "TCPChecksumOffloadIPv6" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "UDPChecksumOffloadIPv6" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "UDPChecksumOffloadIPv4" /t REG_SZ /d "0" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Enable RSS in NIC
echo Enabling RSS in NIC
reg add "%%n" /v "RSS" /t REG_SZ /d "1" /f >> APB_Log.txt
reg add "%%n" /v "*NumRssQueues" /t REG_SZ /d "2" /f >> APB_Log.txt
reg add "%%n" /v "RSSProfile" /t REG_SZ /d "3" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Disable Flow Control
echo Disabling Flow Control
reg add "%%n" /v "*FlowControl" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "FlowControlCap" /t REG_SZ /d "0" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Remove Interrupt Delays
echo Removing Interrupt Delays
reg add "%%n" /v "TxIntDelay" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "TxAbsIntDelay" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "RxIntDelay" /t REG_SZ /d "0" /f >> APB_Log.txt
reg add "%%n" /v "RxAbsIntDelay" /t REG_SZ /d "0" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Remove Adapter Notification
echo Removing Adapter Notification Sending
reg add "%%n" /v "FatChannelIntolerant" /t REG_SZ /d "0" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL

:: Disable Interrupt Moderation
echo Disabling Interrupt Moderation
reg add "%%n" /v "*InterruptModeration" /t REG_SZ /d "0" /f >> APB_Log.txt
timeout /t 1 /nobreak > NUL
)

:: Enable WeakHost Send and Recieve (melodytheneko)
echo Enabling WH Send and Recieve
powershell "Get-NetAdapter -IncludeHidden | Set-NetIPInterface -WeakHostSend Enabled -WeakHostReceive Enabled -ErrorAction SilentlyContinue"
timeout /t 1 /nobreak > NUL

goto CompletedNetworkOptimizations

:CompletedNetworkOptimizations
cls
echo Completed Network Optimizations
call :pressAnyKey
goto :mainMenu

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
echo -exec autoexec -noaafonts -no-browser -high -nojoy -limitvsconst -softparticlesdefaultoff +fps_max 0 +engine_low_latency_sleep_after_client_tick true +cl_clock_recvmargin_enable 0 +cl_cq_min_queue 1 -language english
echo.
echo Parameter breakdown:
echo   • Launches autoexec.cfg file (-exec autoexec)
echo   • Disables anti-aliased fonts and browser for performance (-noaafonts -no-browser)
echo   • Sets high process priority and disables joystick support (-high -nojoy)
echo   • Optimizes graphics and engine settings for smoother gameplay (-limitvsconst -softparticlesdefaultoff)
echo   • Removes FPS cap (+fps_max 0)
echo   • Enables low latency engine settings (+engine_low_latency_sleep_after_client_tick true)
echo   • Disables clock receive margin and minimizes command queue (+cl_clock_recvmargin_enable 0 +cl_cq_min_queue 1)
echo   • Forces game language to English (-language english)
echo.
echo [INFO] Copying parameters to clipboard...
echo -exec autoexec -noaafonts -no-browser -high -nojoy -limitvsconst -softparticlesdefaultoff +fps_max 0 +engine_low_latency_sleep_after_client_tick true +cl_clock_recvmargin_enable 0 +cl_cq_min_queue 1 -language english | clip
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

