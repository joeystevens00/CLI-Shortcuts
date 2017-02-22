#!/bin/bash

# Parse thru the arguments
function parseargs() {
	# If we're given less than 3 arguments show an error
	if (($# < 3)); then
		echo "incorrect usage."
		NOCLEANUP=1 # Don't try to delete a file that doesn't exit
		exit 1
	fi

	local x=1
	while (($# > 0)); do # While there are arguments left to parse
		if((x==1)); then
			SHORTCUT="$1" # Contains the shortcut we will use
		elif  ((x==2)); then
			OPTION="$1" # Contains options for that shortcut
		else
			COMMAND="$@" # Contains everything else
			break
		fi
		((x++))
		shift
	done
}

function replaceIterableSyntax() {
	COMMAND=$(echo -e "$COMMAND" | sed 's/{}/\"\$CLISHORTCUTOPTIONITERABLE"/g')
	COMMAND=$(echo -e "$COMMAND" | sed 's/{basename}/\"\$CLISHORTCUTFILENAME\"/g')
	COMMAND=$(echo -e "$COMMAND" | sed 's/{ext}/\"\$CLISHORTCUTFILEEXT\"/g')

	# This is the code that sets up the vars for our DSL
	SETUPVARS=" 
		# we cut . if it happens to be the first character and then get every character after the first .
		CLISHORTCUTFILEEXT=\$(basename \"\$CLISHORTCUTOPTIONITERABLE\" | sed 's/^\.//' | cut -d . -f2-)

		# If we removed the leading . then lets put it back
		CLISHORTCUTFILEEXT=\$(echo -e \$CLISHORTCUTFILEEXT | sed 's/^\([a-z]\)/\.\1/g')

		# When we have a scenario like .tar.gz we may end up with a trailing .
		CLISHORTCUTFILENAME=\$(basename \$CLISHORTCUTOPTIONITERABLE \$CLISHORTCUTFILEEXT)
	"
}

function shortCutFor() {
	# Creates the shortcut for iteratable in OPTION
	echo -e "
	#!/bin/bash
	cleanOption=$(echo -e \"$OPTION\" | tr '\n' ' ')
	for CLISHORTCUTOPTIONITERABLE in \$cleanOption
	do 
		$SETUPVARS
		$COMMAND
	done

	" > $CLISHORTCUTTMPFILE
}

function shortCutWhile() {
	# Creates the shourtcut while [[ logic ]] 
	echo -e "
	#!/bin/bash
	while [[ $OPTION ]]
	do 
		$SETUPVARS
		$COMMAND
	done

	" > $CLISHORTCUTTMPFILE
}

function shortCutLoop() {
	# Creates the shortcut loop X times 

	# If the first word in the COMMAND is a number this will contain that number
	# Otherwise this will contain 0
	local -i end=$(echo "$COMMAND" | cut -d" " -f1)
	if ((end==0)); then
		start=1
		end=$OPTION
	else
		start=$OPTION
		COMMAND=$(echo "$COMMAND" | cut -d" " -f2-) # Remove the END
	fi
	echo -e "
	#!/bin/bash
	for((x=$start; x<=$end; x++))
	do
		CLISHORTCUTOPTIONITERABLE=\$x
		$SETUPVARS
		$COMMAND
	done
	" > $CLISHORTCUTTMPFILE
}

function shortCutLoopf() {
	# Creates the shortcut that iterates through a file
	FILE=$(cat $OPTION)
	FILE=$(echo -e "$FILE" | tr '\n' ' ')
	echo -e "
	#!/bin/bash
	for CLISHORTCUTOPTIONITERABLE in $FILE
	do 
		$SETUPVARS
		$COMMAND
	done

	" > $CLISHORTCUTTMPFILE
}

function checkShortCut() {
	# Checks what shortcut to use and executes that shortcut
	shopt -s nocasematch
	replaceIterableSyntax
	case "$SHORTCUT" in
		for)
			shortCutFor ;;
		while)
			shortCutWhile ;;
		loop)
			shortCutLoop ;;
		loopf) 
			shortCutLoopf ;;
		*)
			echo "Incorrect usage"
	esac
 
	source "$CLISHORTCUTTMPFILE"
}

function cliShortCutCleanUp() {
	if ((NOCLEANUP!=1)); then
		rm "$CLISHORTCUTTMPFILE"
	fi
}

function --() {
	# Main function
	# Cleanup on exit
	trap cliShortCutCleanUp SIGTERM SIGHUP SIGINT SIGQUIT EXIT
	local unixtimestamp=`date +%s`
	CLISHORTCUTTMPFILE="/tmp/cli-shortcut-$unixtimestamp"
	parseargs "$@"
	checkShortCut
}
-- "$@"
