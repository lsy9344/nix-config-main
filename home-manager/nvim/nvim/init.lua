-- Apply NixOS-specific fixes first
require("config.nixos-fixes")

-- Set up clipboard before anything else
require("config.clipboard")

-- Ensure git is available for plugins
require("config.git-setup")

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
