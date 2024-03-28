# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="7"
EGIT_REPO_URI="https://gitlab.freedesktop.org/mesa/drm.git"
if [[ ${PV} != *9999* ]]; then
	CROS_WORKON_COMMIT="56f81e6776c1c100c3f627b2c1feb9dcae2aad3c"
	CROS_WORKON_TREE="f2dad5f135f56bf9e56b44d5b9637ffb59d38f23"
fi
CROS_WORKON_PROJECT="chromiumos/third_party/libdrm"
CROS_WORKON_EGIT_BRANCH="upstream/master"
CROS_WORKON_MANUAL_UPREV="1"

inherit meson cros-workon

DESCRIPTION="X.Org libdrm library"
HOMEPAGE="http://dri.freedesktop.org/"
SRC_URI=""

# This package uses the MIT license inherited from Xorg but fails to provide
# any license file in its source, so we add X as a license, which lists all
# the Xorg copyright holders and allows license generation to pick them up.
LICENSE="|| ( MIT X )"
SLOT="0"
if [[ ${PV} = *9999* ]]; then
	KEYWORDS="~*"
else
	KEYWORDS="*"
fi
VIDEO_CARDS="amdgpu exynos freedreno intel nouveau omap radeon vc4 vmware"
for card in ${VIDEO_CARDS}; do
	IUSE_VIDEO_CARDS+=" video_cards_${card}"
done

IUSE="${IUSE_VIDEO_CARDS} libkms manpages +udev"
REQUIRED_USE="video_cards_exynos? ( libkms )"
RESTRICT="test" # see bug #236845

RDEPEND="dev-libs/libpthread-stubs
	udev? ( virtual/udev )
	video_cards_amdgpu? ( dev-util/cunit )
	video_cards_intel? ( >=x11-libs/libpciaccess-0.10 )
	!<x11-libs/libdrm-tests-2.4.58-r3
"

DEPEND="${RDEPEND}"

src_prepare() {
	eapply "${FILESDIR}"/Add-header-for-Rockchip-DRM-userspace.patch
	eapply "${FILESDIR}"/Add-header-for-Mediatek-DRM-userspace.patch
	eapply "${FILESDIR}"/Add-Evdi-module-userspace-api-file.patch
	eapply "${FILESDIR}"/Add-Rockchip-AFBC-modifier.patch
	eapply "${FILESDIR}"/Add-back-VENDOR_NV-name.patch
	eapply "${FILESDIR}"/CHROMIUM-add-resource-info-header.patch
	eapply "${FILESDIR}"/UPSTREAM-intel-Add-support-for-RPLP.patch
	eapply "${FILESDIR}"/UPSTREAM-tests-util-add-vkms-driver.patch

	eapply_user
}

src_configure() {
	cros_optimize_package_for_speed

	local emesonargs=(
		-Dinstall-test-programs=true
		$(meson_use video_cards_amdgpu amdgpu)
		$(meson_use video_cards_exynos exynos)
		$(meson_use video_cards_freedreno freedreno)
		$(meson_use video_cards_intel intel)
		$(meson_use video_cards_nouveau nouveau)
		$(meson_use video_cards_omap omap)
		$(meson_use video_cards_radeon radeon)
		$(meson_use video_cards_vc4 vc4)
		$(meson_use video_cards_vmware vmwgfx)
		$(meson_use libkms)
		$(meson_use manpages man-pages)
		$(meson_use udev)
		-Dcairo-tests=false
	)
	meson_src_configure
}
