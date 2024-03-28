# Copyright 2022 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="modem logging blobs from fibocom"

LICENSE="BSD-Fibocom"
SLOT="0"
KEYWORDS="*"
IUSE=""

MIRROR_PATH="gs://chromeos-localmirror/distfiles"
SRC_URI="${MIRROR_PATH}/fibocomtools-${PV}.tar.xz"

S=${WORKDIR}

src_install() {
	insinto "/opt/fibocom/"
	doins -r "${WORKDIR}/fibocomtools"
}
