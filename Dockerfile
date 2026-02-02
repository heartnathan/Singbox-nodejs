# ========================
# Stage 1: Builder (下載 sing-box + 安裝 node 依賴)
# ========================
FROM node:20-alpine AS builder

WORKDIR /app

# 只複製 package.json 先安裝依賴（快取優化）
COPY package.json ./
RUN npm install --production

# 複製所有程式碼
COPY . .

# （可選）如果你想在 build 時就產生一些東西，這裡可以跑 node index.js 但通常不需要

# ========================
# Stage 2: Runtime (最終輕量映像)
# ========================
FROM node:20-alpine

# 安裝必要的工具（wget/curl 用來下載 sing-box，busybox 內建 crontab）
RUN apk add --no-cache wget curl bash tzdata

# 設定時區（台灣/中國常用 CST）
ENV TZ=Asia/Shanghai

WORKDIR /app

# 從 builder 階段複製 node_modules 和程式碼
COPY --from=builder /app /app

# 預設暴露三種協議的端口（你可以之後在 docker run 或 compose 裡改）
# TUIC / HY2 / VLESS 通常用不同端口，這裡先暴露常見範圍
EXPOSE 443 8443 10000-20000/udp

# 入口點：先跑 start.sh（它會下載 sing-box、產生 config、啟動）
# 如果 start.sh 沒 foreground 運行，容器會馬上退出 → 所以建議改成 foreground 方式
CMD ["bash", "start.sh"]
