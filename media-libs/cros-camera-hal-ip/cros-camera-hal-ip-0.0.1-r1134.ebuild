# Copyright 2019 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=5

CROS_WORKON_COMMIT="759635cf334285c52b12a0ebd304988c4bb1329f"
CROS_WORKON_TREE=("f91b6afd5f2ae04ee9a2c19109a3a4a36f7659e6" "6c6fe21162ea08ec90c2c7d7674913fa726d72af" "38016702d21dcec0490adde4f421d4056f5bf51b" "13a1732d79ff7a78aec895914901f7207cb5770c" "152f7a4c3a86075c9718b0df309dda5757ae3bfe" "a9a0ffa59bdd3d5f4dbcef883804d59c3b909b69" "5e629c67fd59365eaddcda399ebb829ff0360349" "5fc655a864e89f331445ad76c757c117f451092b" "c5a3f846afdfb5f37be5520c63a756807a6b31c4")
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_LOCALNAME="../platform2"
CROS_WORKON_SUBTREE=".gn camera/build camera/common camera/hal/ip camera/hal/usb camera/include camera/mojo chromeos-config common-mk"
CROS_WORKON_OUTOFTREE_BUILD="1"
CROS_WORKON_INCREMENTAL_BUILD="1"

PLATFORM_SUBDIR="camera/hal/ip"

inherit cros-camera cros-workon platform

DESCRIPTION="Chrome OS IP camera HAL v3."

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
RDEPEND="
	chromeos-base/chromeos-config-tools
	chromeos-base/cros-camera-android-deps
	chromeos-base/cros-camera-libs
	media-libs/libsync"

DEPEND="${RDEPEND}
	virtual/pkgconfig"

platform_pkg_test() {
	platform test_all
}
