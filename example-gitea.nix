{ pkgs ? import <nixpkgs> {}
, instance
, token
}: let
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
