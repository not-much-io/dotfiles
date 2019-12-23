# Edit this configuration file to define what should be installed on
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
          version = "5.0.0";
          modDirVersion = version;

          src = fetchurl {
            url = "https://github.com/torvalds/linux/archive/v5.0.tar.gz";
            sha256 = "10c228c231bedac30e704a58344bf70a580e92a18e1ccbf8ae2004231ce32c16";
          };
          kernelPatches = [
            { name = "0001";
              patch = fetchurl {
                url = "https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.0.21/0001-base-packaging.patch";
                sha256 = "40a0c6bbe0087a8b082c41d443afd0129da44cf3d233562b5590f986282deed1";
              };
            }
            { name = "0002";
              patch = fetchurl {
                url = "https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.0.21/0002-UBUNTU-SAUCE-add-vmlinux.strip-to-BOOT_TARGETS1-on-p.patch";
                sha256 = "f8115da44cecef42c071a494285000cf6e45d7ad5e131df964a5ab781a7cba54";
              };
            }
            { name = "0003";
              patch = fetchurl {
                url = "https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.0.21/0003-UBUNTU-SAUCE-tools-hv-lsvmbus-add-manual-page.patch";
                sha256 = "847e7da88c7b34c397009ed27c0868709466e145ff402cf60739088c72fe5d05";
              };
            }
            { name = "0004";
              patch = fetchurl {
                url = "https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.0.21/0004-debian-changelog.patch";
                sha256 = "6e113103a5fa75d0b3a8e0287f7241edb4ca770096f46735bf2652c59a4e9c91";
              };
            }
            { name = "0005";
              patch = fetchurl {
                url = "https://kernel.ubuntu.com/~kernel-ppa/mainline/v5.0.21/0005-configs-based-on-Ubuntu-5.0.0-16.17.patch";
                sha256 = "c37ca2d78b472dead6a3eacd3ced234af9811b1b65eedacaa2d362c0399fcd99";
               };
             }
          ];

          extraMeta.branch = "5.0.0";
        } // (args.argsOverride or {}));
      linux_sgx = pkgs.callPackage linux_sgx_pkg{};
    in
      pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_sgx);

  networking.hostName = "nmio-workstation";
  networking.networkmanager.enable = true;

  hardware.pulseaudio.enable = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.pulseaudio.support32Bit = true;
  hardware.bluetooth.enable = false;

  # Select internationalisation properties.
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  # Set your time zone.
  time.timeZone = "Europe/Tallinn";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true; # TODO: Remove when evdi for displaylink fixed!

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    openvpn

    firefox
    chromium

    go
    gcc
    git
    htop
    bash
    docker
    lazydocker
    gnumake
    binutils
    ktorrent

    vlc
    nodejs-12_x
    rustup
    cargo
    python37

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
  networking.firewall.enable = true;

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
    "nvidia"
    "displaylink"
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.extraUsers.guest = {
  #   isNormalUser = true;
  #   uid = 1000;
  # };
  # NOTE: dockerdev group is a dummy group for working with docker volumes
  #       Both docker and host user (nmio) will have a group with guid "1024" and thus can share the data there
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
