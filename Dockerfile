FROM ghcr.io/linuxserver/baseimage-kasmvnc:debianbookworm

ARG BUILD_DATE
ARG VERSION=dev
ARG MT5_SETUP_URL="https://download.terminal.free/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe"
ARG PYTHON_SETUP_URL="https://www.python.org/ftp/python/3.14.0/python-3.14.0-amd64.exe"

LABEL org.opencontainers.image.title="metatrader5-docker"
LABEL org.opencontainers.image.description="MetaTrader 5 with Wine and KasmVNC"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.version="${VERSION}"

ENV TITLE=MetaTrader5 \
    LC_ALL=en_US.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    WINEDEBUG=-all \
    WINEARCH=win64 \
    WINEPREFIX=/config/.wine \
    MT5_TEMPLATE_WINEPREFIX=/opt/mt5-template/.wine \
    MT5_SETUP_URL=${MT5_SETUP_URL} \
    PYTHON_SETUP_URL=${PYTHON_SETUP_URL} \
    MT5_CMD_OPTIONS=

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        gnupg2 \
        xvfb \
        xauth \
        cabextract \
        winbind \
        procps \
        psmisc \
        unzip \
    && mkdir -pm755 /etc/apt/keyrings \
    && wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
    && wget -O /etc/apt/sources.list.d/winehq-bookworm.sources https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-stable \
    && rm -rf /var/lib/apt/lists/*

COPY scripts /scripts
COPY root /

RUN chmod +x /scripts/build/install-mt5.sh \
    /scripts/build/install-python.sh \
    /scripts/runtime/bootstrap-prefix.sh \
    /scripts/runtime/start-mt5.sh \
    /scripts/runtime/healthcheck.sh \
    && mkdir -p /opt/mt5-template /config \
    && /scripts/build/install-mt5.sh \
    && /scripts/build/install-python.sh

EXPOSE 3000
VOLUME /config

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
  CMD /scripts/runtime/healthcheck.sh
