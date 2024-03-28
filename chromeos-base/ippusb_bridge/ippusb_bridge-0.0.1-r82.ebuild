# Copyright 2020 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="759635cf334285c52b12a0ebd304988c4bb1329f"
CROS_WORKON_TREE="5a13b63a8f4febdce19074556742946cb2a72d86"
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_SUBTREE="ippusb_bridge"

inherit cros-workon cros-rust udev user

DESCRIPTION="A proxy for HTTP traffic over an IPP-USB printer connection"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/ippusb_bridge/"

LICENSE="BSD-Google"
SLOT="0/0"
KEYWORDS="*"
IUSE=""

COMMON_DEPEND="
	virtual/libusb:1=
"

RDEPEND="
	${COMMON_DEPEND}
	!chromeos-base/ippusb_manager
"

DEPEND="
	${COMMON_DEPEND}
	dev-rust/third-party-crates-src:=
	dev-rust/libchromeos:=
	dev-rust/sync:=
	virtual/libusb:1
"

pkg_preinst() {
	enewgroup ippusb
	enewuser ippusb

	cros-rust_pkg_preinst
}

src_install() {
	dobin "$(cros-rust_get_build_dir)"/ippusb_bridge

	# install tmpfiles.d
	insinto /usr/lib/tmpfiles.d/on-demand/
	newins "tmpfiles.d/on-demand/ippusb-bridge.conf" "ippusb-bridge.conf"

	# Install policy files.
	insinto /usr/share/policy
	newins "seccomp/ippusb-bridge-seccomp-${ARCH}.policy" \
		ippusb-bridge-seccomp.policy

	udev_dorules udev/*.rules

	insinto /etc/init
	newins "init/ippusb-bridge.conf" "ippusb-bridge.conf"
	newins "init/printscan-debug-cleanup.conf" "printscan-debug-cleanup.conf"

	insinto /usr/share/ippusb_bridge
	newins "init/ippusb-bridge-debug.conf" "ippusb-bridge-debug.conf"

	exeinto /usr/libexec/ippusb
	doexe "init/bridge_start"
	doexe "init/bridge_stop"
}
