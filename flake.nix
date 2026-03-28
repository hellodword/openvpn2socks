{
  description = "OpenVPN to socks without root";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;
      in
      {
        packages.openvpn = pkgs.openvpn.overrideAttrs (_old: {
          version = "2.6-rootless";
          src = pkgs.fetchFromGitHub {
            owner = "OpenVPN";
            repo = "openvpn";
            rev = "dd98c38b31c02cbca7f88ed0a709e68f24361195";
            hash = "sha256-B2nmRATq6QZ3rAKmv1kkBNOp9vJ7vhL5dxSyvgUev/A=";
          };
          patches = [ ./openvpn-tunpipe.diff ];
          buildInputs =
            (_old.buildInputs or [ ])
            ++ pkgs.lib.optionals pkgs.stdenv.isLinux (
              with pkgs;
              [
                libnl
                libcap_ng
              ]
            )
            ++ (with pkgs; [
              lz4
              python3Packages.docutils
            ]);
          nativeBuildInputs =
            (_old.nativeBuildInputs or [ ])
            ++ (with pkgs; [
              autoreconfHook
            ]);
        });
        packages.tunsocks = pkgs.stdenv.mkDerivation {
          pname = "tunsocks";
          version = "2023-06-22";

          src = pkgs.fetchFromGitHub {
            owner = "russdill";
            repo = "tunsocks";
            rev = "4e4ff8682053412145930b8daf2c55d357cf1e44";
            hash = "sha256-9d8GLPhjIG2DvQx0Gvf4yRVYX/r/P8AkqrtsXZpB6Jw=";
            fetchSubmodules = true;
          };

          buildInputs = with pkgs; [
            libpcap
            libevent
          ];
          nativeBuildInputs = with pkgs; [ autoreconfHook ];

        };

        apps.tunsocks = {
          type = "app";
          program = "${pkgs.writeShellScript "tuna-tunsocks" ''
            set -eu

            ${self.packages.${system}.openvpn}/bin/openvpn \
              --config "$1" \
              --script-security 2 \
              --dev "|HOME=$HOME exec ${
                self.packages.${system}.tunsocks
              }/bin/tunsocks -D 127.0.0.1:10080 -d 1.1.1.1"
          ''}";
        };
      }
    );
}
