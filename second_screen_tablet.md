sudo pacman -S wayvnc android-tools

hyprctl output create headless tabmon
ok
hyprctl keyword monitor tabmon,2960x1848@60,auto-right,2
ok
wayvnc -o tabmon 127.0.0.1 5900


# Set screen timeout to the Android maximum (~24.8 days)
adb shell settings put system screen_off_timeout 2147483647
When you're done and want normal behavior back:


# Reset to 5 minutes
adb shell settings put system screen_off_timeout 300000


