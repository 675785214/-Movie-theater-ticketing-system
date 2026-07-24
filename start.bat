@echo off
setlocal enabledelayedexpansion
title Cinema Manager
cd /d "%~dp0"

echo ============================================
echo   Movie Theater Ticketing System Launcher
echo ============================================
echo.

REM ---- Load .env ----
if exist .env (
    for /f "usebackq tokens=1,2 delims==" %%a in (".env") do set %%a=%%b
) else (
    echo [SETUP] First run: creating .env file...
    set /p CINEMA_DB_PASSWORD="Enter MySQL password: "
    echo CINEMA_DB_PASSWORD=!CINEMA_DB_PASSWORD! > .env
    echo   .env created.
)

REM ---- Check Prerequisites ----
echo [1/5] Checking environment...
where java  >nul 2>&1 || (echo [ERROR] Java not found -- install JDK 17+ & pause & exit /b 1)
where node  >nul 2>&1 || (echo [ERROR] Node.js not found -- install Node.js & pause & exit /b 1)
if not defined JAVA_HOME (
    echo [WARN] JAVA_HOME not set, trying to auto-detect...
    for /f "tokens=*" %%i in ('where java') do set JAVA_HOME=%%~dpi..
    if defined JAVA_HOME set JAVA_HOME=!JAVA_HOME!
    echo   JAVA_HOME=!JAVA_HOME!
)
echo   Java: !JAVA_HOME!
echo   OK

REM ---- Check MySQL ----
echo.
echo [2/5] Checking MySQL...
mysql -u root -p!CINEMA_DB_PASSWORD! -e "SELECT 1" >nul 2>&1
if !errorlevel! equ 0 (echo   MySQL connected) else (echo   [WARN] MySQL unavailable, continue anyway...)

REM ---- Build and Start Backend ----
echo.
echo [3/5] Building and starting backend (port 9231)...
cd cinema-backend
echo   Compiling...
call mvnw.cmd clean compile -DskipTests
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] Build failed! Check the error above.
    cd ..
    pause
    exit /b 1
)
echo   Starting backend...
start /B mvnw.cmd spring-boot:run -q > ..\log-backend.txt 2>&1
cd ..

REM ---- Start User Frontend ----
echo.
echo [4/5] Starting user frontend (port 9232)...
cd user
start /B npm run serve > ..\log-user.txt 2>&1
cd ..

REM ---- Start Admin Frontend ----
echo.
echo [5/5] Starting admin frontend (port 9233)...
cd admin
start /B npm run serve > ..\log-admin.txt 2>&1
cd ..

REM ---- Wait for backend ----
echo.
echo Waiting for backend...
:wait_backend
timeout /t 3 /nobreak >nul
curl -s http://localhost:9231/captcha >nul 2>&1
if !errorlevel! neq 0 goto wait_backend
echo   Backend is ready!

echo.
echo ============================================
echo   All services started!
echo ============================================
echo.
echo   Backend API    : http://localhost:9231
echo   User Frontend  : http://localhost:9232
echo   Admin Frontend : http://localhost:9233
echo.
echo   Logs: log-backend.txt / log-user.txt / log-admin.txt
echo.
echo   Press any key to STOP all services...
pause >nul
echo.
echo Shutting down...

for %%p in (9231 9232 9233) do (
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr :%%p.*LISTENING') do (
        taskkill /F /PID %%a >nul 2>&1
    )
)

echo All services stopped.
echo.
pause
