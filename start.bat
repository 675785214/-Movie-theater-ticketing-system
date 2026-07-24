@echo off
title Cinema Manager
cd /d "%~dp0"

echo ============================================
echo   Movie Theater Ticketing System Launcher
echo ============================================
echo.

REM ---- Check Prerequisites ----
echo [1/5] Checking environment...
where java >nul 2>&1 || (echo [ERROR] Java not found & pause & exit /b 1)
where mvn  >nul 2>&1 || (echo [ERROR] Maven not found & pause & exit /b 1)
where node >nul 2>&1 || (echo [ERROR] Node.js not found & pause & exit /b 1)
where npm  >nul 2>&1 || (echo [ERROR] npm not found & pause & exit /b 1)
echo   OK

REM ---- Check MySQL ----
echo.
echo [2/5] Checking MySQL...
mysql -u root -p675785214 -e "SELECT 1" >nul 2>&1
if %errorlevel% equ 0 (echo   MySQL connected) else (echo   [WARN] MySQL unavailable, continue anyway...)

REM ---- Build & Start Backend ----
echo.
echo [3/5] Building and starting backend (port 9231)...
cd cinema-backend
call mvn clean compile -DskipTests -q 2>nul
echo   Backend launching...
start /B mvn spring-boot:run -q > ..\log-backend.txt 2>&1
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

REM ---- Wait for services to come online ----
echo.
echo Waiting for services...
:wait_backend
timeout /t 3 /nobreak >nul
curl -s http://localhost:9231/captcha >nul 2>&1
if %errorlevel% neq 0 goto wait_backend
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
