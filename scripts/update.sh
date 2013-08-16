#!/bin/sh
# Usage:
#  ./update.sh URL
#
#  Add script execution to /usr/bin/enigma2_pre_start.sh | /usr/bin/enigma2.sh

if [ $# != 1 ] 
then 
	echo "usage '$0 URL'"
	exit 0
fi

FILE=update.zip
WORKING_PATH=/var/e2code
DIRECTORY=channels
CHECKSUM_LOCAL=CHECKSUM
CHECKSUM_LATEST=CHECKSUM_LATEST

updateSettings() {
	echo "Updating settings"
	echo "Downloading latest stable release"
	wget -O "$WORKING_PATH/$FILE" "$1/$FILE"
	
	echo "Checking downloaded file"
	if [ -f "$WORKING_PATH/$FILE" ]
	then
		echo "Cleaning directory"
		if [ -d "$WORKING_PATH/$DIRECTORY" ]
		then
			cd "$WORKING_PATH/$DIRECTORY"
			rm -rf *
			cd -
		else
			mkdir -p "$WORKING_PATH/$DIRECTORY"
		fi

		echo "Extracting..."
		unzip "$WORKING_PATH/$FILE" -d "$WORKING_PATH/$DIRECTORY"

		echo "Removing downloaded archive file."
		rm "$WORKING_PATH/$FILE"
	else
		echo "Failed downloading file!"
		exit 0
	fi
	
	echo "[DUMP] killall enigma2"
	local FILES=$(ls -lh "$WORKING_PATH/$DIRECTORY/userbouquet.*" | awk '{ print $9 }')
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
	FILES=$(ls -lh "$WORKING_PATH/$DIRECTORY" | awk '{ print $9 }')
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
			echo "cp -f $WORKING_PATH/$DIRECTORY/$base_i $target"
			cp -f "$WORKING_PATH/$DIRECTORY/$base_i" "$target"
		fi
	done
	echo "[DUMP] ./usr/bin/enigma2"
}

echo "Downloading latest CHECKSUM"
wget -O "$WORKING_PATH/$CHECKSUM_LATEST" "$1/$CHECKSUM_LOCAL"
if [ -f "$WORKING_PATH/$CHECKSUM_LATEST" ]
then
	if [ -f "$WORKING_PATH/$CHECKSUM_LOCAL" ]
	then
		if diff "$WORKING_PATH/$CHECKSUM_LOCAL" "$WORKING_PATH/$CHECKSUM_LATEST" > /dev/null
		then
			echo "No update required"
		else
			updateSettings "$1"
			echo "Updating latest CHECKSUM"
			rm "$WORKING_PATH/$CHECKSUM_LOCAL"
			mv "$WORKING_PATH/$CHECKSUM_LATEST" "$WORKING_PATH/$CHECKSUM_LOCAL"
		fi
	else
		updateSettings "$1"
		echo "Updating latest CHECKSUM"
		mv "$WORKING_PATH/$CHECKSUM_LATEST" "$WORKING_PATH/$CHECKSUM_LOCAL"
	fi
else
	echo "Latest CHECKSUM missing! Aborting..."
	exit 1
fi