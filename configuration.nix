{ config, lib, pkgs, inputs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ── Boot ──────────────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "lockdown=integrity" ];
  boot.initrd.luks.devices."cryptroot" = {
  device = "/dev/disk/by-uuid/1780dd9f-1284-453a-b21e-b42fc158b0c8";
  preLVM = true;
};
  # ── Networking ────────────────────────────────────────────────────────────
  networking.hostName = "nix-btw";
  networking.firewall.enable = true;
  networking.networkmanager = {
    enable = true;
    wifi.macAddress = "random";
    ethernet.macAddress = "stable";
  };
  # ── Security ──────────────────────────────────────────────────────────────
  security.sudo.wheelNeedsPassword = true;
  swapDevices = [{
  device = "/dev/disk/by-partuuid/a4c7f1de-3484-4677-87db-6781fe959358";
  randomEncryption.enable = true;
}]; 
systemd.coredump.enable = false;

boot.kernel.sysctl = {
  "kernel.yama.ptrace_scope"  = 2;
  "kernel.kptr_restrict"      = 2;
  "kernel.dmesg_restrict"     = 1;
  "net.core.bpf_jit_harden"   = 2;
};

  # ── GPU ───────────────────────────────────────────────────────────────────
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.open = true;
  hardware.graphics.enable = true;

  # ── Desktop ───────────────────────────────────────────────────────────────
  services.displayManager.ly.enable = true;
  services.displayManager.defaultSession = "hyprland";
  programs.hyprland.enable = true;
  security.polkit.enable = true;
  services.fail2ban.enable = true;
  security.apparmor.enable = true;
 ###
  networking.firewall.allowedTCPPortRanges = [
    { from = 1714; to = 1764; }
  ];
  networking.firewall.allowedUDPPortRanges = [
  { from = 1714; to = 1764; }
  ];



  programs.kdeconnect.enable = true;
###
  nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 30d";
};
  # ── Bluetooth ─────────────────────────────────────────────────────────────
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # ── Audio ─────────────────────────────────────────────────────────────────
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # ── Power ─────────────────────────────────────────────────────────────────
  services.power-profiles-daemon.enable = true;

  # ── Time ──────────────────────────────────────────────────────────────────
  time.timeZone = "Europe/Moscow";

  # ── Locale ────────────────────────────────────────────────────────────────
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Users ─────────────────────────────────────────────────────────────────
  users.users.oxy = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.zsh;
  };

  # ── Virtualisation ────────────────────────────────────────────────────────
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };
  systemd.sockets.docker.wantedBy = lib.mkForce [];

  # ── Programs ──────────────────────────────────────────────────────────────
  programs.steam.enable = true;
  programs.firefox.enable = true;
  nixpkgs.config.allowUnfree = true;
  programs.zsh.enable = true;
  services.flatpak.enable = true;

  # ── Tor ───────────────────────────────────────────────────────────────────
services.tor = {
  enable = true;
  client.enable = true;
  settings = {
    ExcludeExitNodes = "{RU},{BY},{KZ}";
    ClientUseIPv6 = false;
    UseBridges = true;
    ClientTransportPlugin = "obfs4 exec ${pkgs.obfs4}/bin/lyrebird";
    "%include" = "/etc/tor/bridges.conf";
  };
};
systemd.services.tor.serviceConfig = {
    ProtectProc = lib.mkForce "default";
    RestrictAddressFamilies = lib.mkForce [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
    CapabilityBoundingSet = lib.mkForce [ "CAP_NET_BIND_SERVICE" "CAP_SETUID" "CAP_SETGID" ];
    ReadWritePaths = [ "/etc/tor" ];
  };


systemd.tmpfiles.rules = [
  "d /etc/tor 0750 tor tor -"
];

  programs.proxychains = {
  enable = true;
  chain.type = "dynamic";
  proxies = {
    default = {
      enable = true;
      type = "socks5";
      host = "127.0.0.1";
      port = 9050;
      };
    };
  };

  services.privoxy = {
  enable = true;
  settings = {
    forward-socks5t = "/ 127.0.0.1:9050 ."; # Пересылаем всё в Tor
    listen-address = "127.0.0.1:8118";
  };
};

  # ── Packages ──────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # Core utils
    vim
    wget
    curl
    git
    btop
    fd
    fastfetch
    python3
    bat
    eza
    fzf
    zoxide
    tmux
    ripgrep
    neovim
    helix
    yazi
    tree
 
    # Desktop
    ghostty
    thunar
    nwg-look
    adw-gtk3
    qt6Packages.qt6ct
    papirus-icon-theme
    hyprshot
    easyeffects
    kdePackages.dolphin
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Apps
    telegram-desktop
    vesktop
    vscodium
    zoom-us
    obsidian
    gpu-screen-recorder

    # Gaming
    vulkan-loader
    vulkan-tools

    # Network / Security
    dnsutils
    nmap
    whois
    nikto
    gobuster
    tshark
    wireshark

    # Tor / Privacy
    tor
    tor-browser
    proxychains-ng
    obfs4

    # Docker
    lazydocker

    # Pywalfox
    pywalfox-native
    
    # Funny
    nethack
    moon-buggy
  ];

  system.stateVersion = "25.11";
}
