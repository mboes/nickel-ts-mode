{
  description = "Emacs major mode for Nickel, using tree-sitter";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        eldev = pkgs.emacsPackages.eldev;
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.emacs-nox
            pkgs.nickel
            # The package ships the eldev script, but not on PATH.
            (pkgs.writeScriptBin "eldev" (builtins.readFile
              "${eldev}/share/emacs/site-lisp/elpa/eldev-${eldev.version}/bin/eldev"))
          ];
        };
      });
}
