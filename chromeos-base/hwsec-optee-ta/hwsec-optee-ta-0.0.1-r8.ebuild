# Copyright 2023 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT=("759635cf334285c52b12a0ebd304988c4bb1329f" "302248e3d8bd39059235b827055195156bbb8175")
CROS_WORKON_TREE=("7ebcf45cbdad04e67d178c51e512d50d30933695" "0863f39408a3f136f0c594aa4df8ba5ad34aedec")
CROS_WORKON_LOCALNAME=("platform2" "third_party/tpm2")
CROS_WORKON_PROJECT=("chromiumos/platform2" "chromiumos/third_party/tpm2")
CROS_WORKON_SUBTREE=("hwsec-optee-ta" "")
CROS_WORKON_DESTDIR=("${S}/platform2" "${S}/third_party/tpm2")

inherit cros-workon coreboot-sdk

DESCRIPTION="Trusted Application for HWSec for Op-Tee on ARM"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"
IUSE="coreboot-sdk"

RDEPEND="chromeos-base/optee_client"

DEPEND="
	${RDEPEND}
	sys-firmware/optee_os_tadevkit
"

# Make sure we don't use SDK gcc anymore.
REQUIRED_USE="coreboot-sdk"

src_configure() {
	export OPTEE_DIR="${SYSROOT}/build/share/optee"
	export PLATFORM=mediatek-mt8195
	export CROSS_COMPILE64=${COREBOOT_SDK_PREFIX_arm64}
	export CROSS_COMPILE_core=${COREBOOT_SDK_PREFIX_arm64}
	export TA_DEV_KIT_DIR=${OPTEE_DIR}/export-ta_arm64
	export TA_OUTPUT_DIR="${WORKDIR}/out"

	# CFLAGS/CXXFLAGS/CPPFLAGS/LDFLAGS are set for userland, but those options
	# don't apply properly to firmware so unset them.
	unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
}

src_compile() {
	emake -C "${S}/platform2/hwsec-optee-ta"
}

src_install() {
	insinto /lib/optee_armtz
	doins "${WORKDIR}/out/ed800e33-3c58-4cae-a7c0-fd160e35e00d.ta"
}
