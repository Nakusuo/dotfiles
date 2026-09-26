source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
starship init fish | source

fish_add_path /home/nakusu/.spicetify


# Added by Antigravity CLI installer
set -gx PATH "/home/nakusu/.local/bin" $PATH

# --- Android / React Native (Claude) ---
set -gx ANDROID_HOME "$HOME/Android/Sdk"
set -gx ANDROID_SDK_ROOT "$ANDROID_HOME"
set -gx JAVA_HOME /home/nakusu/.local/lib/jdk17
fish_add_path -g "$JAVA_HOME/bin" "$ANDROID_HOME/cmdline-tools/latest/bin" "$ANDROID_HOME/platform-tools" "$ANDROID_HOME/emulator"
