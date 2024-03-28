# Copyright 2020 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="759635cf334285c52b12a0ebd304988c4bb1329f"
CROS_WORKON_TREE=("c5a3f846afdfb5f37be5520c63a756807a6b31c4" "58b24ad9dd2de7e6ec5810d918462e919b3a889f" "f91b6afd5f2ae04ee9a2c19109a3a4a36f7659e6")
CROS_WORKON_INCREMENTAL_BUILD="1"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_SUBTREE="common-mk cfm-dfu-notification .gn"
CROS_WORKON_DESTDIR="${S}/platform2"

PLATFORM_SUBDIR="cfm-dfu-notification"

inherit cros-workon platform

DESCRIPTION="Library to send firmware update notifications to CFM"

LICENSE="BSD-Google"
SLOT="0/0"
KEYWORDS="*"

RDEPEND=""
DEPEND="${RDEPEND}"

src_install() {
	platform_src_install

	dolib.so "${OUT}"/lib/libcfm_dfu_notification.so

	"${S}"/platform2_preinstall.sh "${PV}" "/usr/include/chromeos" "${OUT}"
	insinto "/usr/$(get_libdir)/pkgconfig"
	doins "${OUT}"/cfm-dfu-notification.pc

	insinto "/usr/include/chromeos/cfm-dfu-notification"
	doins ./*.h
}

platform_pkg_test() {
	platform_test "run" "${OUT}"/cfm_dfu_notification_test
}
