{ pkgs ? import <nixpkgs> {}
, instance
, token
}: let
  # https://github.com/go-gitea/gitea/issues/30161
  # There are two places where we need to configure the runner timeout:
  # 1. Gitea instance configure: custom/conf/app.ini: ENDLESS_TASK_TIMEOUT
  # 2. Runner instance configure: the yaml below: timeout
  default-config = builtins.fromJSON (builtins.readFile (
    pkgs.runCommand "default-config.json" {
      nativeBuildInputs = with pkgs; [ gitea-actions-runner remarshal ];
    } "act_runner generate-config | yaml2json > $out"
  ));
  custom-config = pkgs.lib.recursiveUpdate default-config {
    runner.timeout = "72h";
    runner.labels = [];
  };
  config_yml = (pkgs.formats.yaml {}).generate "runner-config.yml" custom-config;
in pkgs.callPackage ./. rec {
  containerName = "$HOSTNAME-$(TZ=UTC-8 date +%y%m%d%H%M%S)";
  runner = pkgs.gitea-actions-runner;
  runner_sh = let
    registerCmd = [
      "act_runner register"
      "--no-interactive"
      "--instance '${instance}'"
      "--token ${token}"
      "--name ${containerName}"
      "--labels 'self-hosted,Linux,X64,nix'"
      "--config ${config_yml}"
      "$@"
    ];
    daemonCmd = [
      "act_runner daemon"
      "--config ${config_yml}"
    ];
  in pkgs.writeText "runner.sh" ''
    echo ${toString registerCmd}
    ${toString registerCmd}
    echo ${toString daemonCmd}
    ${toString daemonCmd}
  '';
  extraPodmanOpts = [];
  extraPkgsInPATH = [
    pkgs.git
    # TODO: why github actions/checkout not need node?
    pkgs.nodejs
  ];
}
