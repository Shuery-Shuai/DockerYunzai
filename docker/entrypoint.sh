#!/bin/sh
set -e

# 自动修复权限
if [ "$(stat -c %U /opt/yunzai)" != "node" ]; then
  chown -R node:node /opt/yunzai
fi

# 启动 Xvfb 虚拟显示
Xvfb :99 -screen 0 1280x1024x24 -ac +extension GLX +render -noreset >/dev/null 2>&1 &

# 等待 Redis
if [ -n "$REDIS_HOST" ]; then
  until redis-cli -h $REDIS_HOST -p ${REDIS_PORT:-6379} ping >/dev/null 2>&1; do
    echo "Waiting for Redis..."
    sleep 1
  done
fi

# 初始化 Yunzai
if [ ! -d "/opt/yunzai/.git" ]; then
  git clone ${YUNZAI_REPO:-https://github.com/yoimiya-kokomi/Miao-Yunzai.git} . \
    --depth=1
fi

# 安装插件
if [ -n "$PLUGIN_REPOS" ]; then
  mkdir -p plugins
  echo "$PLUGIN_REPOS" | tr ',' '\n' | while read repo; do
    plugin_name=$(basename $repo .git)
    if [ ! -d "plugins/$plugin_name" ]; then
      git clone $repo "plugins/$plugin_name" \
        --depth=1
    fi
  done
fi

# 安装依赖
if [ ! -d "node_modules" ]; then
  pnpm install -P
fi

exec "$@"
