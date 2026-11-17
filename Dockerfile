FROM mcr.microsoft.com/devcontainers/python:1-3.13

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN rm -f /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        bluez \
        libffi-dev \
        libssl-dev \
        libjpeg-dev \
        zlib1g-dev \
        autoconf \
        build-essential \
        libopenjp2-7 \
        libtiff6 \
        libturbojpeg0-dev \
        tzdata \
        ffmpeg \
        liblapack3 \
        liblapack-dev \
        libatlas-base-dev \
        git \
        libpcap-dev \
        unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && source /usr/local/share/nvm/nvm.sh \
    && nvm install --lts \
    # Node.js 25+ no longer bundles corepack; install it so projects pinning
    # "packageManager" (e.g. yarn 4) keep working
    && npm install -g corepack \
    && corepack enable \
    # nvm installed Node as root; let the nvm group (which includes vscode)
    # write to it so `npm install -g` and `corepack enable` work as vscode
    && chgrp -R nvm "${NVM_DIR}" \
    && chmod -R g+rwX "${NVM_DIR}" \
    && find "${NVM_DIR}" -type d -exec chmod g+s {} + \
    && pip install --upgrade wheel pip uv

COPY --from=ghcr.io/alexxit/go2rtc:latest /usr/local/bin/go2rtc /bin/go2rtc

EXPOSE 8123

# Default HASS_CONFIG_DIR. Owned by vscode so `container setup` works as the
# remote user. Not a VOLUME: projects can mount it or set HASS_CONFIG_DIR, and
# declaring it left an unused anonymous volume behind for every container.
RUN mkdir -p /config/www \
    && chown -R vscode:vscode /config

USER vscode
ENV VIRTUAL_ENV="/home/vscode/.local/ha-venv"
RUN uv venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY requirements.txt /tmp/requirements.txt
RUN uv pip install -r /tmp/requirements.txt

COPY --chmod=0755 container /usr/local/bin/container
COPY --chmod=0755 hassfest /usr/local/bin/hassfest

CMD ["sudo", "-E", "container"]
