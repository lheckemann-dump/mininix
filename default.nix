{ system ? builtins.currentSystem, seed ? "" }:
rec {
  busybox = import <nix/fetchurl.nix> ({
    x86_64-linux.url = "http://tarballs.nixos.org/stdenv-linux/i686/4907fc9e8d0d82b28b3c56e3a478a2882f1d700f/busybox";
    x86_64-linux.sha256 = "ef4c1be6c7ae57e4f654efd90ae2d2e204d6769364c46469fa9ff3761195cba1";
    aarch64-linux.url = "http://tarballs.nixos.org/stdenv-linux/aarch64/c7c997a0662bf88264db52cbc41e67884eb7a1ff/busybox";
    aarch64-linux.sha256 = "sha256-4EN2vLvXUkelZZR2eKaAQA5kCEuHNvRZN6dcohxVY+c=";
  }.${system} // {
    executable = true;
  });

  mkDerivation = attrs: derivation ({
    inherit system;
    builder = busybox;
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
}
