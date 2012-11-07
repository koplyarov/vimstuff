DELIM='==============================================='
ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

RemoveDots() {
	echo $* | sed 's@/\./@/@g' | sed 's@/\.$@@g'
}

Log() {
	if [ "`basename $SHELL`" != "bash" ]; then
		case $1 in
		"Info"*)
			;;
		"Warning"*)
			;;
		"Error"*)
			;;
		*)
			LOGLEVEL="[Info] "
			;;
		esac
		echo "{vimstuff setup} $LOGLEVEL$*" >&2
	else	
		case $1 in
		"Info"*)
			LOGLEVEL="[$1]"
			MSGCOLOR=$COL_GREEN
			shift
			;;
		"Warning"*)
			LOGLEVEL="[$1]"
			MSGCOLOR=$COL_YELLOW
			shift
			;;
		"Error"*)
			LOGLEVEL="[$1]"
			MSGCOLOR=$COL_RED
			shift
			;;
		*)
			LOGLEVEL="[Info]"
			MSGCOLOR=$COL_GREEN
			;;
		esac

		echo -e $COL_MAGENTA"{vimstuff setup} "$MSGCOLOR"$LOGLEVEL"$COL_RESET "$*" >&2
	fi
}

Fail() {
	Log "$DELIM"
	Log Error $@
	exit 1
}

Try() {
	"$@"
	if [ $? -ne 0 ]; then
		Fail "$* failed!"
	fi
}

MkDirIfAbsent() {
	if [ ! -e $1 ]; then
		Log "Creating directory $1"
		Try mkdir $1
	fi
}

CreateLink() {
	Log "Creating $2 -> $1"
	if [ -e "$2" ]; then
		Fail "$2 exists!"
	fi
	Try ln -s $@
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

ApplyPatch() {
	Log "Applying patch $1"
	Try patch -p1 < $1
}

RevertPatch() {
	Log "Reverting patch $1"
	patch --no-backup --reject-file=- -f -R -p1 < $1
	if [ $? -ne 0 ]; then
		Log Warning "Could not revert $1!"
	fi
}


AddLine() {
	echo "$2" >> $1
	if [ $? -eq 0 ]; then
		Log "Successfully added '$2' to $1"
	else
		Log Warning "Could not add '$2' to $1. You should do it manually."
	fi
}

RemoveLine() {
	TEMPFILE1=`tempfile`
	if grep -xvF "$2" "$1" > $TEMPFILE1; then
		TEMPFILE2=`tempfile`
		Try mv "$1" $TEMPFILE2
		if mv $TEMPFILE1 "$1"; then
			rm $TEMPFILE2
			Log "Successfully removed '$2' from $1"
		else
			Try mv $TEMPFILE2 "$1"
			Log Warning "Could not remove '$2' from $1. You should do it manually."
		fi
	else
		rm $TEMPFILE1
	fi
}
