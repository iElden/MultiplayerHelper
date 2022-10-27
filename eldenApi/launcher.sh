# User configuration
DISCORD_ID=384274248799223818

# Dev configuration
API_BASE="http://127.0.0.1:45612/"
TARGET_PATH="eldenApiGeneral.lua"

cd "$(dirname "$0")" # setcwd to script dir
if [ -f $TARGET_PATH ]; then
  if curl $API_BASE"mphLoader" > $TARGET_PATH; then
    echo "Successfully loaded API Info"
  fi
fi

# Run Game
echo "Launching game ..."
explorer "steam://rungameid/289070"