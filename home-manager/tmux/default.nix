{ config, lib, pkgs, ... }:

with lib;

let
  # Remote link opening script for server side
  remoteLinkOpenScript = pkgs.writeScriptBin "remote-link-open" ''
    #!${pkgs.bash}/bin/bash
    # Open links on the client machine when running on a remote server
    
    set -euo pipefail
    
    if [ $# -eq 0 ]; then
      echo "Usage: remote-link-open <url>"
      exit 1
    fi
    
    URL="$1"
    
    # Check if we're in an SSH session
    if [ -z "''${SSH_CLIENT:-}" ]; then
      echo "Not in an SSH session, opening locally..."
      if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$URL"
      elif command -v open >/dev/null 2>&1; then
        open "$URL"
      else
        echo "No suitable browser opener found"
        exit 1
      fi
      exit 0
    fi
    
    # Get the client IP
    CLIENT_IP=$(echo $SSH_CLIENT | awk '{print $1}')
    
    # Use OSC 8 hyperlink sequence to send URL to client
    printf '\033]8;;%s\033\\Click to open: %s\033]8;;\033\\\n' "$URL" "$URL"
    
    echo "Sent link to client terminal: $URL"
  '';

in
{
  config = {
    programs.tmux = {
      enable = true;
      baseIndex = 1;
      historyLimit = 50000;
      keyMode = "vi";
      mouse = true;
      escapeTime = 0;
      terminal = "xterm-256color";

      plugins = with pkgs.tmuxPlugins; [
        sensible
        yank
        cpu
        net-speed
        {
          plugin = catppuccin;
          extraConfig = ''
            # Catppuccin settings
            set -g @catppuccin_flavor 'mocha'
            set -g @catppuccin_window_status_style "rounded"
            
            # Ensure transparent backgrounds where possible
            set -g status-bg default
            set -g message-style "fg=#94e2d5,bg=default"
            set -g message-command-style "fg=#94e2d5,bg=default"
            
            # Window settings
            set -g @catppuccin_window_left_separator ""
            set -g @catppuccin_window_right_separator " "
            set -g @catppuccin_window_middle_separator " █"
            set -g @catppuccin_window_number_position "right"
            
            set -g @catppuccin_window_default_fill "number"
            set -g @catppuccin_window_default_text "#{window_name}"
            
            set -g @catppuccin_window_current_fill "number"
            set -g @catppuccin_window_current_text "#{window_name}"
          '';
        }
      ];

      extraConfig = ''
        # Enable true color support
        set -ga terminal-overrides ",xterm-256color:Tc"
        set -ga terminal-overrides ",xterm-kitty:Tc"
        set -as terminal-features ",xterm-256color:RGB"
        set -as terminal-features ",xterm-kitty:RGB"
        
        # Ensure proper color rendering
        set -g default-terminal "xterm-256color"
        set -ag terminal-overrides ",xterm*:RGB"
        
        # General Settings
        setw -g pane-base-index 1
        set -g renumber-windows on
        set -g set-titles on
        set -g focus-events on
        set -g status-position bottom
        setw -g automatic-rename on
        setw -g allow-rename on
        set -g automatic-rename-format '#{pane_title}'
        
        # Update environment variables in new shells
        # Explicitly exclude CLAUDE_CODE_NTFY_WRAPPED from being passed to child shells
        set -g update-environment "DISPLAY SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY TMUX_DEVSPACE"
        
        # Set default command to unset CLAUDE_CODE_NTFY_WRAPPED before starting the shell
        set -g default-command "unset CLAUDE_CODE_NTFY_WRAPPED; exec $SHELL"
        
        # Simple terminal title
        set -g set-titles-string "#S:#I:#W"
        
        # Status line configuration
        set -g status-right-length 100
        set -g status-left-length 100
        set -g status-left ""
        
        # Right side status with system monitoring
        set -g status-right \
          "#[fg=#94e2d5]#{E:@catppuccin_status_left_separator}#[fg=#11111b,bg=#94e2d5]󰈀  #{E:@catppuccin_status_middle_separator}#[fg=#cdd6f4,bg=#313244] #(${pkgs.tmuxPlugins.net-speed}/share/tmux-plugins/net-speed/scripts/net_speed.sh)#[fg=#313244]#{E:@catppuccin_status_right_separator}"
        
        set -ag status-right \
          "#[fg=#f9e2af]#{E:@catppuccin_status_left_separator}#[fg=#11111b,bg=#f9e2af]#{E:@catppuccin_cpu_icon} #{E:@catppuccin_status_middle_separator}#[fg=#cdd6f4,bg=#313244] #(${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/scripts/cpu_percentage.sh)#[fg=#313244]#{E:@catppuccin_status_right_separator}"
        
        set -g @catppuccin_ram_icon " "
        
        set -ag status-right \
          "#[fg=#cba6f7]#{E:@catppuccin_status_left_separator}#[fg=#11111b,bg=#cba6f7]  #{E:@catppuccin_status_middle_separator}#[fg=#cdd6f4,bg=#313244] #(${pkgs.tmuxPlugins.cpu}/share/tmux-plugins/cpu/scripts/ram_percentage.sh)#[fg=#313244]#{E:@catppuccin_status_right_separator}"

        # Pane borders - Catppuccin Mocha colors
        set -g pane-border-style "fg=#313244"
        set -g pane-active-border-style "fg=#89b4fa"
        
        # Window and pane styles - ensure no background is set
        set -g window-style 'default'
        set -g window-active-style 'default'
        
        # Key bindings
        unbind C-b
        set -g prefix C-a
        bind C-a send-prefix
        
        # Window/pane creation with current path
        bind c new-window -c "#{pane_current_path}"
        bind '"' split-window -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        
        # Vim-style pane navigation
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R
        
        # Quick window switching
        bind-key -n M-1 select-window -t 1
        bind-key -n M-2 select-window -t 2
        bind-key -n M-3 select-window -t 3
        bind-key -n M-4 select-window -t 4
        bind-key -n M-5 select-window -t 5
      '';
    };

    home.packages = with pkgs; [
      remoteLinkOpenScript
    ];

    # Set up environment for remote link opening
    home.sessionVariables = {
      BROWSER = "remote-link-open";
      DEFAULT_BROWSER = "remote-link-open";
    };
  };
}
