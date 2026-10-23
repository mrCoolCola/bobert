# Боберт
Боберт - это Телеграмм бот для мониторинга Linux сервера.
Он умеет:
  - Показывать загруженность CPU, RAM
  - Показывать статус systemd юнитов
  - Показывать температуры с lm-sensors
  - Бродкастить сообщения от пользователей к другим пользователям
  - Оповещать о начале/конце загрузки в qBittorrent
  - Начинать загрузки в qBittorrent по magnet ссылку
  
Доступ к нему ограничивается по айди.

## Параметры 
У него есть модуль для nixos - `bobert.nixosModules.default`
Настройки:
```nix
services.bobert = {
  enable = true;
  report = true; # ежедневный отчёт о состоянии сервера
  token = "placeholder"; # токен самого бота
  tokenFile = "/run/secrets/tokenFile"; # файл содержащий токен
  users = [1 2 3]; # массив айдишников разрешённых пользователей
  nicknames = ["наф-наф" "ниф-ниф" "нуф-нуф"] # массив ников, упорядоченных также как и пользователи
}
```
## Установка
### <img alt="Logo" src="https://github.com/mrCoolCola/mrCoolCola/raw/main/assets/nixos-original.svg" style="height:1em;width:1em;"> NixOS .
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

### Другие дистрибутивы
  В скором времени в <a href="https://github.com/mrCoolCola/bobert/releases/latest">релизах</a> автоматически будут появляться тарболлы с новыми версиями бота. Для запуска нужно установить переменные окружения:
  ```
    BOBERT_TOKEN=<токен>
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