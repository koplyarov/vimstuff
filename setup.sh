#!/bin/sh

VIM_DIR="$HOME/.vim"
CWD=`pwd`
SCRIPT_DIR=`dirname $CWD/$0`

Log() {
	echo $@ >&2
}

Fail() {
	Log $@
	exit 1
}

Try() {
	$@
	if [ $? -ne 0 ]; then
		Fail "$* failed!"
	fi
}

MkDirIfAbsent() {
	if [ ! -e $1 ]; then
		Try mkdir $1
	fi
}

ClearLink() {
	SRC=`readlink $2`
	if [ $? -eq 0 ]; then
		if [ "$SRC" = "$1" ]; then
			Log "Removing $2 -> $1"
			Try rm $2
		else
			Log "$2 is not a link to $1, ignoring it"
		fi
	fi
}

RemoveIfEmpty() {
	if [ \( -d $1 \) ]; then
		if [ -z "`ls -1A $1`" ]; then
			Log "$1 is empty, removing it"
			Try rm -r $1
		fi
	fi
}

if [ "x$1" = "x--remove" ]; then
	patch --no-backup --reject-file=- -f -R -p1 < clang_complete.patch
	if [ $? -ne 0 ]; then
		Log "WARNING: Could not patch clang_complete"
	fi

	Try ClearLink "$SCRIPT_DIR/pathogen_bundle" "$VIM_DIR/bundle"
	Try ClearLink "$SCRIPT_DIR/pathogen/autoload/pathogen.vim" "$VIM_DIR/autoload/pathogen.vim"
	Try ClearLink "$SCRIPT_DIR/my-snippets" "$VIM_DIR/my-snippets"

	Try RemoveIfEmpty "$VIM_DIR/autoload"
else
	Try MkDirIfAbsent "$VIM_DIR"
	Try MkDirIfAbsent "$VIM_DIR/autoload"

	Try ln -s "$SCRIPT_DIR/pathogen_bundle" "$VIM_DIR/bundle"
	Try ln -s "$SCRIPT_DIR/pathogen/autoload/pathogen.vim" "$VIM_DIR/autoload/pathogen.vim"
	Try ln -s "$SCRIPT_DIR/my-snippets" "$VIM_DIR/my-snippets"

	Try patch -p1 < clang_complete.patch

	Log "Add 'source $SCRIPT_DIR/vimrc' to your $HOME/.vimrc file"
fi
