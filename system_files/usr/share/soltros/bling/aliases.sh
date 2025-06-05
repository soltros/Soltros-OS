#!/usr/bin/env sh
# SoltrOS: Shell Aliases Setup Script
# Compatible with both bash and zsh

# Detect shell
[ -n "$BASH_VERSION" ] && shell="bash"
[ -n "$ZSH_VERSION" ] && shell="zsh"

# Setup conditional aliases for known tools
for cmd in eza bat gio; do
  command -v "$cmd" >/dev/null && {
    case "$cmd" in
      bat)
        alias cat='bat'
        alias catp='bat -p'
        ;;
      eza)
        alias ls='eza'
        alias ll='eza -l --icons=auto --group-directories-first'
        alias l.='eza -d .*'
        alias l1='eza -1'
        ;;
      gio)
        alias dlsrcam='gio mount -s gphoto2 & wait $last_pid && gphoto2 --stdout --capture-movie | ffmpeg -i - -vcodec rawvideo -pix_fmt yuv420p -threads 0 -f v4l2 /dev/video0'
        ;;
    esac
  }
done

# Flatpak app aliases (SoltrOS default installs)
alias code='flatpak run com.visualstudio.code'
alias vlc='flatpak run org.videolan.VLC'
alias gimp='flatpak run org.gimp.GIMP'
alias qb='flatpak run org.qbittorrent.qBittorrent'

# OpenStreetMap progress GIFs (optional tool aliases)
alias osm_mp4='ffmpeg -framerate 1 -pattern_type glob -i "*.png" -c:v libx264 -r 30 -pix_fmt yuv420p out.mp4'
alias osm_gif='ffmpeg -i out.mp4 -vf "fps=1,scale=1920:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 out.gif'
alias osm_progress='osm_mp4 && osm_gif'

# SoltrOS MOTD alias (just for fun)
alias welcome='cat /etc/motd'

