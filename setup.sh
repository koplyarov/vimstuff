#!/bin/bash

VIM_DIR="$HOME/.vim"
CWD=`pwd`
SCRIPT_NAME=`basename $0`
SCRIPT_DIR=`dirname $CWD/$0`

source "$SCRIPT_DIR/toolkit.sh"
SCRIPT_DIR=`RemoveDots $SCRIPT_DIR`

SYNTAX_FILES=`ls -1 $SCRIPT_DIR/syntax`


if [ $# -eq 0 ]; then
	Try MkDirIfAbsent "$VIM_DIR"
	Try MkDirIfAbsent "$VIM_DIR/autoload"
	Try MkDirIfAbsent "$VIM_DIR/syntax"

	Try CreateLink "$SCRIPT_DIR/pathogen_bundle" "$VIM_DIR/bundle"
	Try CreateLink "$SCRIPT_DIR/pathogen/autoload/pathogen.vim" "$VIM_DIR/autoload/pathogen.vim"
	Try CreateLink "$SCRIPT_DIR/my-snippets" "$VIM_DIR/my-snippets"
	for SYNTAX_FILE in $SYNTAX_FILES; do
		Try CreateLink "$SCRIPT_DIR/syntax/$SYNTAX_FILE" "$VIM_DIR/syntax/$SYNTAX_FILE"
	done

	Try ApplyPatch clang_complete.patch

	Try AddLine "$HOME/.vimrc" "source $SCRIPT_DIR/vimrc"

	Log "$DELIM"
	Log "vimstuff installed!"
else
	case "x$1" in
	"x--remove"*)
		Try RemoveLine "$HOME/.vimrc" "source $SCRIPT_DIR/vimrc"

		RevertPatch clang_complete.patch

		for SYNTAX_FILE in $SYNTAX_FILES; do
			Try ClearLink "$SCRIPT_DIR/syntax/$SYNTAX_FILE" "$VIM_DIR/syntax/$SYNTAX_FILE"
		done
		Try ClearLink "$SCRIPT_DIR/pathogen_bundle" "$VIM_DIR/bundle"
		Try ClearLink "$SCRIPT_DIR/pathogen/autoload/pathogen.vim" "$VIM_DIR/autoload/pathogen.vim"
		Try ClearLink "$SCRIPT_DIR/my-snippets" "$VIM_DIR/my-snippets"

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
