with import <nixpkgs> {};

let
  updateElm = pkgs.writeShellScriptBin "updateElm" ''
    ${pkgs.elm2nix}/bin/elm2nix convert > nix/elm-srcs.nix
    ${pkgs.elm2nix}/bin/elm2nix snapshot
    mv registry.dat nix/registry.dat
  '';

  initElm = pkgs.writeShellScriptBin "initElm" ''
    mkdir nix
    ${pkgs.elm2nix}/bin/elm2nix init > nix/default.nix
    ${pkgs.elm2nix}/bin/elm2nix convert > nix/elm-srcs.nix
    ${pkgs.elm2nix}/bin/elm2nix snapshot
    mv registry.dat nix/registry.dat
   '';

   build = pkgs.writeShellScriptBin "build" ''
   elm make src/Main.elm --optimize --output lambda/Main.js
   '';
in

pkgs.mkShell {
  buildInputs = with pkgs; [
    pkgs.terraform
    pkgs.haskellPackages.dhall
    pkgs.nodejs-16_x
    pkgs.elm2nix
    pkgs.elmPackages.elm
    pkgs.elmPackages.elm-format
    updateElm
    initElm
    build
  ];

  shellHook = ''echo "🚀"'';
}