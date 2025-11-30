{
  description = "NixOS with a side of chadwm";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      chadwm_overlay = final: prev: {
        # Define a custom package that contains the DWM binary AND the scripts
        chadwm = prev.stdenv.mkDerivation rec {
          pname = "chadwm";
          version = "git";
          
          src = prev.fetchFromGitHub {
            owner = "siduck"; 
            repo = "chadwm";
            # Git Commit Hash (40 characters) - REPLACE THIS
            rev = "0000000000000000000000000000000000000000"; 
            # SHA-256 Hash - REPLACE THIS (use "" first)
            sha256 = "";
          };

          # Tell the build process that the WM source is in the 'chadwm' subdirectory
          sourceRoot = "${src}/chadwm"; 

          buildInputs = with prev; [
            imlib2 xsetroot libXinerama
          ];
          
          # Standard Suckless build process
          configurePhase = ''
            # Ensures config.h is present if you don't fork (uses config.def.h)
            cp config.def.h config.h
          '';
          
          buildPhase = "make";
          
          installPhase = ''
            # 1. Install the built ChadWM binary 
            mkdir -p $out/bin
            install -m755 dwm $out/bin/chadwm
            
            # 2. Install essential scripts and make them executable
            # These scripts are needed for the bar (run.sh, bar.sh, etc.)
            mkdir -p $out/share/chadwm/scripts
            cp -r ${src}/scripts/* $out/share/chadwm/scripts/
            chmod +x $out/share/chadwm/scripts/*
            
            # 3. Create a wrapper script to launch the full ChadWM session
            cat > $out/bin/chadwm-session << EOF
              #!${prev.runtimeShell}
              
              # Set up environment and start services (eww/picom/dunst)
              # The run.sh script handles starting the bar and background apps
              ${prev.pkgs.bash}/bin/bash $out/share/chadwm/scripts/run.sh &
              
              # Wait a moment for EWW and other background processes to initialize
              sleep 1
              
              # Execute the ChadWM binary. Note: 'exec' ensures it takes over the session process
              exec $out/bin/chadwm
            EOF
            chmod +x $out/bin/chadwm-session
          '';
        };

        # Overwrite the default Nixpkgs 'dwm' package with our custom 'chadwm' derivation
        dwm = final.chadwm; 
      };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ chadwm_overlay ]; 
      };

    in
    {
      homeConfigurations."atom" = home-manager.lib.homeManagerConfiguration {
          inherit system;
          pkgs = pkgs; 
          modules = [ ./home.nix ];
      };
    };
}