# Copyright 2022 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

EAPI=7

inherit toolchain-funcs

DESCRIPTION="Tool for inspection and simple manipulation of eBPF programs and maps"
HOMEPAGE="https://github.com/libbpf/bpftool"
SRC_URI="https://github.com/libbpf/bpftool/archive/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="*"
IUSE="caps"

DEPEND="sys-libs/binutils-libs:=
	sys-libs/zlib:=
	virtual/libelf:=
	caps? ( sys-libs/libcap:= )
"
RDEPEND=${DEPEND}

PATCHES=(
       "${FILESDIR}/0001-remove-compilation-of-skeletons.patch"
)

S=${WORKDIR}/${P}/src

bpftool_make() {
	local arch=$(tc-arch-kernel)
	emake V=1 VF=1 \
		HOSTCC="${BUILD_CC}" HOSTLD="${BUILD_LD}" \
		EXTRA_CFLAGS="${CFLAGS}" ARCH="${arch}" BPFTOOL_VERSION="${PV}" \
		prefix="${EPREFIX}"/usr \
		feature-libcap="$(usex caps 1 0)" \
		"$@"
}

src_configure() {
	tc-export AR LD BUILD_CC BUILD_PKG_CONFIG CC PKG_CONFIG BUILD_LD
}

src_compile() {
	bpftool_make
}

src_install() {
	bpftool_make DESTDIR="${D}" install
}
