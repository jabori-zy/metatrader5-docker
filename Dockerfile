ARG BUILD_DATE
ARG VERSION=dev
ARG MT5_SETUP_URL="https://download.terminal.free/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe"
ARG PYTHON_SETUP_URL="https://www.python.org/ftp/python/3.14.0/python-3.14.0-amd64.exe"
ARG WINE_VERSION=10.0.0.0~bookworm-1

FROM ghcr.io/linuxserver/baseimage-kasmvnc:debianbookworm

ARG BUILD_DATE
ARG VERSION
ARG MT5_SETUP_URL
ARG PYTHON_SETUP_URL
ARG WINE_VERSION

LABEL org.opencontainers.image.title="metatrader5-docker"
LABEL org.opencontainers.image.description="MetaTrader 5 with Wine and KasmVNC"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.version="${VERSION}"

ENV TITLE=MetaTrader5 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    WINEDEBUG=-all \
    WINEARCH=win64 \
    WINEDLLOVERRIDES=winemenubuilder.exe=d \
    WINEPREFIX=/config/.wine \
    MT5_INSTALLER_DIR=/opt/installers \
    WINE_GECKO_DIR=/opt/wine-offline/gecko \
    WINE_MONO_DIR=/opt/wine-offline/mono \
    MT5_SETUP_URL=${MT5_SETUP_URL} \
    PYTHON_SETUP_URL=${PYTHON_SETUP_URL} \
    MT5_CMD_OPTIONS=

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        gnupg2 \
        git \
        gosu \
        locales \
        p7zip-full \
        sudo \
        tzdata \
        xvfb \
        xauth \
        cabextract \
        winbind \
        procps \
        psmisc \
        unzip \
        zenity \
    && mkdir -pm755 /etc/apt/keyrings \
    && wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
    && wget -O /etc/apt/sources.list.d/winehq-bookworm.sources https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources \
    && apt-get update \
    && apt-get install -y --install-recommends \
        "winehq-stable=${WINE_VERSION}" \
        "wine-stable=${WINE_VERSION}" \
        "wine-stable-amd64=${WINE_VERSION}" \
        "wine-stable-i386:i386=${WINE_VERSION}" \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen \
    && mkdir -p /opt/installers /opt/wine-offline/gecko /opt/wine-offline/mono /config \
    && mkdir -p /usr/share/wine \
    && rm -rf /usr/share/wine/gecko /usr/share/wine/mono \
    && ln -sfn /opt/wine-offline/gecko /usr/share/wine/gecko \
    && ln -sfn /opt/wine-offline/mono /usr/share/wine/mono \
    && rm -rf /var/lib/apt/lists/*

COPY scripts /scripts
COPY root /

RUN chmod +x /scripts/build/install-mt5.sh \
    /scripts/build/download-offline-assets.sh \
    /scripts/build/install-python.sh \
    /scripts/runtime/bootstrap-prefix.sh \
    /scripts/runtime/start-mt5.sh \
    /scripts/runtime/healthcheck.sh \
    && /scripts/build/download-offline-assets.sh

EXPOSE 3000
VOLUME /config

HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
  CMD /scripts/runtime/healthcheck.sh
