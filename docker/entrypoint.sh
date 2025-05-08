#!/bin/sh
#================================================================
# HEADER
#================================================================
# 脚本名称: entrypoint.sh
# 作    者: shuery
# 版    本: 0.2.0
# 创建时间: 2025-05-07
# 用    途: Yunzai Bot 容器入口脚本
# 兼 容 性: 适用于 POSIX shell 环境
# 依赖要求:
#   - git: 用于仓库克隆
#   - pnpm: Node.js 包管理
#   - redis: 数据库服务
#   - Xvfb: 虚拟显示服务
# 环境变量:
#   - YUNZAI_REPO: Yunzai 仓库地址（默认 Miao-Yunzai）
#   - PLUGIN_REPOS: 插件仓库列表（逗号分隔）
#   - PNPM_REGISTRY: pnpm 镜像源
#   - REDIS_HOST: Redis 服务地址
#   - REDIS_PORT: Redis 服务端口
#   - REDIS_USERNAME: Redis 用户名
#   - REDIS_PASSWORD: Redis 密码
#   - REDIS_DB: Redis 数据库编号
#   - QQ_ACCOUNT: 机器人QQ号（必需）
#   - QQ_PASSWORD: 机器人密码（必需）
#   - GITHUB_PROXY: GitHub 镜像代理地址
#================================================================

set -e

#================================================================
# 预定义颜色和表情常量
#================================================================
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'
TIMESTAMP="[$(date '+%Y-%m-%d %H:%M:%S')]"

# 表情符号
EMO_OK="✅"
EMO_WARN="⚠️"
EMO_ERROR="❌"
EMO_INFO="ℹ️"
EMO_CONFIG="⚙️"
EMO_PLUGIN="🔌"
EMO_DB="🗄️"
EMO_START="🚀"

#================================================================
# 通用日志函数
# 参数:
#   $1 - 日志级别 (INFO/WARN/ERROR)
#   $2 - 日志内容
#================================================================
log() {
  local level=$1
  local message=$2
  local color=""
  local emoji=""

  case "$level" in
  "INFO")
    color="${BLUE}"
    emoji="$EMO_INFO "
    ;;
  "WARN")
    color="${YELLOW}"
    emoji="$EMO_WARN "
    ;;
  "ERROR")
    color="${RED}"
    emoji="$EMO_ERROR "
    ;;
  *)
    color="${RESET}"
    emoji=""
    ;;
  esac

  printf "%s ${color}%5s${RESET}: ${emoji}%s\n" "$TIMESTAMP" "$level" "$message"
}

#================================================================
# 目录权限修复
#================================================================
_yz_dir="/app/yunzai"
log "INFO" "Checking directory permissions... 📂"
if [ "$(stat -c %U "$_yz_dir")" != "node" ]; then
  log "INFO" "Fixing directory ownership... 🔧"
  chown -R node:node "$_yz_dir" || {
    log "ERROR" "Failed to change ownership! ${EMO_ERROR}"
    exit 1
  }
  log "INFO" "Permissions fixed ${EMO_OK}"
fi

#================================================================
# 函数: clone_repo
# 用途: 克隆 Git 仓库并处理 GitHub 镜像代理
# 参数:
#   $1 - 仓库地址 (repo_url)
#   $2 - 目标目录 (target_dir)
# 环境变量:
#   - GITHUB_PROXY: GitHub 镜像代理地址
#================================================================
clone_repo() {
  local repo_url="$1"
  local target_dir="$2"

  if [ -d "${target_dir}/.git" ]; then
    log "INFO" "Repository exists, skipping clone ${EMO_OK}"
    return 0
  fi

  # 处理 GitHub 镜像代理
  if [ -n "${GITHUB_PROXY}" ] && [[ "${repo_url}" == https://github.com/* ]]; then
    repo_url="https://${GITHUB_PROXY}/github.com/${repo_url#https://github.com/}"
    log "INFO" "Using GitHub proxy: ${GITHUB_PROXY} 🌐"
  fi

  log "INFO" "Cloning ${repo_url}... ⎘"
  git clone "${repo_url}" "${target_dir}" --depth=1 || {
    log "ERROR" "Clone failed! ${EMO_ERROR}"
    exit 1
  }
  log "INFO" "Repository cloned successfully ${EMO_OK}"
}

#================================================================
# 初始化虚拟显示服务
#================================================================
log "INFO" "Starting Xvfb virtual display server 🖥️"
Xvfb :99 -screen 0 1280x1024x24 -ac +extension GLX +render -noreset >/dev/null 2>&1 &
export DISPLAY=:99
log "INFO" "Xvfb started ${EMO_OK} (DISPLAY=:99)"

#================================================================
# 主执行流程
#================================================================
log "INFO" "Starting Yunzai Bot initialization... ${EMO_START}"

# 1. 初始化 Yunzai 本体
log "INFO" "Initializing Yunzai core... ${EMO_START}"
clone_repo "${YUNZAI_REPO:-https://github.com/yoimiya-kokomi/Miao-Yunzai.git}" "${_yz_dir}"

# 2. 安装插件模块
log "INFO" "Processing plugins... ${EMO_PLUGIN}"
mkdir -p "${_yz_dir}/plugins" || {
  log "ERROR" "Failed to create plugins dir! ${EMO_ERROR}"
  exit 1
}

IFS=','
set -f
for repo in ${PLUGIN_REPOS:-https://github.com/yoimiya-kokomi/miao-plugin.git}; do
  plugin_name=$(basename "${repo}" .git)
  log "INFO" "Installing plugin: ${plugin_name} ${EMO_PLUGIN}"
  clone_repo "${repo}" "${_yz_dir}/plugins/${plugin_name}"
done
set +f
unset IFS

#================================================================
# 函数: setup_registry
# 用途: 配置自定义 pnpm 镜像源
# 环境变量:
#   - PNPM_REGISTRY: pnpm 镜像源地址
#================================================================
setup_registry() {
  [ -z "${PNPM_REGISTRY}" ] && return 0

  log "INFO" "Configuring PNPM registry... ${EMO_CONFIG}"
  pnpm config set registry "${PNPM_REGISTRY}" || {
    log "ERROR" "Failed to set registry! ${EMO_ERROR}"
    exit 1
  }

  pnpm config set strict-ssl false || {
    log "ERROR" "Failed to disable SSL strict mode ${EMO_ERROR}"
    exit 1
  }
  log "INFO" "PNPM configured ${EMO_OK}"
}
setup_registry

# 3. 安装 Node.js 依赖
log "INFO" "Installing dependencies... 📦"
ARCH=$(uname -m)
case $ARCH in
x86_64) NODE_ARCH="x64" ;;
aarch64) NODE_ARCH="arm64" ;;
*) NODE_ARCH="$ARCH" ;;
esac

