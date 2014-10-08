#!/bin/bash
# Date : (2014-10-04 02-53)
# Last revision : (2014-10-09 00-20)
# Wine version used : 1.7.21
# Distribution used to test : Arch Linux
# Author : Arza

[ -z "$PLAYONLINUX" ] && exit 0
source "$PLAYONLINUX/lib/sources"

TITLE="$(eval_gettext 'Divinity: Original Sin (GoG release)')"
SHORTCUT="$TITLE"
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

POL_Wine_SelectPrefix "$PREFIX"
POL_Wine_PrefixCreate "$WORKING_WINE_VERSION"

POL_SetupWindow_VMS "512"

POL_System_TmpCreate "$PREFIX"

POL_Call POL_Install_d3dcompiler_43
POL_Call POL_Install_d3dx9
POL_Call POL_Install_d3dx9_43
POL_Call POL_Install_mono26
POL_Call POL_Install_vcrun2008
POL_Call POL_Install_dotnet35sp1

Set_OS winxp

POL_SetupWindow_message "$(eval_gettext 'The script will ask you which version you want to install.')\\n
$(eval_gettext 'If you don'\''t know, just refer to the filename of your setup file:')\\n
setup_divinity_original_sin_2.3.0.6.exe: 1.0.57\\n
setup_divinity_original_sin_2.5.0.11.exe: 1.0.107\\n
setup_divinity_original_sin_2.11.0.21.exe: 1.0.177\\n\\n
$(eval_gettext 'When the GoG installer ask you to install dotnet, hit cancel. You might have a few errors, but the game will still run -- flawlessly.')\\n
$(eval_gettext 'Also, if you'\''re having graphic issues with the GoG installer, consider installing lib32-libpng12.')" "$TITLE"

POL_SetupWindow_menu "$(eval_gettext 'Which version do you want to install ?')" "$TITLE" "1.0.57~1.0.107~1.0.177" "~"
VERSION="$APP_ANSWER"

if [[ "$VERSION" = "1.0.57" ]]; then
    install_file "setup_divinity_original_sin_2.3.0.6.exe" "35948232" "a1597f3975bf38ea44632cd73b6b6bf2"

    install_file "patch_divinity_original_sin_2.3.0.7.exe" "290033752" "0a002693070732362879d81246c85954"
elif [[ "$VERSION" = "1.0.107" ]]; then
    install_file "setup_divinity_original_sin_2.5.0.11.exe" "35961472" "c6c44a836df634c2bedc6bd4c15a9b02"

    install_file "patch_divinity_original_sin_2.7.0.14.exe" "73179704" "3eb062170af754d15a18e1c61654803e"
elif [[ "$VERSION" = "1.0.177" ]]; then
    install_file "setup_divinity_original_sin_2.11.0.21.exe" "36028944" "82e7d53475592d7cdeef2e5d3ad6a878"

    install_file "patch_divinity_original_sin_2.12.0.23.exe" "22301168" "c9298dadd23ffc25886dcdfe0fa5f02c"
fi

POL_SetupWindow_message "$(eval_gettext '$TITLE has been successfully installed.')" "$TITLE"
POL_SetupWindow_message "$(eval_gettext 'Please note that during the game is running, your keyboard layout will be changed to qwerty (US).')\\n
$(eval_gettext 'Your old layout will be restored once the game is closed.')\\n
$(eval_gettext 'Also note you can run the configurator to change in-game language, but launching the game from it might fail.')" "$TITLE"

POL_System_TmpDelete

POL_Wine_reboot

POL_Shortcut "EoCApp.exe" "$SHORTCUT"
# Injecting a script to retrieve keyboard layout
POL_Shortcut_InsertBeforeWine "$SHORTCUT" 'layout=$(setxkbmap -print | awk -F"+" '\''/xkb_symbols/ {print $2}'\'')'
POL_Shortcut_InsertBeforeWine "$SHORTCUT" "setxkbmap us"
# Insert after wine to restore keyboard layout, based on POL_Shortcut_InsertBeforeWine
after='setxkbmap "$layout"'
POL_Debug_Message "Inserting after POL_Wine : $after"
COMMANDS="$after" perl -ni -e '
print;
if (!$done && /^POL_Wine /) {
    print "$ENV{COMMANDS}\n";
    $done=1
}' "$REPERTOIRE/shortcuts/$SHORTCUT"

POL_SetupWindow_Close

cat << _EOF_ > "$REPERTOIRE/configurations/configurators/$SHORTCUT"
#!/bin/bash
[ -z "\$PLAYONLINUX" ] && exit 0
source "\$PLAYONLINUX/lib/sources"
export WINEPREFIX="\$REPERTOIRE/wineprefix/$PREFIX"
export WINEDEBUG="-all"
cd "\$WINEPREFIX/drive_c/GOG Games/Divinity - Original Sin"
POL_Wine LanguageSetup.exe "$@"
_EOF_

exit
