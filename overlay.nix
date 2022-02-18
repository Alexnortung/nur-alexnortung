# You can use this file as a nixpkgs overlay. This is useful in the
# case where you don't want to add the whole NUR namespace to your
# configuration.

self: super:
let
  isReserved = n: n == "lib" || n == "overlays" || n == "modules";
  nameValuePair = n: v: { name = n; value = v; };
  nurAttrs = import ./default.nix { pkgs = super; };
  pkgsAttrs = nurAttrs.pkgs;

in
# builtins.listToAttrs
#   (map (n: nameValuePair n pkgsAttrs.${n})
#     (builtins.filter (n: !isReserved n)
#       (builtins.attrNames pkgsAttrs)))
pkgsAttrs
