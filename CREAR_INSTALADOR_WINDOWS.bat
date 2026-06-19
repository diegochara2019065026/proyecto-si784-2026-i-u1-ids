@echo off
setlocal

cd /d "%~dp0"

set "APP_EXE=dist\TrafficWatchIDS\TrafficWatchIDS.exe"
set "INNO_ISCC="

echo ==========================================
echo  Creando instalador TrafficWatch IDS
echo ==========================================
echo.

if not exist "%APP_EXE%" (
    echo [INFO] No se encontro %APP_EXE%.
    echo [INFO] Creando ejecutable primero...
    call CREAR_EJECUTABLE_WINDOWS.bat
    if errorlevel 1 (
        echo [ERROR] No se pudo crear el ejecutable.
        pause
        exit /b 1
    )
)

where iscc >nul 2>nul
if not errorlevel 1 (
    for /f "delims=" %%I in ('where iscc') do (
        set "INNO_ISCC=%%I"
        goto :found_iscc
    )
)

if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" (
    set "INNO_ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
    goto :found_iscc
)

if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" (
    set "INNO_ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"
    goto :found_iscc
)

if exist "%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe" (
    set "INNO_ISCC=%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe"
    goto :found_iscc
)

echo [AVISO] Inno Setup no esta instalado.
where winget >nul 2>nul
if errorlevel 1 (
    echo [ERROR] WinGet no esta disponible.
    echo Instala Inno Setup manualmente desde:
    echo https://jrsoftware.org/isdl.php
    pause
    exit /b 1
)

set /p INSTALL_INNO="Quieres instalar Inno Setup automaticamente con winget? (S/N): "
if /i not "%INSTALL_INNO%"=="S" (
    echo Instalacion cancelada.
    pause
    exit /b 1
)

winget install --id JRSoftware.InnoSetup --exact --accept-package-agreements --accept-source-agreements
if errorlevel 1 (
    echo [ERROR] No se pudo instalar Inno Setup.
    pause
    exit /b 1
)

if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" (
    set "INNO_ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
) else if exist "%ProgramFiles%\Inno Setup 6\ISCC.exe" (
    set "INNO_ISCC=%ProgramFiles%\Inno Setup 6\ISCC.exe"
) else if exist "%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe" (
    set "INNO_ISCC=%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe"
) else (
    echo [ERROR] Inno Setup se instalo, pero no se encontro ISCC.exe.
    pause
    exit /b 1
)

:found_iscc
echo [INFO] Usando Inno Setup:
echo %INNO_ISCC%
echo.

if not exist "installer_output" mkdir "installer_output"

"%INNO_ISCC%" "installer\TrafficWatchIDS.iss"
if errorlevel 1 (
    echo [ERROR] No se pudo crear el instalador.
    pause
    exit /b 1
)

echo.
echo Instalador creado:
echo %CD%\installer_output\TrafficWatchIDS_Setup.exe
echo.
pause
