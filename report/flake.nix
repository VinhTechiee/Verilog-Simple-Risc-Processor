{
  description = "LaTeX (Devshell)";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell.url = "github:numtide/devshell";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devshell.flakeModule ];

      systems = [ "x86_64-linux" ];

      perSystem =
        { pkgs, ... }:

        {
          devshells.default = {
            name = "LaTeX";

            packages = with pkgs; [
              ### Option 1: tectonic compiler (tends to break with minted)
              # tectonic
              # (python314.withPackages (qs: with qs; [ pygments ]))
              # (texlive.withPackages (ps: with ps; [ latexindent ]))

              ### Option 2: latexmk compiler
              texliveFull

              bibtex-tidy
              texlab
              ghostscript
            ];

            devshell.motd = ''
               {45}Welcome to LaTeX.{reset}
              Enter 'menu' for general commands.
            '';
          };
        };
    };
}
