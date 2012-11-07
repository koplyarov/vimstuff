#!/bin/bash

VIM_DIR="$HOME/.vim"
CWD=`pwd`
SCRIPT_NAME=`basename $0`
SCRIPT_DIR=`dirname $CWD/$0`

source "$SCRIPT_DIR/toolkit.sh"
SCRIPT_DIR=`RemoveDots $SCRIPT_DIR`

SYNTAX_FILES=`ls -1 $SCRIPT_DIR/syntax`
PATHOGEN_BUNDLES=`ls -1 $SCRIPT_DIR/pathogen_bundle`


CreateDocLinks()
{
	DOC_DIR="$SCRIPT_DIR/pathogen_bundle/$1/doc"
	if [ -d "$DOC_DIR" ]; then
		for DOC_FILE in `ls -1 $DOC_DIR/*.txt`; do
			DOC_FILE=`basename $DOC_FILE`
			Try CreateLink "$DOC_DIR/$DOC_FILE" "$VIM_DIR/doc/$DOC_FILE"
		done
	fi
}

RemoveDocLinks()
{
	DOC_DIR="$SCRIPT_DIR/pathogen_bundle/$1/doc"
	if [ -d "$DOC_DIR" ]; then
		for DOC_FILE in `ls -1 $DOC_DIR/*.txt`; do
			DOC_FILE=`basename $DOC_FILE`
			Try ClearLink "$DOC_DIR/$DOC_FILE" "$VIM_DIR/doc/$DOC_FILE"
		done
	fi
}

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


if [ $# -eq 0 ]; then
	Try MkDirIfAbsent "$VIM_DIR"
	Try MkDirIfAbsent "$VIM_DIR/autoload"
	Try MkDirIfAbsent "$VIM_DIR/syntax"
	Try MkDirIfAbsent "$VIM_DIR/doc"

	Try CreateLink "$SCRIPT_DIR/pathogen_bundle" "$VIM_DIR/bundle"
	Try CreateLink "$SCRIPT_DIR/pathogen/autoload/pathogen.vim" "$VIM_DIR/autoload/pathogen.vim"
	Try CreateLink "$SCRIPT_DIR/my-snippets" "$VIM_DIR/my-snippets"

	for SYNTAX_FILE in $SYNTAX_FILES; do
		Try CreateLink "$SCRIPT_DIR/syntax/$SYNTAX_FILE" "$VIM_DIR/syntax/$SYNTAX_FILE"
	done

	for PATHOGEN_BUNDLE in $PATHOGEN_BUNDLES; do
		Try CreateDocLinks "$PATHOGEN_BUNDLE"
	done

	Try ApplyPatch clang_complete.patch

	Try AddLine "$HOME/.vimrc" "source $SCRIPT_DIR/vimrc"
	Try UpdateVimHelpTags

	Log "$DELIM"
	Log "vimstuff installed!"
else
	case "x$1" in
	"x--remove"*)
		Try RemoveLine "$HOME/.vimrc" "source $SCRIPT_DIR/vimrc"

		RevertPatch clang_complete.patch

		for PATHOGEN_BUNDLE in $PATHOGEN_BUNDLES; do
			Try RemoveDocLinks "$PATHOGEN_BUNDLE"
		done

		for SYNTAX_FILE in $SYNTAX_FILES; do
			Try ClearLink "$SCRIPT_DIR/syntax/$SYNTAX_FILE" "$VIM_DIR/syntax/$SYNTAX_FILE"
		done

		Try ClearLink "$SCRIPT_DIR/pathogen_bundle" "$VIM_DIR/bundle"
		Try ClearLink "$SCRIPT_DIR/pathogen/autoload/pathogen.vim" "$VIM_DIR/autoload/pathogen.vim"
		Try ClearLink "$SCRIPT_DIR/my-snippets" "$VIM_DIR/my-snippets"

		Try UpdateVimHelpTags

		Try RemoveIfEmpty "$VIM_DIR/doc"
		Try RemoveIfEmpty "$VIM_DIR/syntax"
		Try RemoveIfEmpty "$VIM_DIR/autoload"

		Log "$DELIM"
		Log "vimstuff removed!"
		;;
	*)
		Fail "usage: $SCRIPT_NAME [--remove]"
		;;
	esac
fi
