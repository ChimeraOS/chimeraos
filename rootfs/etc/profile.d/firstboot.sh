if test "$(id -u)" -gt "0" && test -d "$HOME"; then
    if test ! -e "$HOME"/.config/autostart/org.chimeraos.firstboot.desktop; then
        mkdir -p "$HOME"/.config/autostart
        cp -f /usr/share/.config/autostart/org.chimeraos.firstboot.desktop "$HOME"/.config/autostart
    fi
fi