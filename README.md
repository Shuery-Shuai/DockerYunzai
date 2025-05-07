# Yunzai-Bot Docker 容器化部署

[![Docker Image CI](https://github.com/Shuery-Shuai/DockerYunzai/actions/workflows/docker.yml/badge.svg)](https://github.com/Shuery-Shuai/DockerYunzai/actions)
[![GitHub Container Registry](https://img.shields.io/badge/Container%20Registry-GHCR-blue)](https://github.com/Shuery-Shuai/DockerYunzai/pkgs/container/DockerYunzai)

专为 Yunzai-Bot 设计的 Docker 容器化解决方案，支持多架构部署，提供开箱即用的运行环境。

## ✨ 特性

- ✅ 预配置 Node.js LTS 环境
- 🚀 集成 pnpm 包管理工具
- 🔒 非 root 用户运行保障安全
- 📦 自动持久化数据存储
- 🌐 多架构支持 (AMD64/ARM64)

## 🚀 快速开始

### 使用 Docker CLI

```bash
docker run -d \
  --name yunzai-bot \
  -v yunzai_data:/app/yunzai \
  -e TZ=Asia/Shanghai \
  ghcr.io/Shuery-Shuai/DockerYunzai:latest
```

### 使用 docker-compose

```bash
# 下载配置文件
curl -O https://raw.githubusercontent.com/Shuery-Shuai/DockerYunzai/main/docker-compose.yml

# 启动服务
docker-compose up -d
```

## ⚙️ 配置指南

### 环境变量

| 变量名            | 默认值                  | 说明          |
| ----------------- | ----------------------- | ------------- |
| `TZ`              | Asia/Shanghai           | 容器时区      |
| `PNPM_HOME`       | /app/yunzai/.pnpm       | pnpm 安装路径 |
| `PNPM_STORE_PATH` | /app/yunzai/.pnpm/store | 包存储路径    |

### 数据卷

| 卷名        | 容器路径    | 说明               |
| ----------- | ----------- | ------------------ |
| yunzai_data | /app/yunzai | 存储所有配置和插件 |

## 🔄 更新管理

```bash
# 拉取最新镜像
docker pull ghcr.io/Shuery-Shuai/DockerYunzai:latest

# 重启容器
docker-compose down && docker-compose up -d
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
