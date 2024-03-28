# Copyright 2020 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

EAPI=7

CROS_WORKON_COMMIT="37e9941ffa778bef80f56b959cfdf2e7d5008c5b"
CROS_WORKON_TREE="6f55c80867b6a5931cbc26b350a9d5b0e8604030"
CROS_RUST_SUBDIR="sof_sys"

CROS_WORKON_LOCALNAME="adhd"
CROS_WORKON_PROJECT="chromiumos/third_party/adhd"
# We don't use CROS_WORKON_OUTOFTREE_BUILD here since cras-sys/Cargo.toml is
# using "provided by ebuild" macro which supported by cros-rust.
CROS_WORKON_INCREMENTAL_BUILD=1
CROS_WORKON_SUBTREE="${CROS_RUST_SUBDIR}"

inherit cros-workon cros-rust

DESCRIPTION="Crate for SOF C-structures generated by bindgen"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/third_party/adhd/+/HEAD/sof_sys"

SRC_URI=""

LICENSE="BSD-Google"
KEYWORDS="*"
IUSE="test"
