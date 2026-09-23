{ system ? builtins.currentSystem, seed ? "", bigTreeWidths ? [ 5 5 5 5 ] }:
rec {
  # pkgsStatic.busybox for the respective systems, from
  # nixpkgs b36e8f733df3ca8a60fec114e1ce85e15fb198b2
  busyboxes = {
    x86_64-linux = ./busybox-x86_64;
    aarch64-linux = ./busybox-aarch64;
  };
  busybox = busyboxes.${system};

  mkDerivation = attrs: derivation ({
    inherit system;
    builder = busybox;
    inherit busybox;
    args = ["ash" "-c" ''eval "$script"''];
  } // attrs);

  trivial = mkDerivation {
    name = "trivial";
    inherit seed;
    script = ''
      echo hello > $out
    '';
  };
  dependent = mkDerivation {
    name = "dependent";
    script = ''
      echo ${trivial} > $out
    '';
  };
  multi-output = mkDerivation {
    name = "multi-output";
    outputs = ["out" "lib"];
    script = ''
      echo ${dependent} > $out
      echo ${dependent} > $lib
    '';
  };

  
  bigTree = let
    treeDrv = n: deps: mkDerivation {
      name = "tree-${toString n}";
      outputs = ["out"];
      inherit deps seed;
      script = ''
        echo $deps > $out
      '';
    };

    makeTreeDrvs = depth: widths: if widths == [] then [(treeDrv depth [])] else
      let
        width = builtins.head widths;
        range = n: if n <= 0 then [] else (range (n - 1)) ++ [n];
        deps = builtins.map (n: makeTreeDrvs (depth*10+n) (builtins.tail widths)) (range width);
      in treeDrv depth deps;
  in 
    makeTreeDrvs 0 bigTreeWidths;
}
