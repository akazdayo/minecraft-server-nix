{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    terranix = {
      url = "github:terranix/terranix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      terranix,
      deploy-rs,
      ...
    }:
    let
      # --- NixOS Configurations ---
      nixosConfigurations = {
        # DigitalOcean image build用
        do = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"
            ./do-image.nix
          ];
        };

        # Droplet用 NixOS Configuration
        droplet = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-config.nix"
            ./droplet-configuration.nix
          ];
        };
      };
    in
    {
      inherit nixosConfigurations;

      # --- Deploy-RS ---
      deploy.nodes.droplet = {
        hostname = "HOST IP ADDRESS"; # IPアドレスをterraformのoutputに置き換えしてください
        sshUser = "root";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.droplet;
        };
      };

      # Deploy-RS validation checks
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        terraform = pkgs.opentofu;
        terraformConfiguration = terranix.lib.terranixConfiguration {
          inherit system;
          modules = [ ./terraform.nix ];
        };
      in
      {
        formatter = pkgs.alejandra;

        # DigitalOcean image build (既存)
        packages.do-image = nixosConfigurations.do.config.system.build.digitalOceanImage;

        # Terranix: Terraform JSON configuration
        packages.terraform = terraformConfiguration;

        # --- Apps ---
        # nix run .#tf-apply
        apps.tf-apply = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "tf-apply" ''
              if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
              cp ${terraformConfiguration} config.tf.json \
                && ${terraform}/bin/tofu init \
                && ${terraform}/bin/tofu apply
            ''
          );
        };

        # nix run .#tf-destroy
        apps.tf-destroy = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "tf-destroy" ''
              if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
              cp ${terraformConfiguration} config.tf.json \
                && ${terraform}/bin/tofu init \
                && ${terraform}/bin/tofu destroy
            ''
          );
        };

        # nix run .#tf-plan
        apps.tf-plan = {
          type = "app";
          program = toString (
            pkgs.writers.writeBash "tf-plan" ''
              if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
              cp ${terraformConfiguration} config.tf.json \
                && ${terraform}/bin/tofu init \
                && ${terraform}/bin/tofu plan
            ''
          );
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            opentofu
            deploy-rs.packages.${system}.default
          ];
        };
      }
    );
}
