# Copyright 2018 The ChromiumOS Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

CROS_WORKON_COMMIT="759635cf334285c52b12a0ebd304988c4bb1329f"
CROS_WORKON_TREE=("c5a3f846afdfb5f37be5520c63a756807a6b31c4" "2343b73a380a93779b70b4c3099c7a86e473ab99" "f91b6afd5f2ae04ee9a2c19109a3a4a36f7659e6")
CROS_GO_PACKAGES=(
	"chromiumos/policy/..."
)

CROS_WORKON_LOCALNAME="platform2"
CROS_WORKON_PROJECT="chromiumos/platform2"
CROS_WORKON_OUTOFTREE_BUILD=1
CROS_WORKON_SUBTREE="common-mk policy_proto .gn"

PLATFORM_SUBDIR="policy_proto"

inherit cros-go cros-workon platform

DESCRIPTION="Chrome OS policy protocol buffer binding for go"
HOMEPAGE="https://chromium.googlesource.com/chromiumos/platform2/+/HEAD/policy_proto"
LICENSE="BSD-Google"
KEYWORDS="*"

DEPEND="
	>=chromeos-base/protofiles-0.0.48:=
	dev-go/protobuf:=
	dev-go/protobuf-legacy-api:=
	dev-libs/protobuf:=
"

src_install() {
	platform_src_install

	cros-go_src_install
}

src_unpack() {
	platform_src_unpack
	CROS_GO_WORKSPACE="${OUT}/gen/go"
}
