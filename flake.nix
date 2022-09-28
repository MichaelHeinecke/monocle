{
  description = "Monocle";
  nixConfig.bash-prompt = "[nix(monocle)] ";

  inputs = {
    nixpkgs.url =
      "github:NixOS/nixpkgs/ed014c27f4d0ca772fb57d3b8985b772b0503bbd";
    hspkgs.url =
      "github:podenv/hspkgs/8596beefeb8471cbafae9bdefb6cb5de8dbc5627";
      # "path:/srv/github.com/podenv/hspkgs";
  };

  outputs = { self, nixpkgs, hspkgs }:
    let
      legacy = import ./nix/default.nix {
        nixpkgsPath = nixpkgs;
        hspkgs = hspkgs.pkgs;
        self = self;
      };
    in {
      devShell."x86_64-linux" = legacy.shell;
      devShells."x86_64-linux".ci = legacy.ci-shell;
      packages."x86_64-linux".default = legacy.monocle-exe;
      packages."x86_64-linux".env = legacy.monocle-light.env;
      packages."x86_64-linux".containerMonocle = legacy.containerMonocle;
      packages."x86_64-linux".containerGrafana = legacy.containerGrafana;
      packages."x86_64-linux".containerPrometheus = legacy.containerPrometheus;
      apps."x86_64-linux".default = {
        type = "app";
        program = "${legacy.monocle-exe}/bin/monocle";
      };
    };
}
