# Copyright 2017 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7
CROS_WORKON_COMMIT="ebb1ce499fa801866a805e50a2d1d70377245b51"
CROS_WORKON_TREE="ffabb16c97896e3aa777a759c34b9736969e172e"
CROS_WORKON_PROJECT="chromiumos/platform/crosvm"
CROS_WORKON_LOCALNAME="platform/crosvm"
CROS_WORKON_EGIT_BRANCH="chromeos"
CROS_WORKON_INCREMENTAL_BUILD=1

# We don't use CROS_WORKON_OUTOFTREE_BUILD here since crosvm/Cargo.toml is
# using "# ignored by ebuild" macro which supported by cros-rust.

inherit cros-fuzzer cros-rust cros-sanitizers cros-workon user

DESCRIPTION="Utility for running VMs on Chrome OS"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform/crosvm/"

# 'Apache-2.0' and 'BSD-vmm_vhost' are for third_party/vmm_vhost.
LICENSE="BSD-Google Apache-2.0 BSD-vmm_vhost"
KEYWORDS="*"
IUSE="test cros-debug crosvm-gpu crosvm-swap -crosvm-trace-marker -crosvm-plugin +crosvm-power-monitor-powerd +crosvm-video-decoder +crosvm-video-encoder -crosvm-video-ffmpeg +crosvm-video-libvda +crosvm-wl-dmabuf fuzzer tpm2 android-vm-master android-vm-tm arcvm_gce_l1"

BDEPEND="dev-libs/protobuf"
COMMON_DEPEND="
	sys-apps/dtc:=
	sys-libs/libcap:=
	crosvm-video-ffmpeg? ( media-video/ffmpeg )
	crosvm-video-libvda? ( chromeos-base/libvda )
	chromeos-base/minijail:=
	dev-libs/wayland:=
	crosvm-gpu? (
		media-libs/virglrenderer:=
	)
	crosvm-wl-dmabuf? ( media-libs/minigbm:= )
	dev-rust/libchromeos:=
"

RDEPEND="${COMMON_DEPEND}
	!chromeos-base/crosvm-bin
	crosvm-power-monitor-powerd? ( sys-apps/dbus )
	tpm2? ( sys-apps/dbus )
"

DEPEND="${COMMON_DEPEND}
	cros_host? ( dev-libs/protobuf:= )
	dev-rust/third-party-crates-src:=
	dev-libs/wayland-protocols:=
	dev-rust/cros_fuzz:=
	dev-rust/minijail:=
	dev-rust/p9:=
	dev-rust/system_api:=
	media-sound/cras-client:=
	sys-apps/dbus:=
	tpm2? (
		chromeos-base/tpm2:=
		chromeos-base/trunks:=
	)
	crosvm-power-monitor-powerd? (
		chromeos-base/system_api
	)
"

FUZZERS=(
	crosvm_block_fuzzer
	crosvm_fs_server_fuzzer
	crosvm_qcow_fuzzer
	crosvm_usb_descriptor_fuzzer
	crosvm_virtqueue_fuzzer
	crosvm_zimage_fuzzer
)

src_unpack() {
	# Unpack both the project and dependency source code
	cros-workon_src_unpack
	cros-rust_src_unpack
}

src_prepare() {
	cros_optimize_package_for_speed
	cros-rust_src_prepare

	if use arcvm_gce_l1; then
		eapply "${FILESDIR}"/0001-betty-arcvm-Loose-mprotect-mmap-for-software-renderi.patch
	fi

	default
}

src_configure() {
	cros-rust_src_configure

	# Change the path used for the minijail pivot root from /var/empty.
	# See: https://crbug.com/934513
	export DEFAULT_PIVOT_ROOT="/mnt/empty"
}

src_compile() {
	export CROSVM_BUILD_VARIANT="chromeos"

	local features=(
		"audio"
		"balloon"
		"config-file"
		"qcow"
		"usb"
		$(usex crosvm-gpu gpu "")
		$(usex crosvm-gpu virgl_renderer "")
		$(usex crosvm-gpu virgl_renderer_next "")
		$(usex crosvm-plugin plugin "")
		$(usex crosvm-power-monitor-powerd power-monitor-powerd "")
		$(usex crosvm-swap swap "")
		$(usex crosvm-trace-marker trace_marker "")
		$(usex crosvm-video-decoder video-decoder "")
		$(usex crosvm-video-encoder video-encoder "")
		$(usex crosvm-video-libvda libvda "")
		$(usex crosvm-video-ffmpeg ffmpeg "")
		$(usex crosvm-wl-dmabuf wl-dmabuf "")
		$(usex tpm2 tpm "")
		$(usex cros-debug gdb "")
		chromeos
		$(usex android-vm-master composite-disk "")
		$(usex android-vm-tm composite-disk "")
	)

	local packages=(
		qcow_utils
		crosvm
		crosvm_control
	)

	# Remove other versions of crosvm_control so the header installation
	# only picks up the most recently built version.
	# TODO(b/188858559) Remove this once the header is installed directly by cargo
	rm -rf "$(cros-rust_get_build_dir)/build/crosvm_control-*" || die "failed to remove old crosvm_control packages"

	for pkg in "${packages[@]}"; do
		ecargo_build -v \
		 	--no-default-features \
			--features="${features[*]}" \
			-p "${pkg}" ||
			die "cargo build failed"
	done

	if use fuzzer; then
		cd crosvm-fuzz || die "failed to move directory"
		local f
		for f in "${FUZZERS[@]}"; do
			ecargo_build_fuzzer --bin "${f}"
		done
		cd .. || die "failed to move directory"
	fi
}

