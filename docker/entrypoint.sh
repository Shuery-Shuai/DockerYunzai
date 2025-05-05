#!/bin/sh
set -e

# 自动修复挂载卷权限
if [ "$(stat -c %U /opt/yunzai)" != "node" ]; then
  chown -R node:node /opt/yunzai
fi

exec "$@"
