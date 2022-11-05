@echo off
:: User configuration
set DISCORD_ID=384274248799223818

:: Dev configuration
set API_BASE=http://civ.ielden.eu/
set TARGET_PATH=eldenApiGeneral.lua


:: Actual script
cd /D "%~dp0"

if exist %TARGET_PATH% (
    curl.exe %API_BASE%mphLoader?discord_id=%DISCORD_ID% > %TARGET_PATH% && echo Successfully loaded API Info
)

:: Run Game
echo Launching game ...
explorer "steam://rungameid/289070"