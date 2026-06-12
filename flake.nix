{
  description = "neovim config for devellopement";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
        let 
            system = "x86_64-linux";
            pkgs = import nixpkgs {inherit system;};

        neovimWithPlugins = pkgs.neovim.override {
            configure = {
                packages.nix = {
                    start = with pkgs.vimPlugins; [
                        (nvim-treesitter.withPlugins (p: [
                            p.asm
                            p.c p.cpp p.cmake p.make 
                            p.python
                            p.go p.gomod p.gosum p.gowork
                            p.nix
                            p.lua p.vim p.vimdoc
                            p.markdown
                            p.yaml
                        ]))
                        nvim-lspconfig
                        lualine-nvim
                    ];
                };
            };
        };

        devNvimBin = pkgs.symlinkJoin {
          name = "dev-nvim";
          paths = [ neovimWithPlugins ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            makeWrapper ${neovimWithPlugins}/bin/nvim $out/bin/dev-nvim \
              --set NVIM_APPNAME nvim \
              --set XDG_CONFIG_HOME "${self}" \
              --set VIMINIT "lua dofile('${self}/nvim/init.lua')"
          '';
        };

        in {
            packages.${system} = {
                default = devNvimBin;
                typst-nvim = devNvimBin;
            };
            devShells.${system}.default = pkgs.mkShell {
            name = "dev-nvim";

            packages = [
                devNvimBin
                pkgs.gcc
                pkgs.clang
                pkgs.clang-tools
                pkgs.binutils

                pkgs.pyright

                pkgs.gopls 
                pkgs.gotools

                pkgs.lua-language-server

                pkgs.nixd

                pkgs.git
            ];

            shellHook =''
                export XDG_CONFIG_HOME="$(pwd)"
                export NVIM_APPNAME="nvim"
                export VIMINIT="source $(pwd)/nvim/init.lua"
                echo "Hello vim"
                '';
        };
    }; 
}
