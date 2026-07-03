@echo off
setlocal
set PROJECT=%~dp0..
set OUT=%PROJECT%\builds\windows\MoonGoonsCrimeWars.exe

where godot >nul 2>nul
if errorlevel 1 (
  echo Godot is not available on PATH.
  echo Open this project in Godot 4.7 and use Project ^> Export ^> Windows Desktop instead.
  pause
  exit /b 1
)

if not exist "%PROJECT%\builds\windows" mkdir "%PROJECT%\builds\windows"
echo Exporting MoonGoons: Crime Wars...
godot --headless --path "%PROJECT%" --export-release "Windows Desktop" "%OUT%"
if errorlevel 1 (
  echo Export failed. Confirm Godot export templates are installed.
  pause
  exit /b 1
)

echo Export complete: %OUT%
pause
