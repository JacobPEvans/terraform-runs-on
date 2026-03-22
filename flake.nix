{
  description = "RunsOn self-hosted GitHub Actions runners infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
            };
          }
        );
    in
    {
      devShells = forAllSystems (
        { pkgs }:
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # Infrastructure as Code
              # terraform omitted: unfree license in nixpkgs; CI uses hashicorp/setup-terraform
              opentofu
              terragrunt
              terraform-docs
              tflint

              # Security
              tfsec
              trivy

              # Cloud
              awscli2
              git

              # Utilities
              jq
              yq
              pre-commit
            ];
          };
        }
      );
    };
}
