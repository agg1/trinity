# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI="5"
TRINITY_MODULE_NAME="tdegraphics"

inherit trinity-meta

DESCRIPTION="A Trinity Viewer for PostScript (.ps, .eps) and PDF (.pdf) files"
KEYWORDS=
IUSE=""

DEPEND="x11-libs/libXft"
RDEPEND="${DEPEND}"
