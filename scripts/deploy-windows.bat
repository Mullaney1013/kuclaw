@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fI"

set "BUILD_DIR=%ROOT_DIR%\build-windows"
set "DEPLOY_DIR=%ROOT_DIR%\dist\windows\Kuclaw"
set "CONFIG=Release"
set "DO_BUILD=0"
set "TARGET=kuclaw_desktop"

:parse_args
if "%~1"=="" goto after_args

if /I "%~1"=="--build" (
  set "DO_BUILD=1"
  shift
  goto parse_args
)

if /I "%~1"=="--debug" (
  set "CONFIG=Debug"
  shift
  goto parse_args
)

if /I "%~1"=="--release" (
  set "CONFIG=Release"
  shift
  goto parse_args
)

if /I "%~1"=="--build-dir" (
  if "%~2"=="" goto missing_build_dir
  set "BUILD_DIR=%~f2"
  shift
  shift
  goto parse_args
)

if /I "%~1"=="--deploy-dir" (
  if "%~2"=="" goto missing_deploy_dir
  set "DEPLOY_DIR=%~f2"
  shift
  shift
  goto parse_args
)

if /I "%~1"=="-h" goto usage
if /I "%~1"=="--help" goto usage

echo [deploy-windows] Unknown argument: %~1
goto usage_error

:missing_build_dir
echo [deploy-windows] --build-dir requires a path.
goto usage_error

:missing_deploy_dir
echo [deploy-windows] --deploy-dir requires a path.
goto usage_error

:usage
echo.
echo Usage:
echo   scripts\deploy-windows.bat [--build] [--release^|--debug] [--build-dir PATH] [--deploy-dir PATH]
echo.
echo Options:
echo   --build              Run CMake configure/build before deploy.
echo   --release            Deploy Release output. Default.
echo   --debug              Deploy Debug output.
echo   --build-dir PATH     Override the CMake build directory. Default: .\build-windows
echo   --deploy-dir PATH    Override the output directory. Default: .\dist\windows\Kuclaw
echo.
echo Notes:
echo   1. Run this script on Windows after Qt is installed.
echo   2. The script will look for windeployqt.exe via WINDEPLOYQT_EXE, PATH, then QTDIR\bin.
echo   3. The output directory will be recreated on each run.
echo   4. The default build directory is .\build-windows to avoid reusing macOS CMake cache copied from another machine.
echo.
exit /b 0

:usage_error
call :usage
exit /b 1

:after_args
if /I not "%OS%"=="Windows_NT" (
  echo [deploy-windows] This script must run on Windows.
  exit /b 1
)

if "%DO_BUILD%"=="1" (
  if not exist "%BUILD_DIR%\CMakeCache.txt" (
    if defined QTDIR (
      cmake -S "%ROOT_DIR%" -B "%BUILD_DIR%" -DCMAKE_PREFIX_PATH="%QTDIR%"
    ) else (
      cmake -S "%ROOT_DIR%" -B "%BUILD_DIR%"
    )
    if errorlevel 1 exit /b 1
  )

  cmake --build "%BUILD_DIR%" --config %CONFIG% --target %TARGET%
  if errorlevel 1 exit /b 1
)

set "APP_EXE="
if exist "%BUILD_DIR%\apps\kuclaw-desktop\%CONFIG%\Kuclaw.exe" (
  set "APP_EXE=%BUILD_DIR%\apps\kuclaw-desktop\%CONFIG%\Kuclaw.exe"
)
if not defined APP_EXE if exist "%BUILD_DIR%\apps\kuclaw-desktop\Kuclaw.exe" (
  set "APP_EXE=%BUILD_DIR%\apps\kuclaw-desktop\Kuclaw.exe"
)
if not defined APP_EXE if exist "%BUILD_DIR%\%CONFIG%\Kuclaw.exe" (
  set "APP_EXE=%BUILD_DIR%\%CONFIG%\Kuclaw.exe"
)

if not defined APP_EXE (
  echo [deploy-windows] Kuclaw.exe not found.
  echo [deploy-windows] Expected one of:
  echo   %BUILD_DIR%\apps\kuclaw-desktop\%CONFIG%\Kuclaw.exe
  echo   %BUILD_DIR%\apps\kuclaw-desktop\Kuclaw.exe
  echo   %BUILD_DIR%\%CONFIG%\Kuclaw.exe
  echo [deploy-windows] Try running with --build.
  exit /b 1
)

set "WINDEPLOYQT="
if defined WINDEPLOYQT_EXE if exist "%WINDEPLOYQT_EXE%" (
  set "WINDEPLOYQT=%WINDEPLOYQT_EXE%"
)

if not defined WINDEPLOYQT (
  for /f "delims=" %%I in ('where windeployqt.exe 2^>nul') do (
    if not defined WINDEPLOYQT set "WINDEPLOYQT=%%I"
  )
)

if not defined WINDEPLOYQT if defined QTDIR if exist "%QTDIR%\bin\windeployqt.exe" (
  set "WINDEPLOYQT=%QTDIR%\bin\windeployqt.exe"
)

if not defined WINDEPLOYQT (
  echo [deploy-windows] windeployqt.exe not found.
  echo [deploy-windows] Set WINDEPLOYQT_EXE, add Qt\bin to PATH, or set QTDIR.
  exit /b 1
)

if exist "%DEPLOY_DIR%" (
  rmdir /s /q "%DEPLOY_DIR%"
)
mkdir "%DEPLOY_DIR%"
if errorlevel 1 exit /b 1

copy /y "%APP_EXE%" "%DEPLOY_DIR%\Kuclaw.exe" >nul
if errorlevel 1 exit /b 1

set "DEPLOY_MODE=--release"
if /I "%CONFIG%"=="Debug" set "DEPLOY_MODE=--debug"

"%WINDEPLOYQT%" %DEPLOY_MODE% --compiler-runtime --qmldir "%ROOT_DIR%\qml" --dir "%DEPLOY_DIR%" "%APP_EXE%"
if errorlevel 1 exit /b 1

echo.
echo [deploy-windows] Deploy completed.
echo [deploy-windows] Executable directory:
echo   %DEPLOY_DIR%
echo [deploy-windows] Entry executable:
echo   %DEPLOY_DIR%\Kuclaw.exe
echo.
echo [deploy-windows] Suggested next step:
echo   Start "%DEPLOY_DIR%\Kuclaw.exe" on the Windows machine and run the F1 screenshot smoke test.
exit /b 0
