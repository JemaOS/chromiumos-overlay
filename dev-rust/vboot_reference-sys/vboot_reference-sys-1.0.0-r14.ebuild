# Copyright 2022 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="6d1c48e3179056d965edfdd630a9dd6cda12f14b"
CROS_WORKON_TREE=("e544519b416b85d02bc2281f5765f8f905b63ae9" "8aad1415bc8edb5dd4fbbff205b67e7b6453d708")
inherit cros-constants

CROS_RUST_SUBDIR="rust/vboot_reference-sys"

CROS_WORKON_PROJECT="chromiumos/platform/vboot_reference"
CROS_WORKON_LOCALNAME="../platform/vboot_reference"
CROS_WORKON_SUBTREE="host/include rust/vboot_reference-sys"

inherit cros-workon cros-rust

DESCRIPTION="Chrome OS verified boot tools Rust bindings"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform/vboot_reference/+/HEAD/rust"

LICENSE="BSD-Google"
KEYWORDS="*"

# ebuilds that install executables and depend on vboot_reference-sys need to
# RDEPEND on chromeos-base/vboot_reference
DEPEND="
	dev-rust/third-party-crates-src:=
	chromeos-base/vboot_reference:=
	virtual/bindgen:=
"
# (crbug.com/1182669): build-time only deps need to be in RDEPEND so they are pulled in when
# installing binpkgs since the full source tree is required to use the crate.
RDEPEND="${DEPEND}"
