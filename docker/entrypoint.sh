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

  wait_for_redis
}

exec "$@"
