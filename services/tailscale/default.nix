{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.tailscale;

in
{
  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    launchd.daemons.tailscale = {
      serviceConfig = {
        Label = "com.tailscale.tailscale";
        ProgramArguments = [
          "/bin/sh"
          "-c"
          "/bin/wait4path ${cfg.package} &amp;&amp; sleep 10 &amp;&amp; sudo ${cfg.package}/bin/tailscale up"
        ];
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
        };
      };
    };
  };
}
