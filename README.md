# Боберт
Боберт - это первое и единственное название, которое я смог придумать для своего бота. Раньше rust код этого бота был в приватном репозитории - теперь я открыл его и сделал для него флейк.

## Параметры 
У него есть модуль для nixos - `bobert.nixosModules.default`
Настройки:
```nix
services.bobert = {
  enable = true;
  token = "placeholder"; # токен самого бота
  users = [1 2 3]; # массив айдишников разрешённых пользователей
  nicknames = ["наф-наф" "ниф-ниф" "нуф-нуф"] # массив ников, упорядоченных также как и пользователи
}
```
## Пример установки
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