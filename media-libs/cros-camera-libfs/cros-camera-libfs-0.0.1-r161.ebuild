# Copyright 2021 The ChromiumOS Authors
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

EAPI=7

CROS_WORKON_COMMIT="759635cf334285c52b12a0ebd304988c4bb1329f"
CROS_WORKON_TREE=("f91b6afd5f2ae04ee9a2c19109a3a4a36f7659e6" "6c6fe21162ea08ec90c2c7d7674913fa726d72af" "ee46c272200c3bb842d0288afb22d9ebb36f02f7" "c5a3f846afdfb5f37be5520c63a756807a6b31c4")
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_LOCALNAME="../platform2"
CROS_WORKON_SUBTREE=".gn camera/build camera/libfs common-mk"
CROS_WORKON_OUTOFTREE_BUILD="1"
CROS_WORKON_INCREMENTAL_BUILD="1"

PLATFORM_SUBDIR="camera/libfs"

inherit cros-camera cros-workon platform unpacker

DESCRIPTION="Camera Libraries File System which installs the prebuilt libraries."

IUSE="
	camera_feature_auto_framing
	camera_feature_face_detection
	camera_feature_hdrnet
	camera_feature_portrait_mode
	ondevice_document_scanner
	ondevice_document_scanner_dlc
"

# Auto face framing depends on the face detection feature.
REQUIRED_USE="
	camera_feature_auto_framing? ( camera_feature_face_detection )
	?? ( ondevice_document_scanner ondevice_document_scanner_dlc )
"

LOCAL_MIRROR="gs://chromeos-localmirror/distfiles"
PACAKGE_AUTOFRAMING="chromeos-camera-libautoframing-2022.09.06.tbz2"
PACKAGE_DOCUMENT_SCANNING_PV="1.0.0"
PACAKGE_FACESSD="chromeos-facessd-lib-2021.10.27.tar.bz2"
PACKAGE_GCAM="chromeos-camera-libgcam-2023.01.11.tar.zst"
PACKAGE_PORTRAIT_PROCESSOR_AMD64="portrait-processor-lib-x86_64-2023.03.14.tar.zst"
PACKAGE_PORTRAIT_PROCESSOR_ARM="portrait-processor-lib-armv7-2023.03.14.tar.zst"

SRC_URI="
		camera_feature_auto_framing? (
				${LOCAL_MIRROR}/${PACAKGE_AUTOFRAMING}
		)
		${LOCAL_MIRROR}/${PACAKGE_FACESSD}
		camera_feature_hdrnet? (
				${LOCAL_MIRROR}/${PACKAGE_GCAM}
		)
		camera_feature_portrait_mode? (
				amd64? (
						${LOCAL_MIRROR}/${PACKAGE_PORTRAIT_PROCESSOR_AMD64}
				)
				arm? (
						${LOCAL_MIRROR}/${PACKAGE_PORTRAIT_PROCESSOR_ARM}
				)
		)
		$(cros-camera_generate_document_scanning_package_SRC_URI ${PACKAGE_DOCUMENT_SCANNING_PV})
"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="*"

RDEPEND="
	!media-libs/cros-camera-document-scanning
	!media-libs/cros-camera-effect-portrait-mode
	!media-libs/cros-camera-facessd
	!media-libs/cros-camera-libautoframing
	!media-libs/cros-camera-libgcam
"

src_unpack() {
	unpacker
	platform_src_unpack
	# Override unpacked data by files/* for local development.
	if [[ "${PV}" == "9999" ]]; then
		cp -r "${FILESDIR}"/* "${WORKDIR}"
	fi
}

install_lib() {
	local lib_src_path="$1"
	local so_files_path="$2"
	shift 2

	local lib_name=$(basename "${lib_src_path}")

	# For building binary, but won't be installed into the image.
	insinto /build/share/cros_camera
	doins "${lib_src_path}"

	# Put into the squashfs image without debug symbols.
	$(tc-getSTRIP) -s "${lib_src_path}" -o "${so_files_path}/${lib_name}"
}

src_install() {
	platform_src_install

	insinto /etc/init
	doins init/cros-camera-libfs.conf

	local arch_march=$(cros-camera_get_arch_march_path)

	local so_files_path="${WORKDIR}/camera_libs"
	mkdir -p "${so_files_path}"

	local camera_g3_libs_path="${WORKDIR}/g3_libs.squash"

	# Move the required .so into the folder to prepare for compression.
	if use camera_feature_auto_framing; then
		install_lib "${WORKDIR}/libautoframing_cros.so" "${so_files_path}"
	fi
	if use ondevice_document_scanner; then
		install_lib "${WORKDIR}/libdocumentscanner.so" "${so_files_path}"
	fi
	install_lib "${WORKDIR}/${arch_march}/libfacessd_cros.so" "${so_files_path}"
	if use camera_feature_hdrnet && (use march_skylake || use march_alderlake || use amd64); then
		install_lib "${WORKDIR}/${arch_march}/libgcam_cros.so" "${so_files_path}"
	fi
	if use camera_feature_portrait_mode; then
		install_lib "${WORKDIR}/libportrait_cros.so" "${so_files_path}"
	fi

	# Compress the .so files to a single .squash file and install it.
	mksquashfs "${so_files_path}" "${camera_g3_libs_path}" \
			-all-root -noappend -no-recovery -no-exports -exit-on-error \
			-no-progress -4k-align \
			-b 1M \
			-root-mode 0755
	insinto /usr/share/cros-camera
	doins "${camera_g3_libs_path}"
	keepdir /usr/share/cros-camera/libfs

	# For Document Scanning
	insinto /usr/include/chromeos/libdocumentscanner/
	doins "${WORKDIR}"/document_scanner.h

	insinto /usr/include/cros-camera
	doins "${WORKDIR}"/*.h

	# Install model file and anchor file
	insinto /usr/share/cros-camera/ml_models
	doins "${WORKDIR}"/*.pb "${WORKDIR}"/*.tflite
}
