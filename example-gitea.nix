{ pkgs ? import <nixpkgs> {}
, instance
, token
}: pkgs.callPackage ./. {
  runner = pkgs.gitea-actions-runner;
  runner_sh = let
    registerCmd = [
      "act_runner register"
      "--no-interactive"
      "--instance '${instance}'"
      "--token ${token}"
      "--name $HOSTNAME-$(TZ=UTC-8 date +%y%m%d%H%M%S)"
      "--labels 'self-hosted,Linux,X64,nix'"
      "$@"
    ];
  in builtins.toFile "runner.sh" ''
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
