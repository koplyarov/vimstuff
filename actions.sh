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
