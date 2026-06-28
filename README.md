# ZeroTierOne Alpine Linux APKs

This repository builds **static** Alpine Linux APK packages for upstream [zerotier/ZeroTierOne](https://github.com/zerotier/ZeroTierOne) releases and publishes them as GitHub release assets in this repository.

## What gets built

The release workflow packages the current upstream ZeroTierOne release (or a manually requested version) for:

- `x86`
- `x86_64`
- `aarch64`
- `arm64` (published as an alias of Alpine's `aarch64` package naming)

Each package contains:

- `/usr/sbin/zerotier-one`
- `/usr/bin/zerotier-cli`
- `/usr/bin/zerotier-idtool`

Release assets are published with architecture-specific filenames such as `zerotier-one-1.16.2-r0-x86_64.apk`.

## Static build confirmation

These packages are produced from source using the upstream `make` flow and this repository is intended to publish **static builds** for Alpine Linux.

> Verify a binary is static after installation:
>
> ```bash
> ldd /usr/sbin/zerotier-one
> ```
>
> A static binary reports `not a dynamic executable`.

## Install on a running Alpine system

1. Download the correct release assets for your architecture from this repository's Releases page:
   - `zerotier-one-<version>-r0-<arch>.apk`
   - `zerotier-one-<arch>.rsa.pub`
2. Add the package signing key:

```bash
sudo install -m 0644 zerotier-one-<arch>.rsa.pub /etc/apk/keys/
```

3. Install the package:

```bash
sudo apk add ./zerotier-one-<version>-r0-<arch>.apk
```

If you do not want to install the key, you can install with:

```bash
sudo apk add --allow-untrusted ./zerotier-one-<version>-r0-<arch>.apk
```

## Runtime configuration and state paths

ZeroTier stores runtime state and identity material under:

- `/var/lib/zerotier-one`

Important files/directories include:

- `/var/lib/zerotier-one/identity.public`
- `/var/lib/zerotier-one/identity.secret`
- `/var/lib/zerotier-one/networks.d/`

## OpenRC service startup (Alpine)

Start the service now:

```bash
sudo rc-service zerotier-one start
```

Enable it at boot:

```bash
sudo rc-update add zerotier-one default
```

Check status:

```bash
sudo rc-service zerotier-one status
```

Then authorize or join networks with `zerotier-cli`, for example:

```bash
sudo zerotier-cli info
sudo zerotier-cli join <network-id>
```

## Automation

The repository uses `.github/workflows/release.yml` to:

1. Resolve the ZeroTierOne version from:
   - the pushed Git tag in this repository, or
   - the `workflow_dispatch` input, or
   - the latest upstream ZeroTierOne release if no version is supplied.
2. Build APKs in Alpine containers for each supported architecture.
3. Run `make` and `make selftest` during packaging.
4. Publish the generated APK files as assets on the matching GitHub release in this repository.

## Triggering a release

### Option 1: push a matching tag

Create and push a tag that matches an upstream ZeroTierOne release, for example:

```bash
git tag 1.16.2
git push origin 1.16.2
```

The workflow verifies that the same tag exists as an upstream ZeroTierOne release before building.

### Option 2: run the workflow manually

From the GitHub Actions UI, run the `build-and-release` workflow and optionally provide a `version` input such as `1.16.2`. If `version` is left blank, the workflow packages the latest upstream release.

## Local build

You can build one architecture locally with Docker:

```bash
./scripts/build-apk.sh --version 1.16.2 --arch x86_64 --out-dir ./dist
```

Supported local `--arch` values are `x86`, `x86_64`, and `aarch64`.
The build script defaults to Alpine 3.23 so the bundled Rust toolchain is new enough for current ZeroTierOne dependencies.

To install a locally built package, either copy the matching `zerotier-one-<arch>.rsa.pub` file into `/etc/apk/keys/` first or install the APK with `apk add --allow-untrusted`.

## Notes

- The workflow follows the upstream ZeroTierOne source build flow (`make` plus `make selftest`) and wraps it in Alpine APK packaging.
- Alpine 3.23 or newer is required because current ZeroTierOne Rust dependencies need at least Rust 1.88.
- Alpine's 64-bit ARM architecture name is `aarch64`; the workflow also uploads an `arm64`-named release asset for convenience.
