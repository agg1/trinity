# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Original Author: fat-zer
# Purpose: support planty of ebuilds for trinity project (a kde3 fork).
#

inherit trinity-functions cmake-utils qt3 base

# @ECLASS-VARIABLE: BUILD_TYPE
# @DESCRIPTION:
# Determins he build type: live or release

# @ECLASS-VARIABLE: TRINITY_SCM
# @DESCRIPTION:
# Determins from what version control system code is chiking out for live
# ebuilds.

# @ECLASS-VARIABLE: TMP_DOCDIR
# @DESCRIPTION: 
# A temporary directory used to copy common documentation before installing it
# 
# @ECLASS-VARIABLE: TRINTY_BASE_NO_INSTALL_DOC
# @DESCRIPTION: 
# if setted to anything except "no" this variable prevents
# trinity-base_src_install() to install documentation
# 

trinity-base_declare_src_uri() {
	local host_module_name

# taballs are still named with kde prefix
#	case "${TRINITY_MODULE_NAME}" in
#		tdelibs) host_module_name="kdelibs" ;;
#		tdebase) host_module_name="kdebase" ;;
#		tdeartwork) host_module_name="kdeartwork" ;;
#		*) host_module_name="${TRINITY_MODULE_NAME}" ;;
#	esac
	host_module_name="${TRINITY_MODULE_NAME}"

	if [[ -n "${TRINITY_MODULE_TYPE}" ]]; then
		host_module_name="${TRINITY_MODULE_TYPE}/${host_module_name}"
	fi

	SRC_URI="${TRINITY_BASE_SRC_URI}/${PV}/${host_module_name}-${PV}.tar.gz"
}


# @ECLASS-VARIABLE: TRINITY_COMMON_DOCS
# @DESCRIPTION:
# Common doc names that was found in trinity project's dirs.
TRINITY_COMMON_DOCS="AUTHORS BUGS CHANGELOG CHANGES COMMENTS COMPLIANCE COMPILING
	CONFIG_FORMAT CONFIGURING COPYING COPYRIGHT CREDITS DEBUG DESIGN FAQ 
	HACKING HISTORY HOWTO IDEAS INSTALL LICENSE MAINTAINERS NAMING NEWS
	NOTES PLUGINS PORTING README SECURITY-HOLES TASKGROUPS TEMPLATE 
	TESTCASES THANKS THOUGHTS TODO VERSION"

TRINITY_BASE_SRC_URI="http://trinity.blackmag.net/releases"

# determine the build type
if [[ ${PV} = *9999* ]]; then
	BUILD_TYPE="live"
else
	BUILD_TYPE="release"
fi
export BUILD_TYPE

#reset TRINITY_SCM and inherit proper eclass
if [[ ${BUILD_TYPE} = live ]]; then
	# set default TRINITY_SCM if not set
	[[ -z "$TRINITY_SCM" ]] && TRINITY_SCM=git

	case ${TRINITY_SCM} in
		git) inherit git-2 ;;
		svn) inherit subversion ;;
		*) die "Unsupported TRINITY_SCM=${TRINITY_SCM}" ;;
	esac

	#set some varyables
	case ${TRINITY_SCM} in
	git)
		 if [[ -z "${EGIT_MIRROR}" ]]; then
			EGIT_MIRROR="http://scm.trinitydesktop.org/scm/git"
		 fi
		 EGIT_REPO_URI="${EGIT_MIRROR}/${TRINITY_MODULE_NAME}"
		 EGIT_BRANCH="master"
		 EGIT_PROJECT="trinity/${TRINITY_MODULE_NAME}"
		 EGIT_HAS_SUBMODULES="yes"
	;;
#	svn) ESVN_MIRROR="svn://anonsvn.kde.org/home/kde/branches/trinity"
#		 ESVN_REPO_URI="${ESVN_MIRROR}/${TRINITY_MODULE_NAME}"
#		 ESVN_PROJECT="trinity/$(dirname $TRINITY_MODULE_NAME)"
#	;;
	esac
elif [[ "${BUILD_TYPE}" == release ]]; then
	trinity-base_declare_src_uri
else
	die "Unknown BUILD_TYPE=${BUILD_TYPE}"
fi


# @FUNCTION: trinity-base_src_prepare
# @DESCRIPTION:
# General pre-configure and pre-compile function for Trinity applications.
trinity-base_src_prepare() {
	debug-print-function ${FUNCNAME} "$@"

# 	# Only enable selected languages, used for KDE extragear apps.
# 	if [[ -n ${KDE_LINGUAS} ]]; then
# 		enable_selected_linguas
# 	fi

	# SCM bootstrap
	if [[ ${BUILD_TYPE} = live ]]; then
		case ${TRINITY_SCM} in
			svn) subversion_src_prepare ;;
	        git) ;;
			*)  die "TRINITY_SCM: ${TRINITY_SCM} is not supported by ${FUNCNAME}"
		esac
	fi

	# Apply patches
	base_src_prepare
}


