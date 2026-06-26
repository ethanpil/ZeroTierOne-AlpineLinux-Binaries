#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: build-apk.sh --version <tag> --arch <x86|x86_64|aarch64> --out-dir <directory> [--alpine-version <tag>]
EOF
}

version=
arch=
out_dir=
alpine_version=3.20

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version)
      version="${2:-}"
      shift 2
      ;;
    --arch)
      arch="${2:-}"
      shift 2
      ;;
    --out-dir)
      out_dir="${2:-}"
      shift 2
      ;;
    --alpine-version)
      alpine_version="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "${version}" ] || [ -z "${arch}" ] || [ -z "${out_dir}" ]; then
  usage >&2
  exit 1
fi

case "${arch}" in
  x86)
    docker_platform=linux/386
    ;;
  x86_64)
    docker_platform=linux/amd64
    ;;
  aarch64)
    docker_platform=linux/arm64
    ;;
  *)
    echo "Unsupported architecture: ${arch}" >&2
    exit 1
    ;;
esac

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir="$(mktemp -d /tmp/zerotier-apk-build.XXXXXX)"
trap 'rm -rf "${work_dir}"' EXIT

mkdir -p "${out_dir}" "${work_dir}/packages"

/bin/bash "${repo_root}/scripts/render-apkbuild.sh" \
  --version "${version}" \
  --arch "${arch}" \
  --work-dir "${work_dir}"

docker run --rm \
  --platform "${docker_platform}" \
  -v "${work_dir}:/work" \
  "alpine:${alpine_version}" \
  /bin/sh -euxc '
    apk add --no-cache alpine-sdk bash build-base curl linux-headers openssl-dev tar xz
    addgroup -S abuild >/dev/null 2>&1 || true
    adduser -D -h /work/home -G abuild builder
    chown -R builder:abuild /work
    su builder -c "abuild-keygen -n"
    su builder -c "cd /work && abuild -F -P /work/packages"
  '

find "${work_dir}/packages" -type f -name '*.apk' -print0 |
  while IFS= read -r -d '' apk; do
    apk_name="$(basename "${apk%.apk}")-${arch}.apk"
    cp "${apk}" "${out_dir}/${apk_name}"
  done

find "${work_dir}/home/.abuild" -type f -name '*.pub' -print0 |
  while IFS= read -r -d '' pubkey; do
    cp "${pubkey}" "${out_dir}/zerotier-one-${arch}.rsa.pub"
  done
