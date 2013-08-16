#!/bin/sh
# Usage:
#  ./update.sh URL

if [ $# != 1 ] 
then 
	echo "usage '$0 URL'"
	exit 0
fi

FILE=update.zip
DIRECTORY=/var/e2code/channels
CHECKSUM_LOCAL=CHECKSUM
CHECKSUM_LATEST=CHECKSUM_LATEST

updateSettings() {
	echo "Updating settings"
	echo "Downloading latest stable release"
	wget -O "$FILE" "$1/$FILE"
	
	echo "Checking downloaded file"
	if [ -f "$FILE" ]
	then
		echo "Cleaning directory"
		if [ -d "$DIRECTORY" ]
		then
			cd "$DIRECTORY"
			rm -rf *
			cd ..
		else
			mkdir "$DIRECTORY"
		fi

		echo "Extracting..."
		unzip "$FILE" -d "$DIRECTORY"

		echo "Removing downloaded archive file."
		rm $FILE
	else
		echo "Failed downloading file!"
		exit 0
	fi
	
	echo "killall enigma2"
	local FILES=$(ls -lh $DIRECTORY/userbouquet.* | awk '{ print $9 }')
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
			echo "rm $i"
			rm "$i"
		fi
	done
	FILES=$(ls -lh $DIRECTORY | awk '{ print $9 }')
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
			echo "cp -f $i $target"
			cp -f "$i" "$target"
		fi
	done
	echo "[DUMP] ./usr/bin/enigma2"
}

echo "Downloading latest CHECKSUM"
wget -O "$CHECKSUM_LATEST" "$1/$CHECKSUM_LOCAL"
if [ -f $CHECKSUM_LATEST ]
then
	if [ -f $CHECKSUM_LOCAL ]
	then
		if diff "$CHECKSUM_LOCAL" "$CHECKSUM_LATEST" > /dev/null
		then
			echo "No update required"
		else
			updateSettings "$1"
			echo "Updating latest CHECKSUM"
			rm "$CHECKSUM_LOCAL"
			mv "$CHECKSUM_LATEST" "$CHECKSUM_LOCAL"
		fi
	else
		updateSettings "$1"
		echo "Updating latest CHECKSUM"
		rm "$CHECKSUM_LOCAL"
		mv "$CHECKSUM_LATEST" "$CHECKSUM_LOCAL"
	fi
else
	echo "Latest CHECKSUM missing! Aborting..."
	exit 1
fi