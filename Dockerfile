# 使用轻量的 LTS 镜像
FROM node:lts-slim

# 元数据
LABEL maintainer="2463253700@qq.com"
LABEL description="Yunzai Bot Docker Image"
LABEL version="1.0.0"

# 系统时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime

# 启用 corepack
RUN corepack enable

# 安装最新 pnpm 并设置存储路径
ENV PNPM_HOME=/opt/yunzai/.pnpm
ENV PNPM_STORE_PATH=/opt/yunzai/.pnpm/store
RUN corepack prepare pnpm@latest --activate

# 创建工作目录并设置权限
RUN mkdir -p /opt/yunzai &&
  chown -R node:node /opt/yunzai && \
  chmod 750 /opt/yunzai

# 自动修复权限
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# 切换非root用户（推荐）
USER node

WORKDIR /opt/yunzai

CMD ["tail", "-f", "/dev/null"]