npm_config_build_from_source=false \
  npm_config_platform=linux \
  npm_config_arch=$NODE_ARCH \
  pnpm install -P --registry "${PNPM_REGISTRY:-https://registry.npmjs.com}" \
  --prefer-offline --no-cache --shamefully-hoist --ignore-scripts || {
  log "ERROR" "Installation failed! ${EMO_ERROR}"
  exit 1
}
log "INFO" "Dependencies installed ${EMO_OK}"

# 4. 复制默认配置文件
log "INFO" "Copying config files... ${EMO_CONFIG}"
mkdir -p "${_yz_dir}/config/config" &&
  cp -R -n "${_yz_dir}/config/default_config/." "${_yz_dir}/config/config/" &&
  chown -R node:node "${_yz_dir}/config/config" || {
  log "ERROR" "Config copy failed! ${EMO_ERROR}"
  exit 1
}

#================================================================
# 函数: install_qsign
# 用途: 安装 QSign 签名服务
#================================================================
install_qsign() {
  log "INFO" "Installing QSign service... ⚙️"
  curl -fsSLk https://gitee.com/haanxuan/QSign/raw/main/X | bash -s -- || {
    log "ERROR" "QSign install failed! ${EMO_ERROR}"
    exit 1
  }
  log "INFO" "QSign ready ${EMO_OK}"
}
# 5. 安装 QSign 服务
install_qsign

#================================================================
# 函数: configure_yml
# 用途: 统一配置 YAML 文件
# 参数:
#   $1 - 配置文件路径 (config_file)
#   $2 - 配置键 (key)
#   $3 - 配置值 (value)
#================================================================
configure_yml() {
  local config_file="$1"
  local key="$2"
  local value="$3"

  [ -z "$value" ] && return 0

  log "INFO" "Updating config: ${key}=**** ${EMO_CONFIG}"
  if ! sed -i "s/^${key}:.*$/${key}: '${value}'/" "$config_file"; then
    log "WARN" "Config update skipped (key not found) ${EMO_WARN}"
  fi
}

# 6. 配置 QQ 账号
configure_yml "${_yz_dir}/config/config/qq.yaml" "qq" "${QQ_ACCOUNT}"
configure_yml "${_yz_dir}/config/config/qq.yaml" "pwd" "${QQ_PASSWORD}"

# 7. 配置 Redis
redis_config="${_yz_dir}/config/config/redis.yaml"
log "INFO" "Configuring Redis... ${EMO_DB}"
configure_yml "$redis_config" "host" "${REDIS_HOST:-redis}"
configure_yml "$redis_config" "port" "${REDIS_PORT:-6379}"
configure_yml "$redis_config" "username" "${REDIS_USERNAME}"
configure_yml "$redis_config" "password" "${REDIS_PASSWORD}"
configure_yml "$redis_config" "db" "${REDIS_DB}"

#================================================================
# 函数: wait_for_redis
# 用途: 等待 Redis 服务就绪（带30秒超时机制）
#================================================================
wait_for_redis() {
  local timeout=30
  local redis_address="${REDIS_HOST:-redis}:${REDIS_PORT:-6379}"

  log "INFO" "Connecting to Redis at ${redis_address} 🔄"
  until echo "PING" | redis-cli -h "${REDIS_HOST:-redis}" \
    -p "${REDIS_PORT:-6379}" \
    -a "${REDIS_PASSWORD}" >/dev/null 2>&1; do
    if [ $timeout -le 0 ]; then
      log "ERROR" "Redis timeout! Service unavailable ${EMO_ERROR}"
      exit 1
    fi

    log "WARN" "Waiting for Redis... (${timeout}s left) ⏳"
    sleep 1
    timeout=$((timeout - 1))
  done
  log "INFO" "Redis connected ${EMO_OK}"
}
wait_for_redis

# 8. 启动 Yunzai Bot
log "INFO" "Starting Yunzai Bot... ${EMO_START}"
pnpm start

# 9. 执行自定义命令
log "INFO" "Executing command: $* 🛠️"
exec "$@"
