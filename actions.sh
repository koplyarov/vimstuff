msg_AddVimCfgLine() { echo "Adding '$2' to $1"; }
do_AddVimCfgLine() {
	if grep -xF "\"$2" "$1" >/dev/null 2>/dev/null; then
		LINE="`EscapeForSed "$2"`"
		sed -i "s/^\"$LINE/$LINE/g" $1
	else
		echo "$2" >> $1;
	fi
}
undo_AddVimCfgLine() {
	LINE="`EscapeForSed "$2"`"
	sed -i "s/^$LINE/\"$LINE/g" $1
}

msg_VimBall() { echo "Installing vimball '$1'"; }
do_VimBall() { vim +"source $1" +"qa"; }
undo_VimBall() { vim +"RmVimball `basename "$1"`"; }

msg_GitSubmodulesInitUpdate() { echo "Initting git submodules for '$1'"; }
do_GitSubmodulesInitUpdate() { ( cd "$1" && git submodule update --init --recursive ) }
undo_GitSubmodulesInitUpdate() { ( cd "$1" && git submodule deinit . ) }

msg_YcmInstall() { echo "Installing YouCompleteMe (this step downloads clang from somewhere, so it may take a while)"; }
do_YcmInstall() { ( cd "$1" && ./install.py --clang-completer ) }
undo_YcmInstall() { true; }
