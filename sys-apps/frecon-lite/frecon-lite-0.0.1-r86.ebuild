# Copyright 2014 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="e4ff063b3e0cb7c16b09b24d0983bf21b22654c0"
CROS_WORKON_TREE="48b86f9eea5489b0234d6ecfaec2c162bcd3c105"
CROS_WORKON_PROJECT="chromiumos/platform/frecon"
CROS_WORKON_LOCALNAME="../platform/frecon"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_INCREMENTAL_BUILD=1

inherit cros-sanitizers cros-workon cros-common.mk

DESCRIPTION="Chrome OS KMS console (without DBUS/UDEV support)"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform/frecon"

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="-asan"

BDEPEND="virtual/pkgconfig"

COMMON_DEPEND="media-libs/libpng:0=
	sys-apps/libtsm:="

RDEPEND="${COMMON_DEPEND}"

DEPEND="${COMMON_DEPEND}
	media-sound/adhd:=
	x11-libs/libdrm:="

src_configure() {
	export FRECON_LITE=1
	sanitizers-setup-env
	cros-common.mk_src_configure
}
