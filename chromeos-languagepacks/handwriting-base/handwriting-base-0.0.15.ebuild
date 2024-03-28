# Copyright 2022 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit dlc

# This ebuild is referring to the same resource as package:
# src/third_party/chromiumos-overlay/dev-libs/libhandwriting/
# We keep two ebuilds while we migrate from nacl to Language Packs.

DESCRIPTION="Handwriting Library used by Language Pack for Chromium OS"

SRC_URI="gs://chromeos-localmirror/distfiles/libhandwriting-${PV}.tar.gz"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"

IUSE="dlc ondevice_handwriting"
REQUIRED_USE="dlc ondevice_handwriting"

# DLC variables.
# Allocate 4KB * 7500 = 30MB
DLC_PREALLOC_BLOCKS="7500"

# Enable scaled design.
DLC_SCALED=true

S="${WORKDIR}"

src_install() {
	# This DLC is enabled only if ondevice handwriting is enabled.
	if ! use ondevice_handwriting; then
		return
	fi

	# Setup DLC paths. We don't need any subdirectory inside the DLC path.
	insinto "$(dlc_add_path /)"

	# Install handwriting library.
	insopts -m0755
	newins "libhandwriting-${ARCH}.so" "libhandwriting.so"
	insopts -m0644

	# This command packages the files into a DLC.
	dlc_src_install
}
