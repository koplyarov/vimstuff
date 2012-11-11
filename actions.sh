msg_MkDir() { echo "Creating directory '$1'"; }
do_MkDir() { [ -d $1 ] || mkdir $1; }
undo_MkDir() { [ ! -d $1 ] || [ ! -z "`ls -1A $1`" ] || rm -r $1; }

msg_Symlink() { echo "Creating $2 -> $1"; }
do_Symlink() { ln -s $1 $2; }
undo_Symlink() { [ "`readlink $2`" != "$1" ] || rm $2; }

msg_Patch() { echo "Applying patch $1"; }
do_Patch() { patch -p1 < $1; }
undo_Patch() { patch --no-backup --reject-file=- -f -R -p1 < $1; }

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
do_AddLine() { echo "$2" >> $1; }
undo_AddLine() {
	local TEMPFILE1=`tempfile`
	local TEMPFILE2=`tempfile`

	CreateSetup REMOVELINE_ACTIONS
	AddAction REMOVELINE_ACTIONS GrepTo $TEMPFILE1 -xvF "$2" "$1"
	AddAction REMOVELINE_ACTIONS Mv "$1" $TEMPFILE2
	AddAction REMOVELINE_ACTIONS Mv $TEMPFILE1 "$1"
	AddAction REMOVELINE_ACTIONS Rm $TEMPFILE2
	Install REMOVELINE_ACTIONS
}
