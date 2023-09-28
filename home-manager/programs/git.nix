{ config, pkgs, ... }:
with pkgs;
{
  programs.git = {
    enable = true;
    userName = "Rizky Maulana Nugraha";
    userEmail = "lana.pcfre@gmail.com";
    signing = {
      key = "69AC1656";
      signByDefault = true;
    };
    extraConfig = {
      core.editor = "vim";
      init.defaultBranch = "main";
      safe.directory = [ ] ++ (lib.optionals stdenv.isDarwin [
        "/usr/local/Homebrew"
        "/usr/local/Homebrew/Library/Taps/homebrew/homebrew-bundle"
        "/usr/local/Homebrew/Library/Taps/homebrew/homebrew-core"
        "/usr/local/Homebrew/Library/Taps/homebrew/homebrew-cask"
      ]);
    };
  };
}
