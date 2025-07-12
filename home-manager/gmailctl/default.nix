{ config, lib, pkgs, ... }:

let
  # Python with required packages for analysis scripts
  pythonWithPackages = pkgs.python3.withPackages (ps: with ps; [
    google-api-python-client
    google-auth
    google-auth-oauthlib
    google-auth-httplib2
  ]);
in
{
  home.packages = [
    pkgs.gmailctl
    pythonWithPackages
  ];

  # Shell aliases for convenience
  programs.zsh.shellAliases = {
    gcp = "gmailctl --config ~/.gmailctl-personal";
    gcw = "gmailctl --config ~/.gmailctl-work";
  };

  # Analysis script
  home.file.".local/bin/gmail-analyze" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Run Gmail analysis on the current account
      
      SCRIPT_DIR="$HOME/nix-config/home-manager/gmailctl/scripts"
      
      if [ ! -f "$SCRIPT_DIR/deep-analyze.py" ]; then
        echo "Error: Analysis script not found at $SCRIPT_DIR/deep-analyze.py"
        exit 1
      fi
      
      ${pythonWithPackages}/bin/python "$SCRIPT_DIR/deep-analyze.py" "$@"
    '';
  };

  # Add to PATH
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Automatically sync configs on activation
  home.activation.gmailctlSync = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Copy personal config
    if [ -d "$HOME/.gmailctl-personal" ]; then
      $DRY_RUN_CMD cp ${./configs/personal.jsonnet} $HOME/.gmailctl-personal/config.jsonnet
      # Remove the lib directory/symlink completely before copying
      $DRY_RUN_CMD rm -rf $HOME/.gmailctl-personal/lib || true
      $DRY_RUN_CMD mkdir -p $HOME/.gmailctl-personal/lib
      $DRY_RUN_CMD cp -r ${./lib}/* $HOME/.gmailctl-personal/lib/
      $DRY_RUN_CMD echo "gmailctl: Synced personal config"
    fi

    # Copy work config
    if [ -d "$HOME/.gmailctl-work" ]; then
      $DRY_RUN_CMD cp ${./configs/work.jsonnet} $HOME/.gmailctl-work/config.jsonnet
      # Remove the lib directory/symlink completely before copying
      $DRY_RUN_CMD rm -rf $HOME/.gmailctl-work/lib || true
      $DRY_RUN_CMD mkdir -p $HOME/.gmailctl-work/lib
      $DRY_RUN_CMD cp -r ${./lib}/* $HOME/.gmailctl-work/lib/
      $DRY_RUN_CMD echo "gmailctl: Synced work config"
    fi
  '';
}
