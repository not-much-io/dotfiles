#/ Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.useOSProber = true;
  # Use the latest kernel for magic touchpad 2 driver support (required 4.20+)
  # TODO: When 4.20+ becomes mainline, use that
  # boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPackages = let
      linux_sgx_pkg = { fetchurl, buildLinux, ... } @ args:

        buildLinux (args // rec {
          version = "5.2.0";
          modDirVersion = version;

          src = fetchurl {
            url = "https://github.com/torvalds/linux/archive/v5.2.tar.gz";
            sha256 = "16a2a056c16b91c3e4eaf40d2a5a096cfb604f40e2bf925f607cfa095f9e05b4";
          };
          kernelPatches = [];

          extraConfig = ''
            TYPEC m
            TYPEC_DP_ALTMODE m
	    TYPEC_TCPM m
          '';

          extraMeta.branch = "5.2";
        } // (args.argsOverride or {}));
      linux_sgx = pkgs.callPackage linux_sgx_pkg{};
    in 
      pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_sgx);

  boot.kernelModules = [ "typec" "typec_displayport" "typec_tcpm"];

  networking.hostName = "nmio-bolt";
  networking.networkmanager.enable = true;

  hardware.pulseaudio.enable = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.pulseaudio.support32Bit = true;
  hardware.bluetooth.enable = true;

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  # Set your time zone.
  time.timeZone = "Europe/Tallinn";

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    barrier
    spectacle
    okular
    filelight
    openvpn

    autorandr
    # displaylink

    firefox
    chromium
    slack
    tdesktop

    libreoffice

    go
    gcc
    git
    htop
    bash
    docker
    docker-compose
    lazydocker
    gnumake
    binutils
    ktorrent

    vlc
    nodejs-10_x
    jdk12_headless
    rustup
    cargo
    python

    emacs26-nox
    jetbrains.jdk
    jetbrains.goland
    jetbrains.clion
  ];

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  networking.firewall.allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
  networking.firewall.allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.displayManager.lightdm.enable = false;
  services.xserver.desktopManager.pantheon.enable = false;

  # GPUs
  services.xserver.videoDrivers = [
    "amdgpu"
    # "displaylink"
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.extraUsers.guest = {
  #   isNormalUser = true;
  #   uid = 1000;
  # };
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
    extraGroups = [ "wheel" "networkmanager" "docker" "dockerdev" ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  # These are the commands to change channel:
  # - sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
  # - sudo nixos-rebuild switch --upgrade
  system.stateVersion = "19.09"; # Did you read the comment?
}
