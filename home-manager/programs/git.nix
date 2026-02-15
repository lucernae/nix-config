{ config, pkgs, ... }:
with pkgs;
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    signing = {
      key = "69AC1656";
      signByDefault = true;
    };
    settings = {
      user.name = "Rizky Maulana Nugraha";
      user.email = "lana.pcfre@gmail.com";
      core.editor = "vim";
      core.fileMode = false;
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
