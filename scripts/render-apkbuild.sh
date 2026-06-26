#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: render-apkbuild.sh --version <tag> --arch <x86|x86_64|aarch64> --work-dir <directory>
EOF
}

version=
arch=
work_dir=

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
    --work-dir)
      work_dir="${2:-}"
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

if [ -z "${version}" ] || [ -z "${arch}" ] || [ -z "${work_dir}" ]; then
  usage >&2
  exit 1
fi

case "${arch}" in
  x86|x86_64|aarch64)
    ;;
  *)
    echo "Unsupported architecture: ${arch}" >&2
    exit 1
    ;;
esac

mkdir -p "${work_dir}"

source_url="https://github.com/zerotier/ZeroTierOne/archive/refs/tags/${version}.tar.gz"
if ! source_sha512="$(curl -fsSL "${source_url}" | sha512sum | awk '{print $1}')"; then
  echo "Failed to download ${source_url}" >&2
  exit 1
fi

cat >"${work_dir}/APKBUILD" <<EOF
pkgname=zerotier-one
pkgver=${version}
pkgrel=0
pkgdesc="ZeroTier One virtual Ethernet switch"
url="https://github.com/zerotier/ZeroTierOne"
arch="${arch}"
license="MPL-2.0 AND LicenseRef-ZeroTier-Source-Available-1.0"
depends="libstdc++"
makedepends="build-base linux-headers openssl-dev"
source="\${pkgname}-\${pkgver}.tar.gz::${source_url}"
builddir="\${srcdir}/ZeroTierOne-\${pkgver}"
sha512sums="${source_sha512}  \${pkgname}-\${pkgver}.tar.gz"

build() {
	make
}

check() {
	make selftest
	./zerotier-selftest
}

package() {
	install -Dm755 zerotier-one "\${pkgdir}/usr/sbin/zerotier-one"
	install -Dm755 zerotier-cli "\${pkgdir}/usr/bin/zerotier-cli"
	install -Dm755 zerotier-idtool "\${pkgdir}/usr/bin/zerotier-idtool"
	install -Dm644 LICENSE-MPL.txt "\${pkgdir}/usr/share/licenses/\${pkgname}/LICENSE-MPL.txt"
	install -Dm644 nonfree/LICENSE.md "\${pkgdir}/usr/share/licenses/\${pkgname}/LICENSE-Source-Available.md"
}
EOF
