ARG FREEBSD_RELEASE

FROM ghcr.io/appjail-makejails/core:${FREEBSD_RELEASE}

ARG NO_PKGCLEAN

LABEL org.opencontainers.image.title="Vault" \
    org.opencontainers.image.description="Tool for securely accessing secrets" \
    org.opencontainers.image.source="https://github.com/AppJail-makejails/vault" \
    org.opencontainers.image.url="https://github.com/AppJail-makejails/vault" \
    org.opencontainers.image.vendor="DtxdF" \
    org.opencontainers.image.authors="Jesús Daniel Colmenares Oviedo <dtxdf@disroot.org>"

RUN set -xe; \
    \
    pkg update; \
    pkg install -U vault bash gawk; \
    \
    if [ -z "${NO_PKGCLEAN}" ]; then \
        pkg clean -a; \
        rm -rf /var/cache/pkg/*; \
    fi; \
    rm -rf /var/db/pkg/repos/*

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh && \
    mkdir -p /vault/logs && \
    mkdir -p /vault/file && \
    mkdir -p /vault/config

VOLUME ["/vault/logs", "/vault/file"]

EXPOSE 8200

ENTRYPOINT ["/entrypoint.sh"]
CMD ["server", "-dev"]
