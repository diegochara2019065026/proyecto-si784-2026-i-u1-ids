@echo off
cd /d "%~dp0"
set "PYTHON_CMD=python"

echo.
echo Iniciando IDS PRO Dashboard
echo Ubicacion del proyecto:
echo %CD%
echo.
echo Ejecutando:
echo   python run_dashboard.py
echo.
echo Dashboard:
echo   http://127.0.0.1:5000
echo.

if exist ".venv\Scripts\python.exe" (
    set "PYTHON_CMD=.venv\Scripts\python.exe"
) else (
    where py >nul 2>nul
    if not errorlevel 1 (
        py -3 --version >nul 2>nul
        if not errorlevel 1 set "PYTHON_CMD=py -3"
    )
)

if "%PYTHON_CMD%"=="python" (
    python --version >nul 2>nul
    if errorlevel 1 (
        echo [ERROR] Python no esta instalado correctamente.
        echo Windows esta abriendo el alias de Microsoft Store en vez de Python real.
        echo.
        echo Solucion:
        echo   1. Instala Python desde https://www.python.org/downloads/
        echo   2. Marca "Add Python to PATH"
        echo   3. O desactiva el alias en:
        echo      Configuracion ^> Aplicaciones ^> Configuracion avanzada de aplicaciones ^> Alias de ejecucion de aplicaciones
        echo      y apaga python.exe / python3.exe
        echo.
        pause
        exit /b 1
    )
)

%PYTHON_CMD% --version >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Python no esta instalado o no esta en PATH.
    echo Instala Python desde https://www.python.org/downloads/
    echo Marca la opcion "Add Python to PATH" durante la instalacion.
    echo.
    pause
    exit /b 1
)

echo Verificando dependencias...
%PYTHON_CMD% -m pip install -r requirements.txt
if errorlevel 1 (
    echo.
    echo [ERROR] No se pudieron instalar las dependencias.
    echo Revisa tu conexion a internet o ejecuta manualmente:
    echo   %PYTHON_CMD% -m pip install -r requirements.txt
    echo.
    pause
    exit /b 1
)

%PYTHON_CMD% run_dashboard.py

echo.
echo El dashboard se detuvo o no pudo iniciar.
echo La ventana queda abierta para revisar mensajes.
echo.

cmd /k
