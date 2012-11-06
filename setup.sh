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

Try ln -s $SCRIPT_DIR/pathogen_bundle $VIM_DIR/bundle
if [ ! -e $VIM_DIR/autoload ]; then
	Try mkdir $VIM_DIR/autoload
fi
Try ln -s $SCRIPT_DIR/pathogen/autoload/pathogen.vim $VIM_DIR/autoload/
Try ln -s $SCRIPT_DIR/my-snippets $VIM_DIR/my-snippets

Log "Add 'source $SCRIPT_DIR/vimrc' to your $HOME/.vimrc file"