src_test() {
	export CROSVM_BUILD_VARIANT="chromeos"

	local test_opts=(
		# TODO(b/211023371): Re-enable libvda tests.
		--exclude libvda
		# Disable VAAPI testing as it would require us to depend on libva.
		--exclude libva
	)
	use tpm2 || test_opts+=(--exclude tpm2 --exclude tpm2-sys)
	use crosvm-video-ffmpeg || test_opts+=(--exclude ffmpeg)

	# io_jail tests fork the process, which cause memory leak errors when
	# run under sanitizers.
	cros-rust_use_sanitizers && test_opts+=(--exclude io_jail)

	# kernel versions between 5.1 and 5.10 have io_uring bugs, skip the io_uring
	# integration test on these platforms.  See b/189879899
	local cut_version=$(ver_cut 1-2 "$(uname -r)")
	if ver_test 5.10 -gt "${cut_version}"; then
		test_opts+=(--exclude "io_uring")
	fi

	if ! use x86 && ! use amd64; then
		test_opts+=(--exclude "x86_64")
		test_opts+=(--no-run)
	fi

	if ! use arm64; then
		test_opts+=(--exclude "aarch64")
	fi

	if ! use crosvm-plugin; then
		test_opts+=(--exclude "crosvm_plugin")
	fi

	# Excluding tests that run on a different arch, use /dev/kvm, /dev/dri,
	# /dev/net/tun, or wayland access because the bots don't support these.
	local args=(
		--workspace -v
		--exclude net_util
		--exclude gpu_display
		--exclude rutabaga_gfx
		--exclude crosvm-fuzz
		--exclude swap
		# Exclude crates that require KVM.
		--exclude e2e_tests
		--exclude integration_tests
		--exclude hypervisor
		--exclude kvm
		--exclude kvm_sys
		# Also exclude the following since their tests are run in their ebuilds.
		--exclude enumn
		--exclude sys_util
		--features chromeos
		"${test_opts[@]}"
	)

	# cargo test requires --skip options to be passed to the test itself (after the
	# dividing -- option), so these are in a separate array from args.
	local skip_tests=(
		# Skip tests in devices that need KVM.
		--skip "kvm"
		# Skip tests in x86_64 that need KVM.
		--skip "cpuid::tests::feature_and_vendor_name"
		--skip "test_integration::simple_kvm"
		--skip "test_integration::sys::unix::simple_kvm"
		# Disabled since the test won't pass on builders with disabled
		# cores. b/238787107
		--skip "tsc::calibrate::tests"
	)

	# b/270167741: these tests directly call `libc::fork()` in a
	# multithreaded process (cargo's test harness). This leads to undefined
	# behavior. This UB leads to memory leaks, which breaks AddressSanitizer
	# builds (which imply LeakSanitizer). No breakages related to this UB
	# have been observed outside of LeakSanitizer complaints.
	if use asan; then
		skip_tests+=(
			--skip "register_region_skip_obsolete_process"
			--skip "unregister_region_skip_obsolete_process"
		)
	fi

	# If syslog isn't available, skip the tests.
	[[ -S /dev/log ]] || skip_tests+=(--skip "syslog")

	if use crosvm-plugin; then
		# crosvm_plugin is a cdylibs, so we need to use a profile
		# that doesn't include panic=abort.
		args+=(--profile release-test)
	fi

	ecargo_test "${args[@]}" \
		-- --test-threads=1 \
		"${skip_tests[@]}" ||
		die "cargo test failed"

	# Plugin tests all require /dev/kvm, but we want to make sure they build
	# at least.
	if use crosvm-plugin; then
		ecargo_test --no-run --features plugin,chromeos --profile release-test ||
			die "cargo build with plugin feature failed"
	fi
}

src_install() {
	# cargo doesn't know how to install cross-compiled binaries.  It will
	# always install native binaries for the host system.  Manually install
	# crosvm instead.
	local build_dir="$(cros-rust_get_build_dir)"
	dobin "${build_dir}/crosvm"

	# Install qcow utils library, header, and pkgconfig files.
	dolib.so "${build_dir}/deps/libqcow_utils.so"

	local include_dir="/usr/include/crosvm"

	"${S}"/qcow_utils/platform2_preinstall.sh "${PV}" "${include_dir}" \
		"${WORKDIR}"
	insinto "/usr/$(get_libdir)/pkgconfig"
	doins "${WORKDIR}/libqcow_utils.pc"

	insinto "${include_dir}"
	doins "${S}"/qcow_utils/src/qcow_utils.h

	# Install crosvm_control header and library.
	# Note: Old versions of the crosvm_control package are deleted at the
	# beginning of the compile step, so this doins will only pick up the
	# most recently built crosvm_control.h.
	# TODO(b/188858559) Install the header directly from cargo using --out-dir once the feature is stable
	doins "${build_dir}"/build/crosvm_control-*/out/crosvm_control.h
	dolib.so "${build_dir}/deps/libcrosvm_control.so"

	# Install plugin library, when requested.
	if use crosvm-plugin; then
		insinto "${include_dir}"
		doins "${S}/crosvm_plugin/crosvm.h"
		dolib.so "${build_dir}/deps/libcrosvm_plugin.so"
	fi

	if use fuzzer; then
		cd crosvm-fuzz || die "failed to move directory"
		local f
		for f in "${FUZZERS[@]}"; do
			local fuzzer_component_id="982362"
			fuzzer_install "${S}/crosvm-fuzz/OWNERS" \
				"${build_dir}/${f}" \
				--comp "${fuzzer_component_id}"
		done
		cd .. || die "failed to move directory"
	fi
}

pkg_preinst() {
	enewuser "crosvm"
	enewgroup "crosvm"

	cros-rust_pkg_preinst
}
