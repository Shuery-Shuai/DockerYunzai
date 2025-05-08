FROM node:lts-slim

LABEL maintainer="2463253700@qq.com"
LABEL description="Yunzai Bot Docker Image"
ARG PNPM_VERSION=latest

ENV TZ=Asia/Shanghai \
  PNPM_HOME=/app/yunzai/.pnpm \
  PNPM_STORE_PATH=/app/yunzai/.pnpm/store \
  PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
  PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
  PUPPETEER_ARGS=--no-sandbox,--disable-setuid-sandbox,--disable-dev-shm-usage \
  DISPLAY=:99 \
  FFMPEG_PATH=/usr/bin/ffmpeg

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
  apt-get update && apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
  chromium xvfb ca-certificates \
  ffmpeg libopencore-amrnb0 libopencore-amrwb0 libmp3lame0 \
  python3 python-is-python3 \
  netcat-openbsd git unzip curl bash && \
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  curl -fsSL https://gist.githubusercontent.com/Shuery-Shuai/3fb6366e5f0e288168f1c1b60380b607/raw/fe77dedfaa844a1bb35101489620f0ab9b2f2b6b/appion-1.install-sarasa-nerd-font.sh | sh -s -- --no-confirm --force

RUN corepack enable && \
  corepack prepare pnpm@${PNPM_VERSION} --activate && \
  mkdir -p /app/yunzai && \
  chown -R node:node /app/yunzai && \
  chmod 750 /app/yunzai

COPY ./docker/entrypoint.sh /entrypoint.sh
RUN apt-get update && apt-get install -y dos2unix && \
  dos2unix /entrypoint.sh && \
  chmod 755 /entrypoint.sh && \
  sed -i '1s/^/\n/' /entrypoint.sh && \
  sed -i '1s/^/#!\/bin\/bash\n/' /entrypoint.sh

USER node
WORKDIR /app/yunzai

VOLUME ["/app/yunzai"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["tail", "-f", "/dev/null"]
