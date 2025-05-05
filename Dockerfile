FROM node:lts-slim

LABEL maintainer="2463253700@qq.com"
LABEL description="Yunzai Bot Docker Image"
ARG PNPM_VERSION=latest

ENV TZ=Asia/Shanghai \
  PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
  PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
  DISPLAY=:99

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
  apt update && apt upgrade -y && \
  apt install -y --no-install-recommends \
  ffmpeg libopencore-amrnb0 libopencore-amrwb0 libmp3lame0 \
  chromium xvfb ca-certificates \
  git unzip curl && \
  apt clean && rm -rf /var/lib/apt/lists/* && \
  curl -fsSL https://gist.githubusercontent.com/Shuery-Shuai/3fb6366e5f0e288168f1c1b60380b607/raw/fe77dedfaa844a1bb35101489620f0ab9b2f2b6b/option-1.install-sarasa-nerd-font.sh | sh -s -- --no-confirm --force

RUN corepack enable && \
  corepack prepare pnpm@${PNPM_VERSION} --activate && \
  mkdir -p /opt/yunzai && \
  chown -R node:node /opt/yunzai && \
  chmod 750 /opt/yunzai

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER node
WORKDIR /opt/yunzai
ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
