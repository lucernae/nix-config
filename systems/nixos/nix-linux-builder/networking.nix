{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [ "8.8.8.8"
 ];
    defaultGateway = "172.31.1.1";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address="116.203.210.37"; prefixLength=32; }
        ];
        ipv6.addresses = [
          { address="2a01:4f8:c0c:f2b8::1"; prefixLength=64; }
{ address="fe80::9400:3ff:fe2b:4370"; prefixLength=64; }
        ];
        ipv4.routes = [ { address = "172.31.1.1"; prefixLength = 32; } ];
        ipv6.routes = [ { address = "fe80::1"; prefixLength = 128; } ];
      };
            enp7s0 = {
        ipv4.addresses = [
          { address="10.1.0.2"; prefixLength=32; }
        ];
        ipv6.addresses = [
          { address="fe80::8400:ff:fe82:8a9"; prefixLength=64; }
        ];
        };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="96:00:03:2b:43:70", NAME="eth0"
    ATTR{address}=="86:00:00:82:08:a9", NAME="enp7s0"
  '';
}
