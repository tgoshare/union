{
  lib,
  withSystem,
  inputs,
  ...
}:
{
  flake.checks =
    lib.genAttrs
      [
        "x86_64-linux"
        "aarch64-linux"
      ]
      (
        lib.flip withSystem (
          {
            e2e,
            networks,
            pkgs,
            self',
            dbg,
            ...
          }:
          let
            # full-e2e = import ./full-e2e.nix { inherit e2e pkgs; };
            epoch-staking = import ./epoch-staking.nix { inherit e2e pkgs dbg; };
            upgrades = import ./upgrades.nix {
              inherit e2e pkgs;
              inherit (self'.packages) unionvisor;
              bundle = self'.packages.bundle-union-1-next;
            };
          in
          {
            # Disabled
            # TODO: Fix Ensure Blocks Workflow unionlabs/union#2067
            # ensure-blocks = import ./ensure-blocks/ensure-blocks.nix { inherit e2e networks pkgs nixpkgs crane; };
            #
            # Tests from ./full-e2e.nix
            # inherit (full-e2e) voyager-queue-works;

            # Tests from ./epoch-staking.nix
            inherit (epoch-staking) epoch-completes;
            inherit (epoch-staking) forced-set-rotation;

            # Tests from ./upgrades.nix
            inherit (upgrades) upgrade-from-genesis;
            # inherit (upgrades) upgrade-with-tokenfactory-state;

            virtualisation-works = e2e.mkTest {
              name = "full-dev-setup";
              nodes = {
                devnet = _: {
                  imports = [
                    inputs.arion.nixosModules.arion
                  ];
                  virtualisation = {
                    diskSize = 4 * 1024;
                    arion = {
                      backend = "docker";
                      projects.full-dev-setup.settings = networks.modules.full-dev-setup;
                    };
                  };
                };
              };
              testScript = ''
                devnet.wait_for_unit("arion-${networks.modules.full-dev-setup.project.name}")
              '';
            };

            devnet-eth-runs = e2e.mkTest {
              name = "devnet-eth-runs";

              testScript = ''
                start_all()

                devnetEth.wait_for_open_port(${toString e2e.devnetEthNode.wait_for_open_port})
                devnetEth.wait_for_console_text('${e2e.devnetEthNode.wait_for_console_text}')
              '';

              nodes = {
                devnetEth = e2e.devnetEthNode.node;
              };
            };

            union-runs = e2e.mkTest {
              name = "union-runs";

              testScript = ''
                start_all()

                devnetUnion.wait_for_open_port(${toString e2e.unionNode.wait_for_open_port})

                # Ensure the union network commits more than one block
                devnetUnion.wait_until_succeeds('[[ $(curl "http://localhost:26660/block" --fail --silent | ${pkgs.lib.meta.getExe pkgs.jq} ".result.block.header.height | tonumber > 1") == "true" ]]')
              '';

              nodes = {
                devnetUnion = e2e.unionNode.node;
              };
            };
          }
        )
      );
}
