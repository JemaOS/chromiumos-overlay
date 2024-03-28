# Copyright 2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="759635cf334285c52b12a0ebd304988c4bb1329f"
CROS_WORKON_TREE="0f736b8808c2c5938db35bb9ecaf60840884b976"
CROS_RUST_SUBDIR="sirenia/manatee-runtime"

CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_SUBTREE="${CROS_RUST_SUBDIR}"

inherit cros-workon cros-rust

DESCRIPTION="Library for TEE apps to interact with sirenia."
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/sirenia/manatee-runtime/"

LICENSE="BSD-Google"
SLOT="0/${PVR}"
KEYWORDS="*"
IUSE="cros_host manatee"

DEPEND="
	dev-rust/third-party-crates-src:=
	chromeos-base/libsirenia:=
	dev-rust/libchromeos:=
	dev-rust/sync:=
"
RDEPEND="${DEPEND}"

BDEPEND="chromeos-base/sirenia-tools"

src_install() {
	# Install the crate.
	cros-rust_src_install

	# Install demo_app.
	local build_dir="$(cros-rust_get_build_dir)"
	dobin "${build_dir}/demo_app"

	# Install app manifest.
	local APP_MANIFEST="${S}/src/demo-app.json"
	tee_app_info_lint -R "${D}" -c "${APP_MANIFEST}" || die
	insinto /usr/share/manatee/templates
	doins "${APP_MANIFEST}"
}
