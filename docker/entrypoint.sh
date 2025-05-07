#!/bin/sh
#================================================================
# HEADER
#================================================================
# 脚本名称: entrypoint.sh
# 作    者: shuery
# 版    本: 0.1.0
# 创建时间: 2025-05-07
# 用    途: Yunzai Bot 容器入口脚本
# 兼容性: 适用于 POSIX shell 环境
# 依赖要求: 
#   - git: 用于仓库克隆
#   - pnpm: Node.js 包管理
#   - redis: 数据库服务
#   - Xvfb: 虚拟显示服务
# 环境变量:
#   - YUNZAI_REPO: Yunzai 仓库地址（默认 Miao-Yunzai）
#   - PLUGIN_REPOS: 插件仓库列表（逗号分隔）
#   - PNPM_REGISTRY: pnpm 镜像源
#   - REDIS_*: Redis 连接配置
#   - QQ_ACCOUNT: 机器人QQ号（必需）
#   - QQ_PASSWORD: 机器人密码（必需）
#   - GITHUB_PROXY: GitHub 镜像代理地址
#================================================================

set -e

#================================================================
# 目录权限修复
#================================================================
_yz_dir="/app/yunzai"
if [ "$(stat -c %U "$_yz_dir")" != "node" ]; then
  chown -R node:node "$_yz_dir"
fi

#================================================================
# 函数: clone_repo
# 用  途: 克隆 Git 仓库并处理 GitHub 镜像代理
# 参  数:
#   $1 - 仓库地址
#   $2 - 目标目录
# 环境变量:
#   - GITHUB_PROXY: GitHub 镜像代理地址
#================================================================
clone_repo() {
  local repo="$1"
  local target="$2"
  [ -d "$target/.git" ] && return 0
  
  if [ -n "${GITHUB_PROXY}" ] && [[ "$repo" == https://github.com/* ]]; then
    repo="https://${GITHUB_PROXY}/github.com/${repo#https://github.com/}"
  fi

  git clone "$repo" "$target" --depth=1
}

#================================================================
# 初始化虚拟显示服务
#================================================================
Xvfb :99 -screen 0 1280x1024x24 -ac +extension GLX +render -noreset >/dev/null 2>&1 &

#================================================================
# 主执行流程
#================================================================
# 1. 初始化 Yunzai 本体
clone_repo "${YUNZAI_REPO:-https://github.com/yoimiya-kokomi/Miao-Yunzai.git}" "$_yz_dir"

# 2. 安装插件模块
mkdir -p "$_yz_dir/plugins"
IFS=','
set -f
for repo in ${PLUGIN_REPOS:-https://github.com/yoimiya-kokomi/miao-plugin.git}; do
  plugin_name=$(basename "${repo}" .git)
  clone_repo "$repo" "$_yz_dir/plugins/$plugin_name"
done
set +f
unset IFS

#================================================================
# 函数: setup_registry
# 用  途: 配置自定义 pnpm 镜像源
# 环境变量:
#   - PNPM_REGISTRY: pnpm 镜像源地址
#================================================================
setup_registry() {
  [ -z "${PNPM_REGISTRY:-https://registry.npmjs.com}" ] && return 0
  echo "Setting PNPM Registry: $PNPM_REGISTRY"
  pnpm config set registry "$PNPM_REGISTRY"
  pnpm config set strict-ssl false
}
setup_registry

# 3. 安装 Node.js 依赖
pnpm install -P --registry "${PNPM_REGISTRY:-https://registry.npmjs.com}" --prefer-offline --no-cache || {
  echo "Yunzai installation failed"
  exit 1
}

#================================================================
# 函数: install_qsign
# 用  途: 安装 QSign 签名服务
# 注  意: 安装失败将终止容器启动
#================================================================
install_qsign() {
  bash <(curl -fsSLk https://gitee.com/haanxuan/QSign/raw/main/X) || {
    echo "QSign installation failed"
    exit 1
  }
}
install_qsign

#================================================================
# 函数: configure_yml
# 用  途: 统一配置 YAML 文件
# 参  数:
#   $1 - 配置文件路径
#   $2 - 配置键
#   $3 - 配置值
#================================================================
configure_yml() {
  local file="$1"
  local key="$2"
  local value="$3"
  [ -n "$value" ] && sed -i "s/^${key}:.*$/${key}: '${value}'/" "$file"
}

# 4. 配置 QQ 账号信息
configure_yml "config/qq.yml" "qq" "$QQ_ACCOUNT"
[ -n "$QQ_PASSWORD" ] && configure_yml "config/qq.yml" "pwd" "$QQ_PASSWORD"

# 5. 配置 Redis 连接
configure_yml "config/redis.yml" "host" "${REDIS_HOST:-redis}"
configure_yml "config/redis.yml" "port" "${REDIS_PORT:-6379}"
[ -n "$REDIS_USERNAME" ] && configure_yml "config/redis.yml" "username" "$REDIS_USERNAME"
[ -n "$REDIS_PASSWORD" ] && configure_yml "config/redis.yml" "password" "$REDIS_PASSWORD"
[ -n "$REDIS_DB" ] && configure_yml "config/redis.yml" "db" "$REDIS_DB"

#================================================================
# 函数: wait_for_redis
# 用  途: 等待 Redis 服务就绪（带30秒超时机制）
# 环  境:
#   - REDIS_HOST: Redis 服务地址（默认 redis）
#   - REDIS_PORT: Redis 服务端口（默认 6379）
#================================================================
wait_for_redis() {
  local timeout=30
  until nc -zv "${REDIS_HOST:-redis}" "${REDIS_PORT:-6379}" >/dev/null 2>&1; do
    [ $((timeout--)) -le 0 ] && {
      echo "Redis connection timeout"
      exit 1
    }
    echo "Waiting for Redis ready..."
    sleep 1
  done
}
wait_for_redis

# 6. 启动 Yunzai Bot
pnpm start

# 7. 执行用户自定义命令
exec "$@"
