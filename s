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
	echo -e "$1" | sed 's/{}/\"$CLISHORTCUTOPTIONITERABLE"/g'
}

function shortCutFor() {
	# Creates the shortcut for iteratable in OPTION
	echo -e "
	#!/bin/bash
	for CLISHORTCUTOPTIONITERABLE in $OPTION
	do 
		$COMMAND
	done

	" > $CLISHORTCUTTMPFILE
	less $CLISHORTCUTTMPFILE
}

function shortCutWhile() {
	# Creates the shourtcut while [[ logic ]] 
	echo -e "
	#!/bin/bash
	while [[ $OPTION ]]
	do 
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
		$COMMAND
	done
	" > $CLISHORTCUTTMPFILE
}

function checkShortCut() {
	# Checks what shortcut to use and executes that shortcut
	shopt -s nocasematch
	COMMAND=$(replaceIterableSyntax "$COMMAND")
	if [[ "$SHORTCUT" == "for" ]]; then
		shortCutFor
	elif [[ "$SHORTCUT" == "while" ]]; then
		shortCutWhile
	elif [[ "$SHORTCUT" == "loop" ]]; then
		shortCutLoop
	fi
 
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
export -f --
-- "$@"