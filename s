#!/bin/bash

# Parse thru the arguments
function parseargs() {
	# If we're given less than 3 arguments show an error
	if (($# < 3)); then
		echo "Incorrect usage"
		NOCLEANUP=1 # Don't try to delete a file that doesn't exist
		exit 1
	fi

	local x=1
	while (($# > 0)); do # While there are arguments left to parse
		if((x==1)); then
			SHORTCUT="$1" # Contains the shortcut we will use
		elif  ((x==2)); then
			#echo "$1"
			if [ -f "$1" ]; then # If this option is a File
				FILES+="$1\n"
				if [ -d "$2" ]; then
					x=1
				elif [ -f "$2" ] && [ -z $(echo -e "$FILES" | grep "^$2$") ]; then 
					x=1 # The next file is a file so we'll have to do this again
				else
					x=2 # Don't enter this logic chain again
				fi
			else
				OPTION="$1"
			fi
		else
			if [ "$FILES" ]; then OPTION="$FILES"; fi
			COMMAND="$@" # Contains everything else
			break
		fi
		((x++))
		shift # go to the next command line arg
	done
}

function replaceIterableSyntax() {
	# Parse out our special syntax for the variables we will use
	COMMAND=$(echo -e "$COMMAND" | sed 's/{}/\"\$CLISHORTCUTOPTIONITERABLE"/g')
	COMMAND=$(echo -e "$COMMAND" | sed 's/{basename}/\"\$CLISHORTCUTFILENAME\"/g')
	COMMAND=$(echo -e "$COMMAND" | sed 's/{ext}/\"\$CLISHORTCUTFILEEXT\"/g')
	COMMAND=$(echo -e "$COMMAND" | sed 's/{dirname}/\"\$CLISHORTCUTDIRNAME\"/g')
	COMMAND=$(echo -e "$COMMAND" | sed 's/@err@/\; echo -n $?/g')
	COMMAND=$(echo -e "$COMMAND" | sed 's/@errnl@/\; echo $?/g')
	COMMAND=$(echo -e "$COMMAND" | sed 's/@@/\;/g' | sed 's/\\@/@/g')
	COMMAND=$(echo -e "$COMMAND" | sed 's/%%/\|/g' | sed 's/\\%/%/g')

	# Sets up the vars for our DSL
	SETUPVARS=" 
		# we cut . if it happens to be the first character and then get every character after the first .
		CLISHORTCUTFILEEXT=\$(basename \"\$CLISHORTCUTOPTIONITERABLE\" | sed 's/^\.//' | cut -d . -f2-)

		# If we removed the leading . then lets put it back
		CLISHORTCUTFILEEXT=\$(echo -e \$CLISHORTCUTFILEEXT | sed 's/^\([a-z]\)/\.\1/g')

		# When we have a scenario like .tar.gz we may end up with a trailing .
		CLISHORTCUTFILENAME=\$(basename \$CLISHORTCUTOPTIONITERABLE \$CLISHORTCUTFILEEXT)

		CLISHORTCUTDIRNAME=\$(dirname \$CLISHORTCUTOPTIONITERABLE)
	"
}

function shortCutFor() {
	# Creates the shortcut for iteratable in OPTION
	echo -e "
	#!/bin/bash
	IFS=\$'\n' 
	cleanOption=$(echo -e \'$OPTION\')
	for CLISHORTCUTOPTIONITERABLE in \$cleanOption
	do 
		$SETUPVARS
		$COMMAND
	done

	" > $CLISHORTCUTTMPFILE
}

function shortCutWhile() {
	# Creates the shourtcut while [[ logic ]] 
	# This feels not unique and outclassed by others
	# TODO: Find a purpose for while/until with a better syntax
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
	# This should be a safe assumption 
	# because generally there won't or at least shouldn't be commands that are all numbers
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
	OPTION=$(echo -e "$OPTION" | tr -d ' ')
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
		gloop)
			shortCutgloop ;;
		*)
			echo "Incorrect usage"
			NOCLEANUP=1
			exit 1
	esac
 
	source "$CLISHORTCUTTMPFILE"
}

function cliShortCutCleanUp() {
	# No clean up is set to 1 if the used incorrect syntax
	if ((NOCLEANUP!=1)) && [ -f "$CLISHORTCUTTMPFILE" ]; then 
		rm "$CLISHORTCUTTMPFILE"
	fi
}

function mainFunct() {
	# Main function
	# Cleanup on exit
	trap cliShortCutCleanUp SIGTERM SIGHUP SIGINT SIGQUIT EXIT
	local unixtimestamp=`date +%s`
	CLISHORTCUTTMPFILE="/tmp/cli-shortcut-$unixtimestamp"
	parseargs "$@"
	checkShortCut
}
mainFunct "$@"
