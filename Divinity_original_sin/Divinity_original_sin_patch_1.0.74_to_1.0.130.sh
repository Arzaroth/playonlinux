#!/bin/bash
# Date : (2014-10-08 23-27)
# Last revision : (2014-10-08 23-27)
# Wine version used : 1.7.21
# Distribution used to test : Arch Linux
# Author : Arza

[ -z "$PLAYONLINUX" ] && exit 0
source "$PLAYONLINUX/lib/sources"

TITLE="$(eval_gettext 'Divinity: Original Sin (GoG release) 1.0.74 to 1.0.130 patch')"
ORIG_TITLE="$(eval_gettext 'Divinity: Original Sin (GoG release)')"
PREFIX="DivinityOriginalSin_gog"
WORKING_WINE_VERSION="1.7.21"

# deeply inspired by petch work
check_file() {
    local FILE="$1" EXPECTED_NAME="$2" EXPECTED_MD5="$4"
    local -i EXPECTED_SIZE="$3"

    POL_SetupWindow_wait "$(eval_gettext 'Checking file...')" "$TITLE"
    local NAME="$(basename "$FILE")" MD5="$(POL_MD5_file "$FILE")"
    local -i SIZE="$(wc -c <"$FILE")"

    if [[ "$SIZE" -ne "$EXPECTED_SIZE" || "$MD5" != "$EXPECTED_MD5" ]]; then
        POL_Debug_Error "$(eval_gettext 'Install file mismatch.\n
Either your install file is corrupted, or is not the expected version.\n
This script cannot guarantee that installation will work correctly. Please report success or failure to PlayOnLinux forums.')\n
$(eval_gettext 'Name:') $NAME ($(eval_gettext 'expected') $EXPECTED_NAME)\n
$(eval_gettext 'Size:') $SIZE ($(eval_gettext 'expected') $EXPECTED_SIZE)\n
$(eval_gettext 'MD5:') $MD5 ($(eval_gettext 'expected') $EXPECTED_MD5)"
        POL_SetupWindow_question "$(eval_gettext 'Continue?')" "$TITLE"
        [ "$APP_ANSWER" != "TRUE" ] && POL_Debug_Fatal "$(eval_gettext 'Not the expected file')"
    fi
}

install_file() {
    local FILE_NAME="$1" FILE_MD5="$3"
    local -i FILE_SIZE="$2"

    POL_SetupWindow_browse "$(eval_gettext 'Please now provide $FILE_NAME.')" "$TITLE"
    FILE="$APP_ANSWER"

    check_file "$FILE" "$FILE_NAME" "$FILE_SIZE" "$FILE_MD5"

    POL_SetupWindow_wait "$(eval_gettext 'Please wait while $TITLE is installed.')" "$TITLE"
    POL_Wine start /unix "$APP_ANSWER" || POL_Debug_Fatal "$(eval_gettext 'Error during the installation')"
    POL_Wine_WaitExit "$TITLE"
}

POL_SetupWindow_Init
POL_Debug_Init

POL_SetupWindow_presentation "$TITLE" "Larian Studios" "http://www.larian.com/" "Arza" "$PREFIX"

if [ "$(POL_Wine_PrefixExists "$PREFIX")" = "False" ]
then
    POL_SetupWindow_message "$(eval_gettext '$ORIG_TITLE is not installed. It'\''s required to install it before running the patch.')" "$TITLE"
    POL_SetupWindow_Close
    exit
fi
POL_Wine_SelectPrefix "$PREFIX"

install_file "patch_divinity_original_sin_universal_update_2.9.0.16.exe" "1510352696" "e9c7a94028f00e96c8a91dd18dc1ae8e"

POL_SetupWindow_message "$(eval_gettext '$TITLE has been successfully installed.')" "$TITLE"

POL_Wine_reboot

POL_SetupWindow_Close

exit
