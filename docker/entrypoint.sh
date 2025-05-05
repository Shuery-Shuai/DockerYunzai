#!/bin/sh
set -e

wait_for_redis() {
  echo "Waiting for Redis..."
  until redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD ping >/dev/null 2>&1; do
    sleep 1
  done
}

{
  if [ "$(stat -c %U /opt/yunzai)" != "node" ]; then
    chown -R node:node /opt/yunzai
  fi

  if [ ! -d "/opt/yunzai/.git" ]; then
    echo "Cloning Yunzai repository..."
    git clone ${YUNZAI_REPO:-https://github.com/yoimiya-kokomi/Miao-Yunzai.git} . \
      --depth=1
  fi

  if [ -n "$PLUGIN_REPOS" ]; then
    mkdir -p plugins
    echo "$PLUGIN_REPOS" | tr ',' '\n' | while read repo; do
      plugin_name=$(basename $repo .git)
      if [ ! -d "plugins/$plugin_name" ]; then
        echo "Installing plugin: $plugin_name"
        git clone $repo "plugins/$plugin_name" \
          --depth=1
      fi
    done
  fi

  if [ ! -d "node_modules" ]; then
    pnpm install -P
  fi

  wait_for_redis
}

exec "$@"
