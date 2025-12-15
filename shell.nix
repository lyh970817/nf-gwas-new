# shell.nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nf-test
  ];

  # 2. Add C/C++ libraries to the dynamic linker's search path
  shellHook = ''
  '';
}
