{ pkgs ? import <nixpkgs> {}
, instance
, token
}: let
  # https://github.com/go-gitea/gitea/issues/30161
  # There are two places where we need to configure the runner timeout:
  # 1. Gitea instance configure: custom/conf/app.ini: ENDLESS_TASK_TIMEOUT
  # 2. Runner instance configure: the yaml below: timeout
  config_yml = pkgs.runCommand "gitea-runner-config.yml" {} ''
    ${pkgs.gitea-actions-runner}/bin/act_runner generate-config > $out
    sed -i 's/\<timeout:.*$/timeout: 72h/' $out
    sed -i '/^  labels:/,/^$/c\  labels: []\n' $out
  '';
in pkgs.callPackage ./. {
  runner = pkgs.gitea-actions-runner;
  runner_sh = let
    registerCmd = [
      "act_runner register"
      "--no-interactive"
      "--instance '${instance}'"
      "--token ${token}"
      "--name $HOSTNAME-$(TZ=UTC-8 date +%y%m%d%H%M%S)"
      "--labels 'self-hosted,Linux,X64,nix'"
      "--config ${config_yml}"
      "$@"
    ];
  in pkgs.writeText "runner.sh" ''
    echo ${toString registerCmd}
    ${toString registerCmd}
    act_runner daemon
  '';
  extraPodmanOpts = [];
  extraPkgsInPATH = [
    pkgs.git
    # TODO: why github actions/checkout not need node?
    pkgs.nodejs
  ];
}
