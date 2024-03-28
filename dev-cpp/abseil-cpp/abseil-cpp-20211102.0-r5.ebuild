# Copyright 2020-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} )

inherit cmake python-any-r1

# yes, it needs SOURCE, not just installed one
# and no, 1.11.0 is not enough
GTEST_COMMIT="1b18723e874b256c1e39378c6774a90701d70f7a"
GTEST_FILE="gtest-${GTEST_COMMIT}.tar.gz"

DESCRIPTION="Abseil Common Libraries (C++), LTS Branch"
HOMEPAGE="https://abseil.io"
SRC_URI="https://github.com/abseil/abseil-cpp/archive/${PV}.tar.gz -> ${P}.tar.gz
	test? ( https://github.com/google/googletest/archive/${GTEST_COMMIT}.tar.gz -> ${GTEST_FILE} )"

LICENSE="
	Apache-2.0
	test? ( BSD )
"
SLOT="0/${PVR}"
KEYWORDS="*"
IUSE="test"

DEPEND=""
RDEPEND="${DEPEND}
	!<dev-cpp/absl-${PV}
"

BDEPEND="
	${PYTHON_DEPS}
	test? ( sys-libs/timezone-data )
"

RESTRICT="!test? ( test )"

PATCHES=(
	"${FILESDIR}/${PN}-20211102.0-fix-cuda-nvcc-build.patch"
	"${FILESDIR}/${PN}-20211102.0-fix-pkgconfig.patch"
	"${FILESDIR}/use-std-optional.patch"
)

ABSLDIR="${WORKDIR}/${P}_build/absl"

src_prepare() {
	cmake_src_prepare

	# un-hardcode abseil compiler flags
	sed -i \
		-e '/"-maes",/d' \
		-e '/"-msse4.1",/d' \
		-e '/"-mfpu=neon"/d' \
		-e '/"-march=armv8-a+crypto"/d' \
		absl/copts/copts.py || die

	# now generate cmake files
	python_fix_shebang absl/copts/generate_copts.py
	absl/copts/generate_copts.py || die

	if use test; then
		sed -i 's/-Werror//g' \
			"${WORKDIR}/googletest-${GTEST_COMMIT}"/googletest/cmake/internal_utils.cmake || die
	fi

	# ChromeOS (b/264420866): Enable a "hardened" build.
	sed -i 's/^#define ABSL_OPTION_HARDENED 0/#define ABSL_OPTION_HARDENED 1/' \
		absl/base/options.h || die
}

src_configure() {
	local mycmakeargs=(
		-DABSL_ENABLE_INSTALL=TRUE
		-DABSL_LOCAL_GOOGLETEST_DIR="${WORKDIR}/googletest-${GTEST_COMMIT}"
		-DCMAKE_CXX_STANDARD=17
		-DABSL_PROPAGATE_CXX_STD=TRUE
		$(usex test -DBUILD_TESTING=ON '') #intentional usex
	)
	cmake_src_configure
}

src_compile() {
	cmake_src_compile

	local libs=( "${ABSLDIR}"/*/libabsl_*.so )
	[[ ${#libs[@]} -le 1 ]] && die
	local linklibs="$(echo "${libs[*]}" | sed -E -e 's|[^ ]*/lib([^ ]*)\.so|-l\1|g')"
	sed -e "s/@LIBS@/${linklibs}/g" -e "s/@PV@/${PV}/g" \
		"${FILESDIR}/absl.pc.in" > absl.pc || die
}

src_install() {
	cmake_src_install

	insinto "/usr/$(get_libdir)/pkgconfig"
	doins absl.pc
}
