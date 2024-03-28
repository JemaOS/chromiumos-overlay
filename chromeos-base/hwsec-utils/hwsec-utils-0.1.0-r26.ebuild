# Copyright 2022 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

EAPI=7

CROS_WORKON_COMMIT="759635cf334285c52b12a0ebd304988c4bb1329f"
CROS_WORKON_TREE="8e8006c34aeee0ef14f54c630cdcf7a8353cf79d"
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_SUBTREE="hwsec-utils"

inherit cros-workon cros-rust

DESCRIPTION="Hwsec-related features."
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/hwsec-utils/"

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="cr50_onboard test ti50_onboard"
REQUIRED_USE="^^ ( ti50_onboard cr50_onboard )"
CANDIDATES=( "cr50_onboard" "ti50_onboard" )

DEPEND="
	dev-rust/third-party-crates-src:=
	dev-rust/libchromeos:=
"
# (crbug.com/1182669): build-time only deps need to be in RDEPEND so they are pulled in when
# installing binpkgs since the full source tree is required to use the crate.
RDEPEND="${DEPEND}
	cr50_onboard? ( chromeos-base/chromeos-cr50 )
"

src_compile() {
	local features=()

	local candidate
	for candidate in "${CANDIDATES[@]}"; do
		if use "${candidate}"; then
			features+=("${candidate}")
		fi
	done

	cros-rust_src_compile --features="${features[*]}"
}

src_install() {
	cros-rust_src_install

	exeinto /usr/share/cros/hwsec-utils
	files=(
		cr50_flash_log
		cr50_read_rma_sn_bits
		cr50_reset
		cr50_set_board_id
		cr50_set_sn_bits
		cr50_update
		tpm2_read_board_id
	)
	for f in "${files[@]}"; do
		doexe "$(cros-rust_get_build_dir)/${f}"
	done
}

src_test() {
	local candidate
	for candidate in "${CANDIDATES[@]}"; do
		cros-rust_src_test --features="${candidate}"
	done
}
