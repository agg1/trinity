# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $
EAPI="3"
TRINITY_MODULE_NAME="tdebase"

inherit trinity-meta

DESCRIPTION="Trinity hotkey daemon"
KEYWORDS=""
IUSE="arts"

DEPEND="
	arts? ( >=trinity-base/arts-${PV}:${SLOT} )
	x11-libs/libXtst"
RDEPEND="$DEPEND"

src_configure() {
	mycmakeargs=(
		-D_WITH_XTEST=ON
		$(cmake-utils_use_with arts ARTS)
	)

	trinity-meta_src_configure
}
