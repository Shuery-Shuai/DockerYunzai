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

### 使用 Docker CLI

```bash
# 配置运行变量
QQ_ACCOUNT=1234567890
QQ_PASSWORD="YourQQPassword"
REDIS_PASSWORD="YourWonderfulPassword!"
REDIS_CONFIG=/data/redis.conf
```

```bash
# 创建专用网络
docker network create yunzai_network

# 启动 Redis 服务
docker run -d \
  --name redis \
  --network yunzai_network \
  -e REDIS_PASSWORD=$REDIS_PASSWORD \
  -v redis_data:/data \
  redis:alpine \
  redis-server $REDIS_CONFIG --requirepass $REDIS_PASSWORD --save 60 1

# 启动 Yunzai 服务
docker run -d \
  --name yunzai \
  --network yunzai_network \
  -v yunzai_data:/app/yunzai \
  -e QQ_ACCOUNT=$QQ_ACCOUNT \
  -e QQ_PASSWORD=$QQ_PASSWORD \
  -e REDIS_PASSWORD=$REDIS_PASSWORD \
  shuery/yunzai:latest
```

### 使用 docker-compose

1. 下载配置文件

   ```bash
   curl -O https://raw.githubusercontent.com/Shuery-Shuai/Yunzai/main/docker-compose.yml
   ```

2. 编辑配置文件

   ```bash
   # 配置修改变量
   QQ_ACCOUNT=1234567890
   QQ_PASSWORD="YourQQPassword"
   REDIS_PASSWORD="YourWonderfulPassword!"
   ```

   ```bash
   # Linux/macOS
   sed -i \
     -e "s/QQ_ACCOUNT=.*/QQ_ACCOUNT=$QQ_ACCOUNT/" \
     -e "s/QQ_PASSWORD=.*/QQ_PASSWORD='$QQ_PASSWORD'/" \
     -e "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$REDIS_PASSWORD/" \
     docker-compose.yml
   ```

   ```powershell
   # Windows (PowerShell)
   (Get-Content docker-compose.yml) -replace 'QQ_ACCOUNT=.*', 'QQ_ACCOUNT=$QQ_ACCOUNT' `
     -replace 'QQ_PASSWORD=.*', 'QQ_PASSWORD=$QQ_PASSWORD' `
     -replace 'REDIS_PASSWORD=.*', 'REDIS_PASSWORD=$REDIS_PASSWORD' |
     Set-Content docker-compose.yml
   ```

3. 启动完整服务栈

   ```bash
   docker-compose up -d
   ```

## ⚙️ 配置指南

### 环境变量

| 变量名           | 默认值                                              | 示例值                                                                     | 必需 | 说明                     |
| ---------------- | --------------------------------------------------- | -------------------------------------------------------------------------- | ---- | ------------------------ |
| `YUNZAI_REPO`    | <https://github.com/yoimiya-kokomi/Miao-Yunzai.git> | <https://github.com/Le-niao/Yunzai.git>                                    | 否   | 指定 Yunzai 本体仓库地址 |
| `PLUGIN_REPOS`   | <https://github.com/yoimiya-kokomi/miao-plugin.git> | <https://github.com/user/plugin1.git>,<https://gitee.com/user/plugin2.git> | 否   | 插件仓库列表（逗号分隔） |
| `GITHUB_PROXY`   | 无                                                  | gh-proxy.com                                                               | 否   | GitHub 镜像代理地址      |
| `PNPM_REGISTRY`  | <https://registry.npmjs.com>                        | <https://registry.npmmirror.com>                                           | 否   | pnpm 镜像源地址          |
| `REDIS_HOST`     | redis                                               | 172.0.0.1                                                                  | 否   | Redis 服务地址           |
| `REDIS_PORT`     | 6379                                                | 1234                                                                       | 否   | Redis 服务端口           |
| `REDIS_PASSWORD` | 无                                                  | "YourWonderfulPassword!"                                                   | 否   | Redis 认证密码           |
| `REDIS_DB`       | 0                                                   | 0                                                                          | 否   | Redis 数据库编号         |
| `QQ_ACCOUNT`     | 无                                                  | 1234567890                                                                 | 是   | 机器人 QQ 号码           |
| `QQ_PASSWORD`    | 无                                                  | "YourQQPassword"                                                           | 否   | 机器人 QQ 密码           |

### 数据卷

| 卷名        | 容器路径    | 说明                     |
| ----------- | ----------- | ------------------------ |
| yunzai_data | /app/yunzai | 存储机器人配置和插件数据 |
| redis_data  | /data       | Redis 持久化数据存储     |

## 🔄 更新管理

```bash
# 拉取最新镜像
docker pull ghcr.io/Shuery-Shuai/Yunzai:latest

# 重启容器
docker-compose down && docker-compose up -d
```

## 🛠️ 故障排查

```bash
# 查看实时日志
docker-compose logs -f yunzai

# 错误排查
docker exec -it yunzai tail -n 100 /app/yunzai/logs/*.log
```

## 🤝 参与贡献

欢迎提交 Issue 和 PR！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feat/xxx`)
3. 提交修改 (`git commit -am 'Add some feature'`)
4. 推送分支 (`git push origin feat/xxx`)
5. 创建 Pull Request

## 📄 开源协议

本项目采用 [MIT License](LICENSE)
