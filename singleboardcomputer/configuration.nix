{ config, pkgs, lib, ... }:

let
  unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # This machine boots in UEFI mode
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nmio-tc2";
  networking.networkmanager.enable = true;

  hardware.pulseaudio.enable = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.pulseaudio.support32Bit = true;
  hardware.bluetooth.enable = true;

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "Europe/Tallinn";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.firefox.enablePlasmaBrowserIntegration = true;

  environment.systemPackages = with pkgs; [
    # System
    bash
    binutils
    docker
    docker-compose
    gcc
    git
    gnumake
    htop
    lazydocker
    libsForQt5.qtstyleplugin-kvantum
    openssl
    plasma5.sddm-kcm
    python37

    # Applications
    ark
    barrier
    chromium
    filelight
    unstable.vscode
    emacs26-nox
    firefox
    kdeconnect
    ktorrent
    okular
    slack
    spectacle
    plasma-browser-integration
    tdesktop
    vlc

    # TODO: Split into Go dev env
    go
    unstable.jetbrains.jdk
    unstable.jetbrains.goland

    # Too old, vendored
    # jetbrains.goland
    # Too old, vendored
    # terraform
    # Too old, vendored
    # terragrunt
  ];

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.bash.enableCompletion = true;
  programs.ssh.forwardX11 = true;
  programs.ssh.setXAuthLocation = true;

  # List services that you want to enable:
  services.openssh.enable = true;
  services.openssh.forwardX11 = true;
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "eurosign:e";
  services.xserver.libinput.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.videoDrivers = [
    "amdgpu"
  ];
 
  # Or disable the firewall altogether.
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
      24800 # Barrier
      2376  # Docker Host
  ];

  # NOTE: dockerdev group is a dummy group for working with docker volumes
  #       Both docker and host user (nmio) will have a group with guid "1024" and thus can share the data there
  users.groups.docker =
  { name = "docker";
  };
  users.groups.dockerdev =
  { name = "dockerdev";
    gid = 1024;
  };
  users.users.nmio =
  { isNormalUser = true;
    home = "/home/nmio";
    extraGroups = [ "wheel" "networkmanager" "docker" "dockerdev" "adbuser" ];
  };

  # These are the commands to change channel:
  # - sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
  # - sudo nixos-rebuild switch --upgrade
  system.stateVersion = "20.03";
}
