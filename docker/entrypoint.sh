#!/bin/sh
set -eo pipefail

_yz_dir="/app/yunzai"
if [ "$(stat -c %U "$_yz_dir")" != "node" ]; then
  chown -R node:node "$_yz_dir"
fi

clone_repo() {
  local repo="$1"
  local target="$2"
  [ -d "$target/.git" ] && return 0
  
  if [ -n "${GITHUB_PROXY}" ] && [[ "$repo" == https://github.com/* ]]; then
    repo="https://${GITHUB_PROXY}/github.com/${repo#https://github.com/}"
  fi

  git clone "$repo" "$target" --depth=1
}

Xvfb :99 -screen 0 1280x1024x24 -ac +extension GLX +render -noreset >/dev/null 2>&1 &

clone_repo "${YUNZAI_REPO:-https://github.com/yoimiya-kokomi/Miao-Yunzai.git}" "$_yz_dir"

if [ -n "$PLUGIN_REPOS" ]; then
  mkdir -p "$_yz_dir/plugins"
  IFS=',' read -ra repo_list <<< "${PLUGIN_REPOS}"
  for repo in "${repo_list[@]}"; do
    plugin_name=$(basename "${repo}" .git)
    clone_repo "$repo" "$_yz_dir/plugins/$plugin_name"
  done
fi

setup_registry() {
  [ -z "$PNPM_REGISTRY" ] && return 0
  echo "Setting PNPM Registry: $PNPM_REGISTRY"
  pnpm config set registry "$PNPM_REGISTRY"
  pnpm config set strict-ssl false
}
setup_registry

pnpm install -P

install_qsign() {
  bash <(curl -fsSLk https://gitee.com/haanxuan/QSign/raw/main/X) || {
    echo "QSign installation failed"
    exit 1
  }
}
install_qsign

configure_yml() {
  local file="$1"
  local key="$2"
  local value="$3"
  [ -n "$value" ] && sed -i "s/^${key}:.*$/${key}: '${value}'/" "$file"
}

configure_yml "config/qq.yml" "qq" "$QQ_ACCOUNT"
[ -n "$QQ_PASSWORD" ] && configure_yml "config/qq.yml" "pwd" "$QQ_PASSWORD"

configure_yml "config/redis.yml" "host" "${REDIS_HOST:-redis}"
configure_yml "config/redis.yml" "port" "${REDIS_PORT:-6379}"
[ -n "$REDIS_USERNAME" ] && configure_yml "config/redis.yml" "username" "$REDIS_USERNAME"
[ -n "$REDIS_PASSWORD" ] && configure_yml "config/redis.yml" "password" "$REDIS_PASSWORD"
[ -n "$REDIS_DB" ] && configure_yml "config/redis.yml" "db" "$REDIS_DB"

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

pnpm start

exec "$@"
