{
  self,
  autovirt,
}:

{
  imports = [
    (import ./vfio.nix)
    (import ./vm.nix {
      inherit
        self
        autovirt
        ;
    })
    (import ./looking-glass.nix)
    (import ./kernel.nix)
  ];
}
