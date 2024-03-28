# Copyright 2022 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


EAPI="7"

CROS_WORKON_COMMIT="646236a824b7f417266f4ff4722e3e7895b00af1"
CROS_WORKON_TREE="915540446d927e491cc286ee0ab2786e0ce81f0e"
CROS_RUST_SUBDIR="cras/src/audio_processor"

CROS_WORKON_LOCALNAME="adhd"
CROS_WORKON_PROJECT="chromiumos/third_party/adhd"
# We don't use CROS_WORKON_OUTOFTREE_BUILD here since cras/src/audio_processor is
# using the `provided by ebuild` macro from the cros-rust eclass
CROS_WORKON_SUBTREE="${CROS_RUST_SUBDIR}"

inherit cros-workon cros-rust

DESCRIPTION="Audio processor"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/third_party/adhd/+/HEAD/cras/src/audio_processor"

LICENSE="BSD-Google"
KEYWORDS="*"

DEPEND="dev-rust/third-party-crates-src:="
RDEPEND="${DEPEND}"

src_install() {
	cros-rust_src_install

	# Install to /usr/local so they are stripped out of the release image.
	into /usr/local
	dobin "$(cros-rust_get_build_dir)/offline-pipeline"
}
