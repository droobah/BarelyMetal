{
  description = "BarelyMetal — NixOS module for anti-detection KVM/QEMU virtualization (based on AutoVirt)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    autovirt = {
      url = "github:Scrut1ny/AutoVirt";
      flake = false;
    };

    # NOTE: `qemu-src` and `edk2-src` inputs were removed. The QEMU/OVMF
    # derivations build on top of nixpkgs' own `qemu` / `edk2` packages
    # (see pkgs/qemu/default.nix and pkgs/ovmf/default.nix), which pin the
    # source themselves. Version-aware AutoVirt-patch selection lives in
    # those files, so the version stays glued to whatever nixpkgs ships.
  };

  outputs =
    {
      self,
      nixpkgs,
      autovirt,
    }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      nixosModules = {
        default = self.nixosModules.barelyMetal;
        barelyMetal = import ./modules {
          inherit
            self
            autovirt
            ;
        };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          callPackage = pkgs.callPackage;
        in
        {
          default = callPackage ./pkgs/probe { };
          probe = callPackage ./pkgs/probe { };
          deploy = callPackage ./pkgs/libvirt-xml { };

          qemu-patched = callPackage ./pkgs/qemu {
            inherit autovirt;
            cpu = "amd";
          };
          qemu-patched-intel = callPackage ./pkgs/qemu {
            inherit autovirt;
            cpu = "intel";
          };

          ovmf-patched = callPackage ./pkgs/ovmf {
            inherit autovirt;
            cpu = "amd";
          };
          ovmf-patched-intel = callPackage ./pkgs/ovmf {
            inherit autovirt;
            cpu = "intel";
          };

          smbios-spoofer = callPackage ./pkgs/smbios-spoofer { inherit autovirt; };
          utils = callPackage ./pkgs/utils { inherit autovirt; };
          guest-scripts = callPackage ./pkgs/guest-scripts { inherit autovirt; };
        }
      );

      devShells = forAllSystems (system: {
        default =
          let
            pkgs = pkgsFor system;
          in
          pkgs.mkShell {
            packages = with pkgs; [
              qemu
              libvirt
              virt-manager
              pciutils
              dmidecode
            ];
          };
      });
    };
}
