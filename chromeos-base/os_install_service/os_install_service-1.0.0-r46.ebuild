# Copyright 2021 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="759635cf334285c52b12a0ebd304988c4bb1329f"
CROS_WORKON_TREE="323bc650914026dc9e78ade7984d631816f0dfba"
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_SUBTREE="os_install_service"

inherit cros-workon cros-rust tmpfiles

LICENSE="BSD-Google"
SLOT="0/${PVR}"
KEYWORDS="*"
IUSE="test"

DEPEND="
	dev-rust/third-party-crates-src:=
	chromeos-base/system_api:=
	dev-rust/libchromeos:=
	sys-apps/dbus:=
"

RDEPEND="
	chromeos-base/chromeos-installer
	sys-apps/util-linux
	sys-block/parted
"

src_install() {
	insinto /etc/dbus-1/system.d
	doins conf/org.chromium.OsInstallService.conf

	insinto /usr/share/policy
	newins "conf/os_install_service-seccomp-${ARCH}.policy" os_install_service-seccomp.policy

	insinto /etc/init
	doins conf/os_install_service.conf

	newtmpfiles conf/tmpfiles.conf os_install_service.conf

	dosbin "$(cros-rust_get_build_dir)/is_running_from_installer"
	dosbin "$(cros-rust_get_build_dir)/os_install_service"
}
