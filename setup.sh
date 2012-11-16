#!/bin/bash

VIM_DIR="$HOME/.vim"
CWD=`pwd`
SCRIPT_NAME=`basename $0`
SCRIPT_DIR=`dirname $CWD/$0`

if [ ! -e "$SCRIPT_DIR/shstuff/toolkit.sh" ]; then
	echo "ERROR: toolkit.sh not found! You should update submodules!" >&2
	exit 1
fi

source "$SCRIPT_DIR/shstuff/toolkit.sh"
source "$SCRIPT_DIR/shstuff/libsetup.sh"
source "$SCRIPT_DIR/shstuff/stdsetupactions.sh"
source "$SCRIPT_DIR/actions.sh"

LOGGER_SCRIPTNAME="vimstuff setup"
SCRIPT_DIR=`RemoveDots $SCRIPT_DIR`

SYNTAX_FILES=`ls -1 $SCRIPT_DIR/syntax`
PATHOGEN_BUNDLES=`ls -1 $SCRIPT_DIR/pathogen_bundle`

UpdateVimHelpTags() {
	if [ -z "`ls -1A $VIM_DIR/doc | grep -vxF 'tags'`" ]; then
		Log "$VIM_DIR/doc is empty, removing vim help tags"
		rm $VIM_DIR/doc/tags || Log Warning "Could not remove $VIM_DIR/doc/tags"
	else
		vim +"helptags $VIM_DIR/doc" +"qa" && Log "Updated vim help tags" || Log Warning "Failed at updating vim help tags. You should do it manually."
	fi
}


CreateSetup VIMSTUFF_SETUP
AddAction VIMSTUFF_SETUP MkDir "$VIM_DIR"
AddAction VIMSTUFF_SETUP MkDir "$VIM_DIR/autoload"
AddAction VIMSTUFF_SETUP MkDir "$VIM_DIR/syntax"
AddAction VIMSTUFF_SETUP MkDir "$VIM_DIR/doc"

AddAction VIMSTUFF_SETUP Symlink "$SCRIPT_DIR/pathogen_bundle" "$VIM_DIR/bundle"
AddAction VIMSTUFF_SETUP Symlink "$SCRIPT_DIR/pathogen/autoload/pathogen.vim" "$VIM_DIR/autoload/pathogen.vim"
AddAction VIMSTUFF_SETUP Symlink "$SCRIPT_DIR/my-snippets" "$VIM_DIR/my-snippets"

for SYNTAX_FILE in $SYNTAX_FILES; do
	AddAction VIMSTUFF_SETUP Symlink "$SCRIPT_DIR/syntax/$SYNTAX_FILE" "$VIM_DIR/syntax/$SYNTAX_FILE"
done

for PATHOGEN_BUNDLE in $PATHOGEN_BUNDLES; do
	DOC_DIR="$SCRIPT_DIR/pathogen_bundle/$PATHOGEN_BUNDLE/doc"
	if [ -d "$DOC_DIR" ]; then
		for DOC_FILE in `ls -1 $DOC_DIR/*.txt`; do
			DOC_FILE=`basename $DOC_FILE`
			AddAction VIMSTUFF_SETUP Symlink "$DOC_DIR/$DOC_FILE" "$VIM_DIR/doc/$DOC_FILE"
		done
	fi
done

AddAction VIMSTUFF_SETUP Patch -p1 clang_complete.patch
AddAction VIMSTUFF_SETUP Patch -p1 fuf.patch
AddAction VIMSTUFF_SETUP AddVimCfgLine "$HOME/.vimrc" "source $SCRIPT_DIR/vimrc"

case "x$1" in
"xinstall")
	if Install VIMSTUFF_SETUP; then
		UpdateVimHelpTags
		Log "$DELIM"
		Log "vimstuff installed!"
	else
		Log "$DELIM"
		Log Error "vimstuff failed to install!"
	fi
	;;
"xremove")
	Uninstall VIMSTUFF_SETUP
	UpdateVimHelpTags
	Log "$DELIM"
	Log "vimstuff removed!"
	;;
"xupdate")
	UpdateFunc() {
		Log "Removing current revision of vimstuff"
		$0 remove
		Log "Pulling new revision from git"
		git pull
		if [ $? -ne 0 ]; then
			$0 install || Log Warning "Could not install vimstuff!"
			Fail "Could not pull new version!"
		fi
		Log "Initializing git submodules"
		git submodule init || Log Warning "Could not initialize git submodules!"
		Log "Updating git submodules"
		git submodule update || Log Warning "Could not update git submodules!"
		Log "Installing new revision of vimstuff"
		$0 install || Fail "Could not install vimstuff!"
		exit 0
	}
	UpdateFunc
	;;
*)
	Fail "usage: $SCRIPT_NAME install|remove|update"
	;;
esac
