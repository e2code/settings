#!/bin/sh
# Usage:
#  ./update.sh URL

if [ $# != 1 ] 
then 
	echo "usage '$0 URL'"
	exit 0
fi

FILE=update.zip
PATH=/var/e2code
DIRECTORY=channels
CHECKSUM_LOCAL=CHECKSUM
CHECKSUM_LATEST=CHECKSUM_LATEST

updateSettings() {
	echo "Updating settings"
	echo "Downloading latest stable release"
	wget -O "$PATH/$FILE" "$1/$FILE"
	
	echo "Checking downloaded file"
	if [ -f "$PATH/$FILE" ]
	then
		echo "Cleaning directory"
		if [ -d "$PATH/$DIRECTORY" ]
		then
			cd "$PATH/$DIRECTORY"
			rm -rf *
			cd -
		else
			mkdir -p "$PATH/$DIRECTORY"
		fi

		echo "Extracting..."
		unzip "$PATH/$FILE" -d "$PATH/$DIRECTORY"

		echo "Removing downloaded archive file."
		rm "$PATH/$FILE"
	else
		echo "Failed downloading file!"
		exit 0
	fi
	
	echo "killall enigma2"
	local FILES=$(ls -lh "$PATH/$DIRECTORY/userbouquet.*" | awk '{ print $9 }')
	local CURRENT_FILES=$(ls -lh /etc/enigma2/userbouquet.* | awk '{ print $9 }')
	for i in $CURRENT_FILES
	do
		local base_i=$(basename $i)
		local IS_SET=0
		for j in $FILES
		do
			local base_j=$(basename $j)
			if [ $base_i == $base_j ]
			then
				IS_SET=1
				break
			else
				continue
			fi
		done
		if [ $IS_SET == 0 ]
		then
			echo "rm /etc/enigma2/$base_i"
			rm "/etc/enigma2/$base_i"
		fi
	done
	FILES=$(ls -lh "$PATH/$DIRECTORY" | awk '{ print $9 }')
	for i in $FILES
	do
		local base_i=$(basename $i)
		local target="/etc/enigma2"
		case "$base_i" in
		"satellites.xml")
			target="/etc/tuxbox"
			;;
		"$CHECKSUM_LOCAL")
			target=0
			;;
		*)
			;;
		esac
		if [ $target != 0 ] 
		then 
			echo "cp -f $PATH/$DIRECTORY/$base_i $target"
			cp -f "$PATH/$DIRECTORY/$base_i" "$target"
		fi
	done
	echo "[DUMP] ./usr/bin/enigma2"
}

echo "Downloading latest CHECKSUM"
wget -O "$PATH/$CHECKSUM_LATEST" "$1/$CHECKSUM_LOCAL"
if [ -f "$PATH/$CHECKSUM_LATEST" ]
then
	if [ -f "$PATH/$CHECKSUM_LOCAL" ]
	then
		if diff "$PATH/$CHECKSUM_LOCAL" "$PATH/$CHECKSUM_LATEST" > /dev/null
		then
			echo "No update required"
		else
			updateSettings "$1"
			echo "Updating latest CHECKSUM"
			rm "$PATH/$CHECKSUM_LOCAL"
			mv "$PATH/$CHECKSUM_LATEST" "$PATH/$CHECKSUM_LOCAL"
		fi
	else
		updateSettings "$1"
		echo "Updating latest CHECKSUM"
		rm "$PATH/$CHECKSUM_LOCAL"
		mv "$PATH/$CHECKSUM_LATEST" "$PATH/$CHECKSUM_LOCAL"
	fi
else
	echo "Latest CHECKSUM missing! Aborting..."
	exit 1
fi