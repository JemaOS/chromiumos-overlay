# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

CROS_WORKON_PROJECT="chromiumos/third_party/virglrenderer"
CROS_WORKON_EGIT_BRANCH="master"

# Prevent automatic uprevs of this package since upstream is out of our control.
CROS_WORKON_MANUAL_UPREV="1"

inherit cros-fuzzer cros-sanitizers eutils flag-o-matic meson cros-workon

DESCRIPTION="library used implement a virtual 3D GPU used by qemu"
HOMEPAGE="https://virgil3d.github.io/"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~*"
IUSE="debug fuzzer profiling test virtgpu_native_context vulkan"

RDEPEND="
	chromeos-base/percetto
	>=x11-libs/libdrm-2.4.50
	media-libs/libepoxy
	media-libs/minigbm
	fuzzer? (
		virtual/opengles
	)
	vulkan? (
		media-libs/vulkan-loader
	)
"
# We need autoconf-archive for @CODE_COVERAGE_RULES@. #568624
DEPEND="${RDEPEND}
	sys-devel/autoconf-archive
	fuzzer? ( >=dev-libs/check-0.9.4 )
	test? ( >=dev-libs/check-0.9.4 )
	vulkan? ( dev-util/vulkan-headers )
"

PATCHES=(
	"${FILESDIR}"/0001-vrend-disable-GL_EXT_external_object_fd-path-on-GLES.patch
	"${FILESDIR}"/0002-UPSTREAM-renderer-Ensure-to-only-consider-a-certain-.patch
	"${FILESDIR}"/0003-UPSTREAM-renderer-Unbind-the-sampler-state-from-the-.patch
	"${FILESDIR}"/0004-UPSTREAM-p_state-Decrease-the-size-of-pipe_stream_ou.patch
	"${FILESDIR}"/0005-UPSTREAM-shader-Use-strdup-in-rewrite_1d_image_coord.patch
	"${FILESDIR}"/0006-UPSTREAM-decode-Use-size_t-when-dealing-with-memory-.patch
	"${FILESDIR}"/0007-UPSTREAM-renderer-Make-abo-and-ssbo-take-a-strong-re.patch
	"${FILESDIR}"/0008-UPSTREAM-renderer-Avoid-out-of-bound-access-when-rel.patch
	"${FILESDIR}"/0009-UPSTREAM-shader-Check-the-bias-and-offset-after-the-.patch
	"${FILESDIR}"/0010-UPSTREAM-shader-Extract-the-string-after-last-reallo.patch
	"${FILESDIR}"/0011-UPSTREAM-shader-Properly-check-string-length.patch
	"${FILESDIR}"/0012-UPSTREAM-renderer-Take-a-reference-of-the-resource-w.patch
	"${FILESDIR}"/0013-UPSTREAM-shader-tgsi-check-array-access-and-report-f.patch
	"${FILESDIR}"/0014-UPSTREAM-renderer-Check-the-the-format-is-valid-befo.patch
	"${FILESDIR}"/0015-UPSTREAM-renderer-Take-a-reference-of-the-resource-w.patch
	"${FILESDIR}"/0016-UPSTREAM-tgsi-Add-sanity-checks-to-avoid-out-of-boun.patch
	"${FILESDIR}"/0017-UPSTREAM-renderer-Make-sure-to-unbind-the-sampler-st.patch
	"${FILESDIR}"/0018-UPSTREAM-gallium-fix-tgsi-error-debug-outputs.patch
	"${FILESDIR}"/0019-UPSTREAM-tgsi-catch-sampler-out-of-range-early.patch
	"${FILESDIR}"/0020-UPSTREAM-shader-bail-out-early-if-sampler-id-is-out-.patch
	"${FILESDIR}"/0021-UPSTREAM-shader-Specify-the-size-of-the-front_back_c.patch
	"${FILESDIR}"/0022-UPSTREAM-shader-Do-some-basic-sanity-checks-in-emit_.patch
)

src_prepare() {
	default
}

src_configure() {
	sanitizers-setup-env

	# flto flag added under condition due to llvm open issue
	# https://github.com/llvm/llvm-project/issues/57944
	if ! use fuzzer; then
		append-flags -flto
	fi

	if use profiling; then
		append-flags -fprofile-instr-generate -fcoverage-mapping
		append-ldflags -fprofile-instr-generate -fcoverage-mapping
	fi

	emesonargs+=(
		-Dtracing=percetto
		-Dminigbm_allocation="true"
		-Dplatforms="egl"
		-Dcheck-gl-errors="false"
		$(meson_use fuzzer)
		--buildtype $(usex debug debug release)
	)

	if use virtgpu_native_context; then
		emesonargs+=( -Ddrm-msm-experimental="true" )
	fi

	if use vulkan; then
		emesonargs+=(
			-Dvenus-experimental="true"
			-Drender-server="true"
			-Drender-server-worker="process"
		)
	fi

	# virgl_fuzzer is only built with tests.
	if use test || use fuzzer; then
		emesonargs+=( -Dtests="true" )
	fi

	meson_src_configure
}

src_install() {
	meson_src_install

	local fuzzer_component_id="964076"
	fuzzer_install "${FILESDIR}/fuzzer-OWNERS" \
		"${WORKDIR}/${P}-build"/tests/fuzzer/virgl_fuzzer \
		--options "${FILESDIR}/virgl_fuzzer.options" \
		--comp "${fuzzer_component_id}"
	fuzzer_install "${FILESDIR}/fuzzer-OWNERS" \
		"${WORKDIR}/${P}-build"/vtest/vtest_fuzzer \
		--options "${FILESDIR}/vtest_fuzzer.options" \
		--comp "${fuzzer_component_id}"

	find "${ED}"/usr -name 'lib*.la' -delete
}
