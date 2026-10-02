{ system ? builtins.currentSystem, seed ? "", bigTreeWidths ? [ 5 5 5 5 ], bigTreeExtraScript ? "" }:
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

  big = mkDerivation {
    name = "big";
    inherit seed;
    script = ''
      # Copy busybox approximately the right amount of times to make an 800M output path
      size=$($busybox stat -c %s $busybox)
      count=$((800*1024 / (size / 1024)))
      $busybox cat $(printf "%.0s$busybox " $($busybox seq $count)) > $out
    '';
  };
  
  dependent = mkDerivation {
    name = "dependent";
    script = ''
      echo ${trivial} > $out
      echo ${big} >> $out
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
    treeDrv = suffix: deps: mkDerivation {
      name = "tree${suffix}";
      outputs = ["out"];
      inherit deps seed;
      script = ''
        echo $deps > $out
        ${bigTreeExtraScript}
      '';
    };

    makeTreeDrvs = prefix: widths: if widths == [] then [(treeDrv prefix [])] else
      let
        width = builtins.head widths;
        range = n: if n <= 0 then [] else (range (n - 1)) ++ [n];
        deps = builtins.map (n: makeTreeDrvs (prefix + "-${toString n}") (builtins.tail widths)) (range width);
      in treeDrv prefix deps;
  in 
    makeTreeDrvs "" bigTreeWidths;
}
