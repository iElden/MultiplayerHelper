#!/usr/bin/env bash
# User configuration
DISCORD_ID=181879507756515328

# Dev configuration
API_BASE="http://127.0.0.1:45612/"
TARGET_PATH="eldenApiGeneral.lua"

cd "$(dirname "$0")"
if [ -f $TARGET_PATH ]; then
  if curl "${API_BASE}mphLoader?discord_id=${DISCORD_ID}" > $TARGET_PATH; then
    echo "Successfully loaded API Info"
  fi
fi

# Run Game
echo "Launching game ..."
explorer "steam://rungameid/289070"