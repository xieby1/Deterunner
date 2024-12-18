# Usage: `nix-build example.nix --argstr github_token <GITHUB_TOKEN>`
{ pkgs ? import <nixpkgs> {}
, github_token ? throw ''
    github_token is missing!
    * How to fix:
      * append `--argstr github_token <GITHUB_TOKEN>` to your nix command line.
    * How to retrieve the <GITHUB_TOKEN>:
      * Generate the github token here: https://github.com/settings/tokens?type=beta
      * The fine-grained token must have the following permission set:
        * "Administration" repository permissions (write)
      * For more info: https://docs.github.com/en/rest/actions/self-hosted-runners?apiVersion=2022-11-28#create-a-registration-token-for-a-repository
  ''
, owner ? "xieby1"
, repo ? "Deterunner"
}: let
  name = "Deterunner-Example";
  runner = import ./. {
    inherit pkgs;
    extraConfigOpts = [
      "--labels 'self-hosted,Linux,X64,nix'"
      "--ephemeral"
      "--url https://github.com/${owner}/${repo}"
    ];
    extraPodmanOpts = [];
    extraPkgsInPATH = [pkgs.git];
  };
in pkgs.writeShellScript name ''
  resp=$(curl -L \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${github_token}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    Https://api.github.com/repos/${owner}/${repo}/actions/runners/registration-token)
  # https://unix.stackexchange.com/questions/13466/can-grep-output-only-specified-groupings-that-match
  runner_token=$(echo $resp | grep -oP '"token":\s*"\K[^"]*')
  ${runner} --token $runner_token
''