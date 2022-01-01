let
  pkgs = import <nixpkgs> {};
in
pkgs.mkShell {
  buildInputs = [
    pkgs.terraform
    pkgs.haskellPackages.dhall

  ];
  shellHook = ''echo "🚀"'';
}