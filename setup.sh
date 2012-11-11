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
source "$SCRIPT_DIR/actions.sh"

LOGGER_SCRIPTNAME="vimstuff setup"
SCRIPT_DIR=`RemoveDots $SCRIPT_DIR`

SYNTAX_FILES=`ls -1 $SCRIPT_DIR/syntax`
PATHOGEN_BUNDLES=`ls -1 $SCRIPT_DIR/pathogen_bundle`

UpdateVimHelpTags() {
	if [ -z "`ls -1A $VIM_DIR/doc | grep -vxF 'tags'`" ]; then
		Log "$VIM_DIR/doc is empty, removing vim help tags"
		rm $VIM_DIR/doc/tags
		if [ $? -ne 0 ]; then
			Log Warning "Could not remove $VIM_DIR/doc/tags"
		fi
	else
		vim +"helptags $VIM_DIR/doc" +"qa"
		if [ $? -eq 0 ]; then
			Log "Updated vim help tags"
		else
			Log Warning "Failed at updating vim help tags. You should do it manually."
		fi
	fi
}


ACTIONS=""
AddAction ACTIONS MkDir "$VIM_DIR"
AddAction ACTIONS MkDir "$VIM_DIR/autoload"
AddAction ACTIONS MkDir "$VIM_DIR/syntax"
AddAction ACTIONS MkDir "$VIM_DIR/doc"

AddAction ACTIONS Symlink "$SCRIPT_DIR/pathogen_bundle" "$VIM_DIR/bundle"
AddAction ACTIONS Symlink "$SCRIPT_DIR/pathogen/autoload/pathogen.vim" "$VIM_DIR/autoload/pathogen.vim"
AddAction ACTIONS Symlink "$SCRIPT_DIR/my-snippets" "$VIM_DIR/my-snippets"

for SYNTAX_FILE in $SYNTAX_FILES; do
	AddAction ACTIONS Symlink "$SCRIPT_DIR/syntax/$SYNTAX_FILE" "$VIM_DIR/syntax/$SYNTAX_FILE"
done

for PATHOGEN_BUNDLE in $PATHOGEN_BUNDLES; do
	DOC_DIR="$SCRIPT_DIR/pathogen_bundle/$PATHOGEN_BUNDLE/doc"
	if [ -d "$DOC_DIR" ]; then
		for DOC_FILE in `ls -1 $DOC_DIR/*.txt`; do
			DOC_FILE=`basename $DOC_FILE`
			AddAction ACTIONS Symlink "$DOC_DIR/$DOC_FILE" "$VIM_DIR/doc/$DOC_FILE"
		done
	fi
done

AddAction ACTIONS Patch clang_complete.patch
AddAction ACTIONS AddLine "$HOME/.vimrc" "source $SCRIPT_DIR/vimrc"

case "x$1" in
"x")
	if Install "$ACTIONS"; then
		UpdateVimHelpTags
		Log "$DELIM"
		Log "vimstuff installed!"
	else
		Log "$DELIM"
		Log Error "vimstuff failed to install!"
	fi
	;;
"x--remove")
	UpdateVimHelpTags
	Uninstall "$ACTIONS"
	Log "$DELIM"
	Log "vimstuff removed!"
	;;
"x--update")
	$0 --remove
	#TODO: pull
	$0
	;;
*)
	Fail "usage: $SCRIPT_NAME [--remove]"
	;;
esac
