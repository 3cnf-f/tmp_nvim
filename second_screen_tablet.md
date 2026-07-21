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

add to hyprland config so that win+ these numberss change desktop on tablet
# Dedicated tablet workspaces — always open on tabmon
workspace = 6, monitor:tabmon
workspace = 7, monitor:tabmon
workspace = 8, monitor:tabmon

Edit ~/.config/waybar/config.jsonc (or config.json), find the wlr/workspaces block, and change it to show all workspaces persistently:

    },
    "persistent-workspaces": {
      "1": ["eDP-1"],
      "2": ["eDP-1"],
      "3": ["eDP-1"],
      "4": ["eDP-1"],
      "5": ["eDP-1"],
      "6": ["tabmon"],
      "7": ["tabmon"],
      "8": ["tabmon"]
    }