# if [[ ${CATEGORY} == "kde-base" ]]; then
# 	# Get the aRts dependencies right - finally.
# 	case "${PN}" in
# 		blinken|juk|kalarm|kanagram|kbounce|kcontrol|konq-plugins|kscd|kscreensaver|kttsd|kwifimanager|kdelibs) ARTS_REQUIRED="" ;;
# 		artsplugin-*|kaboodle|kasteroids|kdemultimedia-arts|kolf|krec|ksayit|noatun*) ARTS_REQUIRED="yes" ;;
# 		*) ARTS_REQUIRED="never" ;;
# 	esac
# fi
# @FUNCTION: trinity-base_src_configure
# @DESCRIPTION:
# Call standart cmake-utils_src_onfigure and add some common arguments.
trinity-base_src_configure() {
	debug-print-function ${FUNCNAME} "$@"
	
	[[ -n "${PREFIX}" ]] && export PREFIX="${TDEDIR}"

	mycmakeargs=(
		-DCMAKE_INSTALL_RPATH="${TDEDIR}"
		"${mycmakeargs[@]}"
	)

	cmake-utils_src_configure
}

# @FUNCTION: trinity-base_src_install
# @DESCRIPTION:
# Call standart cmake-utils_src_install and installs common documentation. 
trinity-base_src_install() {
	debug-print-function ${FUNCNAME} "$@"
	cmake-utils_src_install

	trinity-base_fix_desktop_files
	if [[ -z "$TRINITY_BASE_NO_INSTALL_DOC" ||
			"$TRINITY_BASE_NO_INSTALL_DOC" == "no" ]]; then
		trinity-base_create_tmp_docfiles
		trinity-base_install_docfiles
	fi
}

# @FUNCTION: trinity-base_create_tmp_docfiles
# @DESCRIPTION:
# Create docfiles in the form ${TMP_DOCDIR}/path.to.docfile.COMMON_NAME
# Also see the description for TRINITY_COMMON_DOCS and TMP_DOCDIR.
trinity-base_create_tmp_docfiles() {
	debug-print-function ${FUNCNAME} "$@"
	local srcdirs dir docfile targetdoc

	if [[ -z "$TMP_DOCDIR" || ! -d "$TMP_DOCDIR" ]] ; then
		TMP_DOCDIR="$T/docs"
		mkdir -p ${TMP_DOCDIR}
	fi

	if [[ -z "$@" ]] ; then
		srcdirs="./"
	else
		srcdirs="$@"
	fi

	einfo "Generating documentation list..."
	for dir in $srcdirs; do
		for doc in ${TRINITY_COMMON_DOCS}; do
			for docfile in $(find $dir -type f -name "*${doc}*"); do
				targetdoc="${docfile//\//.}"
				targetdoc="${targetdoc#..}"
				cp "${docfile}" "$TMP_DOCDIR/${targetdoc}"
			done
		done
	done

#	if [[ "${TRINITY_INSTALL_ROOT_DOCS}" == "yes" && " ${srcdirs} " == "* ./ *" ]]; then
#		for doc in ${TRINITY_COMMON_DOCS}; do
#			for docfile in $(ls ./"*${doc}*"); do
#				targetdoc="${docfile//\//.}"
#				targetdoc="${targetdoc#..}"
#				cp "${docfile}" "$TMP_DOCDIR/${targetdoc}"
#			done
#		done
#	fi
}

# @FUNCTION: trinity-base_install_docfiles
# @DESCRIPTION:
# Install documentation from ${TMP_DOCDIR} or from first argument.
trinity-base_install_docfiles() {
	debug-print-function ${FUNCNAME} "$@"
	local doc docdir
	[[ -n "$TMP_DOCDIR" ]] && docdir="$TMP_DOCDIR"
	[[ -n "$1" ]] && docdir="$1"
	[[ -z "$docdir" ]] && die "docdir is not set in ${FUNCNAME}."

	pushd "${docdir}" >/dev/null
	find . -maxdepth 1 -type f | while read doc; do
		einfo "Installing documentation: ${doc##*/}"
		dodoc "${doc}"
	done
	popd >/dev/null
}

# @FUNCTION: trinity-base_fix_desktop_files
# @DESCRIPTION:
# Perform desktop files modifications according to current version. You can pass
# either desktop files or direcories to the parametrs. In case you'd pass a
# directory the function will recursively search for all desktop files and
# modify them. If no argument specified the function assume to work on the ${D};
trinity-base_fix_desktop_files() {
	
	# Test if we have to perform any file fixing for current version
	case "3.5" in
		*${TRINITY_VER}*);;
		*) return 0 ;;
	esac
	
	local file_list dir_list f

	if [ "$#" = 1 ]; then
		# Get directories and files from arguments
		for f in $@; do
			if [ -f "$f" ]; then 
				file_list+=" $f"
			elif [ -d "$f" ]; then
				dir_list+=" $f"
			else
				eerror "${FUNCNAME}: bad argument type: $(stat -c %F "$f")"
			fi
		done
	else
		dir_list="${D}"
	fi

	# Recursivly search for desktop files in directories
	for f in $dir_list; do
		file_list+="$(find ${f} -type f -name '*.desktop')"
	done
	
	# Performe the updates
	case "${TRINITY_VER}" in
	3.5)
		for f in $file_list; do
			sed -i '/^OnlyShowIn=/s/KDE/TDE/g' "$f"
		done;;
	esac
}

EXPORT_FUNCTIONS src_configure src_install src_prepare
