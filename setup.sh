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
	Try ClearLink $SCRIPT_DIR/pathogen_bundle $VIM_DIR/bundle
	Try ClearLink $SCRIPT_DIR/pathogen/autoload/pathogen.vim $VIM_DIR/autoload/pathogen.vim
	Try ClearLink $SCRIPT_DIR/my-snippets $VIM_DIR/my-snippets
	Try RemoveIfEmpty "$VIM_DIR/autoload"
else
	Try ln -s $SCRIPT_DIR/pathogen_bundle $VIM_DIR/bundle
	if [ ! -e $VIM_DIR/autoload ]; then
		Try mkdir $VIM_DIR/autoload
	fi
	Try ln -s $SCRIPT_DIR/pathogen/autoload/pathogen.vim $VIM_DIR/autoload/
	Try ln -s $SCRIPT_DIR/my-snippets $VIM_DIR/my-snippets

	Log "Add 'source $SCRIPT_DIR/vimrc' to your $HOME/.vimrc file"
fi
