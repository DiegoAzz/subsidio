# Multi-stage Dockerfile para exportar y servir el juego Web en Coolify (subsidio.appzplay.online)
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV GODOT_VERSION=4.7.2

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
    libfontconfig1 \
    libasound2 \
    libxcursor1 \
    libxinerama1 \
    libxrandr2 \
    libxi6 \
    && rm -rf /var/lib/apt/lists/*

# Descargar Godot Linux Headless
RUN curl -L -o /tmp/godot.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip \
    && unzip /tmp/godot.zip -d /usr/local/bin \
    && mv /usr/local/bin/Godot_v4.7.2-stable_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot \
    && rm /tmp/godot.zip

# Descargar e instalar plantillas oficiales de exportación
RUN mkdir -p /root/.local/share/godot/export_templates/4.7.2.stable \
    && curl -L -o /tmp/templates.tpz https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz \
    && unzip /tmp/templates.tpz -d /tmp/templates \
    && mv /tmp/templates/templates/* /root/.local/share/godot/export_templates/4.7.2.stable/ \
    && rm -rf /tmp/templates*

WORKDIR /app
COPY . /app

# Exportar el proyecto para la Web (HTML5/WebAssembly)
RUN mkdir -p /app/export/web \
    && godot --headless --export-release "Web" /app/export/web/index.html

# Stage 2: Servidor Nginx ultra-ligero
FROM nginx:alpine

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/export/web/ /usr/share/nginx/html/

# Exponer puertos habituales para máxima compatibilidad con Coolify/Traefik
EXPOSE 80
EXPOSE 3000
EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
