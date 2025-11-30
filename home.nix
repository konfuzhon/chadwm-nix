{ config, pkgs, ... }:

let
  dots = "${config.home.homeDirectory}/nixos-dots/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
in

{
  home.username = "atom";
  home.homeDirectory = "/home/atom";
  programs.git.enable = true;
  home.stateVersion = "25.05";
  
  # Ensure your custom configurations are symlinked from your dotfiles
  xdg.configFile."nvim" = {
      source = create_symlink "${dots}/nvim/";
      recursive = true;
  };
  xdg.configFile."qtile" = {
      source = create_symlink "${dots}/qtile/";
      recursive = true;
  };
  # Ensure you have your custom EWW configuration here
  xdg.configFile."eww" = {
      source = create_symlink "${dots}/eww/";
      recursive = true;
  };

  # Packages
  home.packages = with pkgs; [
    neovim
    ripgrep
    nil
    nixpkgs-fmt
    nodejs
    gcc
    # dwm now points to your custom chadwm package
    dwm 
    rofi  # rofi executable
    picom # picom executable
    feh
    dunst # dunst executable
    alacritty
    eww   # eww executable
  ];

  # REMOVED: services.xserver.windowManager.dwm.enable = true;
  
  # Use Home Manager's xsession to launch the custom wrapper script
  xsession.enable = true;
  xsession.windowManager.command = "${pkgs.dwm}/bin/chadwm-session"; # <- Use the new wrapper!

  # Enable and configure accompanying services
  programs.rofi.enable = true;
  programs.dunst.enable = true;
  
  services.picom = {
    enable = true;
    settings = {
      vSync = true;
      shadow = true;
      # Note: Add all your specific Picom settings here!
    };
  };
}