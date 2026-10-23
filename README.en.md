# Bobert
Bobert is a Telegram bot for GNU\Linux server monitoring.
It can:
  - Get CPU, RAM load
  - Systemd Units status
  - Show lm-sensors temperatures
  - Broadcast messages from cli or other users
  - Broadcast qBittorrent done/started messages
  - Download a magnet link with qBittorrent
  
Access is restricted by Telegram ID whitelist.

## Установка
### <img alt="Logo" src="https://github.com/mrCoolCola/mrCoolCola/raw/main/assets/nixos-original.svg" style="height:1em;width:1em;"> NixOS .
#### Flake
```nix
# ./flake.nix
{
  description = "NixOS";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    bobert = {
      url = "github:mrCoolCola/bobert";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { 
    self,
    nixpkgs,
    bobert,
    ...
  }@inputs: let
    inherit (self) outputs;
  in {
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./modules/nixos
          bobert.nixosModules.default
        ];
      };
    };
  };
}
```
#### Configuration
It has a nixos module - `bobert.nixosModules.default`
```nix
services.bobert = {
  enable = true;
  report = true; # daily report of statictics
  token = "placeholder"; # token from @BotFather
  tokenFile = "/run/secrets/tokenFile"; 
  users = [1 2 3]; # id whitelist
  nicknames = ["nickforid1" "nickforid2" "nickforid3"] # nicknames for users
}
```

### Other distributions
  Soon in <a href="https://github.com/mrCoolCola/bobert/releases/latest">releases</a> will be a tarball with binary. To run the bot, you need to set that variables:
  ```
    BOBERT_TOKEN=<token>
    BOBERT_USERS=<id1>,<id2>,<id3>
    BOBERT_NICKNAMES=<nick1>,<nick2>,<nick3>
  ```

## Star history
<a href="https://www.star-history.com/?repos=mrcoolcola%2Fmrcoolcola%2Cmrcoolcola%2Fbobert&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=mrcoolcola/mrcoolcola%2Cmrcoolcola/bobert&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=mrcoolcola/mrcoolcola%2Cmrcoolcola/bobert&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=mrcoolcola/mrcoolcola%2Cmrcoolcola/bobert&type=date&legend=top-left" />
 </picture>
</a>