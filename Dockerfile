FROM node:lts-slim

LABEL maintainer="2463253700@qq.com"
LABEL description="Yunzai Bot Docker Image"
ARG PNPM_VERSION=latest

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime

WORKDIR /opt/yunzai

RUN corepack enable
corepack prepare pnpm@${PNPM_VERSION} --activate &&
  mkdir -p /opt/yunzai &&
  chown -R node:node /opt/yunzai &&
  chmod 750 /opt/yunzai

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
USER node
ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
