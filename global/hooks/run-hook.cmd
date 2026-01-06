: << 'CMDBLOCK'
@echo off
REM Polyglot wrapper: runs .sh scripts cross-platform
REM Usage: run-hook.cmd <script-name> [args...]
REM The script should be in the same directory as this wrapper
REM
REM This file works both as a Windows batch file and a Unix shell script.
REM The Windows portion is at the top, Unix portion at the bottom.

if "%~1"=="" (
    echo run-hook.cmd: missing script name >&2
    exit /b 1
)

REM Try common Git Bash locations
if exist "C:\Program Files\Git\bin\bash.exe" (
    "C:\Program Files\Git\bin\bash.exe" -l "%~dp0%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)

if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    "C:\Program Files (x86)\Git\bin\bash.exe" -l "%~dp0%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)

REM Try WSL
where wsl >nul 2>&1
if %ERRORLEVEL% == 0 (
    wsl bash -l "%~dp0%~1" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b %ERRORLEVEL%
)

echo run-hook.cmd: could not find bash (Git Bash or WSL required) >&2
exit /b 1
CMDBLOCK

# ============================================================================
# Unix shell runs from here
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift

if [[ -z "$SCRIPT_NAME" ]]; then
    echo "run-hook.cmd: missing script name" >&2
    exit 1
fi

SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_NAME}"

if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "run-hook.cmd: script not found: $SCRIPT_PATH" >&2
    exit 1
fi

if [[ ! -x "$SCRIPT_PATH" ]]; then
    # Make executable if not already
    chmod +x "$SCRIPT_PATH" 2>/dev/null || true
fi

exec "${SCRIPT_PATH}" "$@"
