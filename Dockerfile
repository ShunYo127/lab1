# 使用輕量級且較新穩定的 Nginx Alpine 映像（移除 perl 套件以減少攻擊面）
FROM nginx:1.28.0-alpine

# 維護者資訊
LABEL org.opencontainers.image.source="https://github.com/YOUR_USERNAME/YOUR_REPO"
LABEL org.opencontainers.image.description="井字遊戲 - 靜態網頁應用"
LABEL org.opencontainers.image.licenses="MIT"

# 移除預設的 Nginx 網頁
RUN rm -rf /usr/share/nginx/html/*

# 複製靜態檔案到 Nginx 目錄
COPY app/ /usr/share/nginx/html/

# 建立自訂的 Nginx 配置（監聽 8080 端口以支援非 root 用戶）
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 修改 Nginx 配置以支援非 root 用戶運行
RUN sed -i 's/listen\s*80;/listen 8080;/g' /etc/nginx/conf.d/default.conf && \
    sed -i 's/listen\s*\[::\]:80;/listen [::]:8080;/g' /etc/nginx/conf.d/default.conf && \
    sed -i '/user\s*nginx;/d' /etc/nginx/nginx.conf && \
    sed -i 's,/var/run/nginx.pid,/tmp/nginx.pid,' /etc/nginx/nginx.conf && \
    sed -i "/^http {/a \    proxy_temp_path /tmp/proxy_temp;\n    client_body_temp_path /tmp/client_temp;\n    fastcgi_temp_path /tmp/fastcgi_temp;\n    uwsgi_temp_path /tmp/uwsgi_temp;\n    scgi_temp_path /tmp/scgi_temp;\n" /etc/nginx/nginx.conf

# 使用已釘選的 Alpine-based Nginx 以維持可重現性（不要在建置時升級套件）

# 針對性升級有已知高/重大漏洞的套件（減少變更範圍）
RUN apk update && apk add --no-cache --upgrade libxml2 libpng

# 進一步針對 remaining MEDIUM 漏洞升級 busybox 與 c-ares
RUN apk add --no-cache --upgrade busybox c-ares || true

# 使用輕量級 Alpine 基底以減少攻擊面與套件數量

# 暴露 8080 端口（非特權端口）
EXPOSE 8080

# 啟動 Nginx
CMD ["nginx", "-g", "daemon off;"]