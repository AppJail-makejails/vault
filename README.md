# Vault

Vault is a tool for securely accessing secrets. A secret is anything that you want to tightly control access to, such as API keys, passwords, certificates, and more. Vault provides a unified interface to any secret, while providing tight access control and recording a detailed audit log.

developer.hashicorp.com/vault

<img src="https://camo.githubusercontent.com/2b69c33ac7e9cbe082e3bac66eea6346cc0804c8995e7d799067f0fc29bcba7e/68747470733a2f2f7777772e6861736869636f72702e636f6d2f5f6e6578742f7374617469632f6d656469612f7661756c745f6f6e2d6461726b2e39373739326636342e737667" width="30%" height="auto" alt="Vault logo">

## How to use this Makejail

Running the Vault container with no arguments will give you a Vault server in [development mode](https://www.vaultproject.io/docs/concepts/dev-server.html). The provided entry point script will also look for Vault subcommands and run `vault` with that subcommand. For example, you can execute `appjail oci run ghcr.io/appjail-makejails/vault vault version` and it will run the `vault version` command inside the container. The entry point also adds some special configuration options as detailed in the sections below when running the server subcommand. Any other command gets exec-ed inside the container.

The container exposes two optional `VOLUME`s:

* `/vault/logs`, to use for writing persistent audit logs. By default nothing is written here; the `file` audit backend must be enabled with a path under this directory.
* `/vault/file`, to use for writing persistent storage data when using the `file` data storage plugin. By default nothing is written here (a `dev` server uses an in-memory data store); the `file` data storage backend must be enabled in Vault's configuration before the container is started

The container has a Vault configuration directory set up at `/vault/config` and the server will load any HCL or JSON configuration files placed here by binding a volume or by composing a new image and adding files. Alternatively, configuration can be added by passing the configuration JSON via environment variable `VAULT_LOCAL_CONFIG`.

### Memory Locking

You can use the following template, although the default one will work as expected:

**template.conf**:

```
exec.start: "/bin/sh /etc/rc"
exec.stop: "/bin/sh /etc/rc.shutdown jail"
mount.devfs
persist
allow.mlock
```

By default, mlock support is enabled, but it may not work on your system unless you set `vm.old_mlock` to `1`. If you do not want to do this, set `vault_disable_mlock` to `1`. See also: https://github.com/hashicorp/vault/issues/6340#issuecomment-472169916

### Running Vault for Development

```console
$ appjail oci run -Pd \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o template=template.conf \
    ghcr.io/appjail-makejails/vault vault
```

This runs a completely in-memory Vault server, which is useful for development but should not be used in production.

When running in development mode, two additional options can be set via environment variables:

* `VAULT_DEV_ROOT_TOKEN_ID`: This sets the ID of the initial generated root token to the given value.
* `VAULT_DEV_LISTEN_ADDRESS`: This sets the IP:port of the development server listener (defaults to `0.0.0.0:8200`).

As an example:

```console
$ appjail oci run -Pd \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o template=template.conf \
    -e VAULT_DEV_ROOT_TOKEN_ID=myroot -e VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:1234 \
    ghcr.io/appjail-makejails/vault vault
```

### Running Vault in Server Mode for Development

```console
$ appjail oci run -Pd \
    -o overwrite=force \
    -o virtualnet=":<random> default" \
    -o nat \
    -o template=template.conf \
    -e 'VAULT_LOCAL_CONFIG={"storage": {"file": {"path": "/vault/file"}}, "listener": [{"tcp": {"tls_disable": true}}], "default_lease_ttl": "168h", "max_lease_ttl": "720h", "ui": true}' \
    ghcr.io/appjail-makejails/vault vault
```

This runs a Vault server with TLS disabled, the `file` storage backend at path `/vault/file` and a default secret lease duration of one week and a maximum of 30 days. Disabling TLS and using the `file` storage backend are not recommended for production use.

At startup, the server will read configuration HCL and JSON files from `/vault/config` (any information passed into `VAULT_LOCAL_CONFIG` is written into `local.json` in this directory and read as part of reading the directory for configuration files). Please see Vault's [configuration documentation](https://www.vaultproject.io/docs/config/index.html) for a full list of options.

We suggest volume mounting a directory into the container in order to give both the configuration and TLS certificates to Vault. You can accomplish this with:

```console
$ appjail oci run -Pd -o fstab="/path/to/your/vault/config /vault/config" ...
```

For more scalability and reliability, we suggest running containerized Vault in an orchestration environment like [Overlord](https://github.com/DtxdF/overlord).

This image also supports `VAULT_REDIRECT_INTERFACE` and `VAULT_CLUSTER_INTERFACE` environment variables. If set, the IP addresses used for the redirect and cluster addresses in Vault's configuration will be the address of the named interface inside the container (e.g. `em0`).

### Arguments (stage: build)

* `vault_from` (default: `ghcr.io/appjail-makejails/vault`): Location of OCI image. See also [OCI Configuration](#oci-configuration).
* `vault_tag` (default: `latest`): OCI image tag. See also [OCI Configuration](#oci-configuration).

### Environment (OCI image)

* `PGID` (default: `1000`): Equivalent to `PUID` but for the Process Group ID.
* `PUID` (default: `1000`): Process User ID for the container's main process, allowing you to match the owner of files written to mounted host volumes to your host system's user. Writable volumes are changed based on this environment variable.

### Volumes

| Name | Owner | Group | Perm | Type | Mountpoint |
| --- | --- | --- | --- | --- | --- |
| appjail-2593dce56c-vault_file | `${PUID}` | `${PGID}` | - | - | /vault/file |
| appjail-b4ff4e0600-vault_logs | `${PUID}` | `${PGID}` | - | - | /vault/logs |

## OCI Configuration

```yaml
build:
  variants:
    - tag: 15.1
      containerfile: Containerfile
      aliases: ["latest"]
      default: true
      args:
        FREEBSD_RELEASE: "15.1"
        NO_PKGCLEAN: "1"
      cache_dirs: ["pkgcache0:/var/cache/pkg"]
```

## Notes

1. The ideas present in the Docker image of Vault are taken into account for users who are familiar with it.
2. `listener` isn't specified because it has already been specified from the CLI. See https://github.com/hashicorp/docker-vault/issues/7 and https://github.com/hashicorp/docker-vault/issues/109 for details.
