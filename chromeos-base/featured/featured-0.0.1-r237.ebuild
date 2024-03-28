# Copyright 2021 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="759635cf334285c52b12a0ebd304988c4bb1329f"
CROS_WORKON_TREE=("c5a3f846afdfb5f37be5520c63a756807a6b31c4" "7a8c6512524978eb836927aaca8cfdef254c564d" "f91b6afd5f2ae04ee9a2c19109a3a4a36f7659e6")
CROS_WORKON_INCREMENTAL_BUILD="1"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_SUBTREE="common-mk featured .gn"

PLATFORM_SUBDIR="featured"

inherit cros-workon platform tmpfiles user

DESCRIPTION="Chrome OS feature management service"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/featured/"
LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="test"

COMMON_DEPEND="
	chromeos-base/bootlockbox-client:=
	dev-libs/openssl:="

RDEPEND="
	${COMMON_DEPEND}"

DEPEND="
	${COMMON_DEPEND}
	chromeos-base/session_manager-client:=
	chromeos-base/system_api:=
	sys-apps/dbus:="

src_install() {
	platform_src_install

	into /
	dosbin "${OUT}"/featured

	insinto "/usr/$(get_libdir)/pkgconfig"
	dolib.so "${OUT}/lib/libfeatures.so"
	dolib.so "${OUT}/lib/libfeatures_c.so"
	dolib.so "${OUT}/lib/libfake_platform_features.so"
	dolib.so "${OUT}/lib/libc_fake_feature_library.so"
	local v="$(libchrome_ver)"
	./platform2_preinstall.sh "${OUT}" "${v}"
	doins "${OUT}/lib/libfeatures.pc"
	doins "${OUT}/lib/libfeatures_c.pc"

	insinto "/usr/include/featured"
	doins feature_export.h
	doins c_feature_library.h
	doins feature_library.h
	doins c_fake_feature_library.h
	doins fake_platform_features.h

	# Install DBus configuration.
	insinto /etc/dbus-1/system.d
	doins share/org.chromium.featured.conf

	insinto /etc/init
	doins share/featured.conf share/featured-chrome-restart.conf

	dodir /etc/featured
	insinto /etc/featured
	fperms 0764 /etc/featured
	doins share/platform-features.json

	dotmpfiles tmpfiles.d/featured.conf

	local fuzzer_component_id="1096648"
	platform_fuzzer_install "${S}"/OWNERS \
			"${OUT}"/featured_json_feature_parser_fuzzer \
			--comp "${fuzzer_component_id}"
}

platform_pkg_test() {
	platform_test "run" "${OUT}/feature_library_test"
	platform_test "run" "${OUT}/hmac_test"
	platform_test "run" "${OUT}/service_test"
	platform_test "run" "${OUT}/store_impl_test"
}
