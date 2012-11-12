msg_MkDir() { echo "Creating directory '$1'"; }
do_MkDir() { [ -d $1 ] || mkdir $1; }
undo_MkDir() { [ ! -d $1 ] || [ ! -z "`ls -1A $1`" ] || rm -r $1; }

msg_Symlink() { echo "Creating $2 -> $1"; }
do_Symlink() { ln -s $1 $2; }
undo_Symlink() { [ "`readlink $2`" != "$1" ] || rm $2; }

msg_Patch() { echo "Applying patch $1"; }
do_Patch() { patch -p1 < $1; }
undo_Patch() { patch --no-backup --reject-file=- -f -R -p1 < $1; }

msg_Cp() { echo "Copying $1 to $2"; }
do_Cp() { cp $1 $2; }
undo_Cp() { rm $2; }

msg_Mv() { echo "Moving $1 to $2"; }
do_Mv() { mv $1 $2; }
undo_Mv() { mv $2 $1; }

msg_GrepTo() { echo "Grepping to $1"; }
do_GrepTo() { local F="$1"; shift; grep "$@">$F; if [ $? -gt 1 ]; then return 1; fi }
undo_GrepTo() { rm $1; }

msg_Rm() { echo "Removing $1"; }
do_Rm() { rm $1; }
undo_Rm() { echo "There is no way to undo rm. =)"; return 1; }

msg_AddLine() { echo "Adding '$2' to $1"; }
do_AddLine() {
	if [ grep xF "\"$2" "$1" >/dev/null 2>/dev/null ]; then
		echo "$2" >> $1;
	else
		LINE="`EscapeForSed "$2"`"
		sed -i "s/^\"$LINE/$LINE/g" $1
	fi
}
undo_AddLine() {
	LINE="`EscapeForSed "$2"`"
	sed -i "s/^$LINE/\"$LINE/g" $1
}
