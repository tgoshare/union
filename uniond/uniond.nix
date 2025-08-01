_: {
  perSystem =
    {
      pkgs,
      self',
      system,
      nix-filter,
      gitRev,
      uniondBundleVersions,
      mkCi,
      dbg,
      ...
    }:
    let
      libwasmvm = self'.packages.libwasmvm-2_2_1;
      CGO_LDFLAGS = "-z noexecstack -static -L${pkgs.musl}/lib -L${libwasmvm}/lib -s -w";

      mkUniondImage =
        uniond:
        pkgs.dockerTools.buildImage {
          name = "uniond";

          copyToRoot = pkgs.buildEnv {
            name = "image-root";
            paths = [
              pkgs.coreutils
              pkgs.cacert
              uniond
            ];
            pathsToLink = [ "/bin" ];
          };
          config = {
            Entrypoint = [ "uniond" ];
            Cmd = [ "start" ];
            Env = [ "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" ];
          };
        };
    in
    {
      packages = {
        # Statically link on Linux using `pkgsStatic`, dynamically link on Darwin using normal `pkgs`.
        uniond = (if pkgs.stdenv.isLinux then pkgs.pkgsStatic.buildGo123Module else pkgs.buildGo123Module) (
          {
            name = "uniond";
            src = nix-filter {
              name = "uniond-source";
              root = ./.;
              exclude = [
                (nix-filter.matchExt "nix")
                (nix-filter.matchExt "md")
              ];
            };
            vendorHash = "sha256-73NK9leABR9kztl7YehH8OHaH8O/lcWv8dLIDIKGwGs=";
            doCheck = true;
            meta.mainProgram = "uniond";
          }
          // (
            if pkgs.stdenv.isLinux then
              {
                inherit CGO_LDFLAGS;
                nativeBuildInputs = [
                  pkgs.musl
                ];
                tags = [
                  "netgo"
                  "muslc"
                ];
                ldflags = [
                  "-linkmode external"
                  "-extldflags \"-Wl,-z,muldefs -static\""
                  "-X github.com/cosmos/cosmos-sdk/version.Name=uniond"
                  "-X github.com/cosmos/cosmos-sdk/version.AppName=uniond"
                  "-X github.com/cosmos/cosmos-sdk/version.BuildTags=netgo"
                ];
              }
            else if pkgs.stdenv.isDarwin then
              {
                # Dynamically link if we're on darwin by wrapping the program
                # such that the DYLD_LIBRARY_PATH includes libwasmvm
                buildInputs = [ pkgs.makeWrapper ];
                postFixup = ''
                  wrapProgram $out/ bin/uniond \
                  --set DYLD_LIBRARY_PATH ${(pkgs.lib.makeLibraryPath [ libwasmvm ])};
                '';
                ldflags = [
                  "-X github.com/cosmos/cosmos-sdk/version.Name=uniond"
                  "-X github.com/cosmos/cosmos-sdk/version.AppName=uniond"
                ];
              }
            else
              { }
          )

        );

        uniond-release = mkCi false (
          self'.packages.uniond.overrideAttrs (old: {
            ldflags = old.ldflags ++ [
              "-X github.com/cosmos/cosmos-sdk/version.Name=uniond"
              "-X github.com/cosmos/cosmos-sdk/version.AppName=uniond"
              "-X github.com/cosmos/cosmos-sdk/version.BuildTags=${system}"
              "-X github.com/cosmos/cosmos-sdk/version.Commit=${gitRev}"
              "-X github.com/cosmos/cosmos-sdk/version.Version=${uniondBundleVersions.last}"
            ];
          })
        );

        uniond-image = mkUniondImage self'.packages.uniond;

        uniond-release-image = mkUniondImage self'.packages.uniond-release;
      };
    };
}
