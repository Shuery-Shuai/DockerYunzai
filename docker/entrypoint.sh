#!/bin/sh
set -e

# 自动修复权限
if [ "$(stat -c %U /opt/yunzai)" != "node" ]; then
  chown -R node:node /opt/yunzai
fi

# 启动 Xvfb 虚拟显示
Xvfb :99 -screen 0 1280x1024x24 -ac +extension GLX +render -noreset >/dev/null 2>&1 &

# 初始化 Yunzai
if [ ! -d "/opt/yunzai/.git" ]; then
  git clone ${YUNZAI_REPO:-https://github.com/yoimiya-kokomi/Miao-Yunzai.git} . \
    --depth=1
fi

# 安装插件
if [ -n "$PLUGIN_REPOS" ]; then
  mkdir -p plugins
  echo "${PLUGIN_REPOS:-https://github.com/yoimiya-kokomi/miao-plugin.git}" | tr ',' '\n' | while read repo; do
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

# 配置 QSign
bash <(curl -sSLk Gitee.com/haanxuan/QSign/raw/main/X)

# 设置登录信息
if [ -n "$QQ_ACCOUNT" ] ; then
  sed -i "s/qq: '.*'/qq: '$QQ_ACCOUNT'/" config/qq.yml
fi
if  [ -n "$QQ_PASSWORD" ]; then
  sed -i "s/pwd: '.*'/pwd: '$QQ_PASSWORD'/" config/qq.yml
fi

# 设置 Redis
if [ -n "${REDIS_HOST:-redis}" && "${REDIS_PORT:-6379}" ]; then
  sed -i "s/host: '.*'/host: '$REDIS_HOST'/" config/redis.yml
  sed -i "s/port: '.*'/port: '$REDIS_PORT'/" config/redis.yml
fi
if [ -n "$REDIS_USERNAME" ]; then
  sed -i "s/username: '.*'/username: '$REDIS_USERNAME'/" config/redis.yml
fi
if [-n "$REDIS_PASSWORD" ]; then
  sed -i "s/password: '.*'/password: '$REDIS_PASSWORD'/" config/redis.yml
fi
if [ -n "$REDIS_DB" ]; then
  sed -i "s/db: '.*'/db: '$REDIS_DB'/" config/redis.yml
fi

# 等待 Redis
if [ -n "$REDIS_HOST" ]; then
  until nc -zv ${REDIS_HOST:-redis} ${REDIS_PORT:-6379} >/dev/null 2>&1; do
    echo "Waiting for Redis ready..."
    sleep 1
  done
fi

# 运行 Yunzai
pnpm start

exec "$@"
