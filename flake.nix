{
  inputs.nixpkgs.url = "nixpkgs/40ae799f1a076e5df247ed3666b33a054f20956b";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
    in
    {
      devShells."${system}" = {
        default =
          let
            pkgs = import nixpkgs {
              inherit system;
            };
            fish-config = pkgs.writers.writeFish "fish-config" ''
              eval (functions fish_prompt | string replace "(prompt_login)" "dev" | string replace "function fish_prompt" "function fish_dev_prompt" | string collect)

              functions -c fish_prompt fish_default_prompt

              function fish_prompt
                if test -n "$IN_NIX_SHELL"
                  fish_dev_prompt
                end
                if test -z "$IN_NIX_SHELL"
                  fish_default_prompt
                end
              end

              function prepare
                rm -rf build
                cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -B build
                cmake --build build -j$(nproc)
              end
            '';
            fish-wrapper = pkgs.writeShellApplication {
              name = "fish";
              text = ''
                ${pkgs.fish}/bin/fish -C "source ${fish-config}"
              '';
            };
          in
          pkgs.mkShell {
            nativeBuildInputs =
              with pkgs;
              [
                pkg-config
                cmake
              ]
              ++ (with pkgs.kdePackages; [
                extra-cmake-modules
              ]);
            buildInputs =
              with pkgs;
              [
                freerdp
                pam
              ]
              ++ (with pkgs.kdePackages; [
                qtbase
                qtwayland
                kcmutils
                kstatusnotifieritem
                kpipewire
                qtkeychain
              ]);
            packages = with pkgs; [
              git
              fish-wrapper
              nixd
              nixfmt-rfc-style
              helix
              llvmPackages_21.clang-tools
              llvmPackages_21.clang-unwrapped.python # git clang-format
              ripgrep
            ];
            shellHook = ''
              exec fish
            '';
          };
      };
    };
}
