# Yunzai-Bot Docker 容器化部署

[![Docker Publish](https://github.com/Shuery-Shuai/Yunzai/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Shuery-Shuai/Yunzai/actions)
[![GitHub Container Registry](https://img.shields.io/badge/Container%20Registry-GHCR-black)](https://github.com/Shuery-Shuai/Yunzai/pkgs/container/Yunzai)
[![Docker Hub](https://img.shields.io/badge/Container%20Registry-DockerHub-blue)](https://hub.docker.com/r/shuery/yunzai)

专为 Yunzai-Bot 设计的 Docker 容器化解决方案，支持多架构部署，提供开箱即用的运行环境。

## ✨ 功能特性

- ✅ 预配置 Node.js LTS 环境
- 🚀 集成 pnpm 包管理工具
- 🔒 非 root 用户运行保障安全
- 📦 自动持久化数据存储
- 🌐 多架构支持 (AMD64/ARM64)
- 🔍 容器健康监测（通过 pnpm/redis-cli）

## 🚀 快速开始

### 创建环境变量文件

1. 配置运行变量

   ```bash
   ENV_FILE=$HOME/.config/docker/yunzai/.env
   EXPOSE_PORTS=
   YUNZAI_REPO=https://github.com/yoimiya-kokomi/Miao-Yunzai.git
   PLUGIN_REPOS=https://github.com/yoimiya-kokomi/miao-plugin.git,https://github.com/guoba-yunzai/guoba-plugin.git
   GITHUB_PROXY=
   PNPM_REGISTRY=https://registry.npmjs.com
   REDIS_HOST=127.0.0.1
   REDIS_PORT=6379
   REDIS_PASSWORD=
   REDIS_DB=0
   QQ_ACCOUNT=
   QQ_PASSWORD=
   ```

2. 创建 .env 文件

   ```bash
   mkdir -p $(dirname $ENV_FILE) && touch $ENV_FILE
   cat <<EOF > $ENV_FILE
   EXPOSE_PORTS=$EXPOSE_PORTS
   YUNZAI_REPO=$YUNZAI_REPO
   PLUGIN_REPOS=$PLUGIN_REPOS
   GITHUB_PROXY=$GITHUB_PROXY
   PNPM_REGISTRY=$PNPM_REGISTRY
   REDIS_HOST=$REDIS_HOST
   REDIS_PORT=$REDIS_PORT
   REDIS_PASSWORD=$REDIS_PASSWORD
   REDIS_DB=$REDIS_DB
   QQ_ACCOUNT=$QQ_ACCOUNT
   QQ_PASSWORD=$QQ_PASSWORD
   EOF
   ```

### 运行容器

#### 使用 Docker CLI

1. 配置运行变量

   ```bash
   LAUNCH_FILE=$HOME/.config/docker/yunzai/start.sh
   ```

2. 创建启动脚本

   ```bash
   mkdir -p $(dirname $LAUNCH_FILE) && touch $LAUNCH_FILE

   PORT_ARGS=""
   if [ -n "$EXPOSE_PORTS" ]; then
     IFS=',' read -ra PORTS <<< "$EXPOSE_PORTS"
     for port in "${PORTS[@]}"; do
       PORT_ARGS+="-p $port "
     done
   fi

   cat <<EOF > $LAUNCH_FILE
   #!/usr/bin/env bash
   # 启动 Yunzai 服务
   docker run -d \\
     --name yunzai \\
     --env-file $ENV_FILE \\
     -v yunzai_data:/app/yunzai \\
     ${PORT_ARGS}\\
     shuery/yunzai:latest
   EOF
   ```

3. 赋予启动脚本执行权限

   ```bash
   chmod +x $LAUNCH_FILE
   ```

4. 启动服务

   ```bash
   $LAUNCH_FILE
   ```

#### 使用 docker-compose

1. 配置运行变量

   ```bash
   COMPOSE_FILE=$HOME/.config/docker/yunzai/docker-compose.yml
   ```

2. 下载配置文件

   ```bash
   mkdir -p $(dirname $COMPOSE_FILE) && touch $COMPOSE_FILE
   curl -fsSLk "https://raw.githubusercontent.com/Shuery-Shuai/Yunzai/main/docker-compose.yml" --output $COMPOSE_FILE
   ```

3. 更改配置文件

   ```bash
   PORTS_BLOCK=""
   if [ -n "$EXPOSE_PORTS" ]; then
     IFS=',' read -ra PORTS <<< "$EXPOSE_PORTS"
     for port in "${PORTS[@]}"; do
       PORTS_BLOCK+="      - \"$port\"\n"
     done
   fi

   sed -i \
     -e "s|env_file:.*|env_file: $ENV_FILE|" \
     -e "s|ports:.*|ports:\\n${PORTS_BLOCK}|" \
     $COMPOSE_FILE
   ```

4. 启动完整服务栈

   ```bash
   cd $(dirname $COMPOSE_FILE) && \
   DOCKER_BUILD_CONTEXT=null docker-compose up -d
   ```

## ⚙️ 配置指南

### 环境变量

| 变量名           | 默认值                                                                                                 | 示例值                                                                     | 必需 | 说明                     |
| ---------------- | ------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------- | ---- | ------------------------ |
| `EXPOSE_PORTS`   | 无                                                                                                     | 6379:6379,50831:50831                                                      | 否   | 暴露端口列表（逗号分隔） |
| `YUNZAI_REPO`    | <https://github.com/yoimiya-kokomi/Miao-Yunzai.git>                                                    | <https://github.com/Le-niao/Yunzai.git>                                    | 否   | 指定 Yunzai 本体仓库地址 |
| `PLUGIN_REPOS`   | <https://github.com/yoimiya-kokomi/miao-plugin.git>,<https://github.com/guoba-yunzai/guoba-plugin.git> | <https://github.com/user/plugin1.git>,<https://gitee.com/user/plugin2.git> | 否   | 插件仓库列表（逗号分隔） |
| `GITHUB_PROXY`   | 无                                                                                                     | gh-proxy.com                                                               | 否   | GitHub 镜像代理地址      |
| `PNPM_REGISTRY`  | <https://registry.npmjs.com>                                                                           | <https://registry.npmmirror.com>                                           | 否   | pnpm 镜像源地址          |
| `REDIS_HOST`     | 127.0.0.1                                                                                              | localhost                                                                  | 否   | Redis 服务地址           |
| `REDIS_PORT`     | 6379                                                                                                   | 1234                                                                       | 否   | Redis 服务端口           |
| `REDIS_PASSWORD` | 无                                                                                                     | YourWonderfulPassword!                                                     | 否   | Redis 认证密码           |
| `REDIS_DB`       | 0                                                                                                      | 0                                                                          | 否   | Redis 数据库编号         |
| `QQ_ACCOUNT`     | 无                                                                                                     | 1234567890                                                                 | 是   | 机器人 QQ 号码           |
| `QQ_PASSWORD`    | 无                                                                                                     | YourQQPassword                                                             | 否   | 机器人 QQ 密码           |

### 数据卷

| 卷名        | 容器路径    | 说明                     |
| ----------- | ----------- | ------------------------ |
| yunzai_data | /app/yunzai | 存储机器人配置和插件数据 |

## 🔄 更新管理

### Docker CLI

1. 拉取最新镜像

   ```bash
   docker pull shuery/yunzai:latest
   ```

2. 停止并删除旧容器

   ```bash
   docker stop yunzai && docker rm yunzai
   ```

3. 重新创建容器（保留原有配置）

   ```bash
   $LAUNCH_FILE
   ```

4. 清理无用镜像

   ```bash
   docker image prune -f
   ```

### docker-compose

1. 拉取最新镜像

   ```bash
   docker pull shuery/yunzai:latest
   ```

2. 重启容器

   ```bash
   cd $(dirname $COMPOSE_FILE) && \
   docker-compose down && DOCKER_BUILD_CONTEXT=null docker-compose up -d
   ```

3. 清理无用镜像

   ```bash
   docker image prune -f
   ```

## 🛠️ 故障排查

- 查看实时日志

  ```bash
  docker-compose logs -f yunzai
  ```

- 错误排查

  ```bash
  docker exec -it yunzai tail -n 100 /app/yunzai/logs/*.log
  ```

## 🤝 参与贡献

欢迎提交 Issue 和 PR！请遵循以下步骤：

### 本地开发模式

```bash
# 强制重新构建镜像并启动服务
ENV_FILE=.env.development DOCKER_BUILD_CONTEXT=. docker-compose --profile development up -d --build
```

### 多架构构建支持

- 构建 ARM64 镜像

  ```bash
  docker buildx build --platform linux/arm64 -t shuery/yunzai:arm64 .
  ```

- 构建 AMD64 镜像

  ```bash
  docker buildx build --platform linux/amd64 -t shuery/yunzai:amd64 .
  ```

### 贡献代码流程

1. 配置开发环境

   ```bash
   git clone https://github.com/your-fork/Yunzai.git
   cd Yunzai
   ```

2. 测试容器构建

   ```bash
   docker-compose -f docker-compose.yml build --no-cache
   ```

3. 提交前检查

   ```bash
   # 运行完整测试流程
   docker-compose --profile development up -d --build
   docker-compose exec yunzai pnpm test
   ```

4. 推送变更到您的 fork 仓库后创建 PR

## 📄 开源协议

本项目采用 [MIT License](LICENSE)
