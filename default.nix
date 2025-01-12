## Github Runner
#
# This is a specially designed github runner:
#
# 1. To improve the security, more specifially, to avoid leaking information of the host environment,
#   * the runner is confined to a container,
#   * the rootless container is used, without sudo privilege.
# 2. To reduce the build time, the /nix/store is shared across containers and host environment, so that
#   * the results can be cached in host /nix/store,
#   * there is no repeated build among different containers.
{ lib
, callPackage
, writeShellScript
, nix
, podman
, gnumake

, runner
, runner_sh
, extraPodmanOpts ? []
, extraPkgsInPATH ? []
}: let
  container = callPackage ./mini-container.nix {};
  pkgsInPATH = [
    runner
    nix
    gnumake
  ] ++ extraPkgsInPATH;
in writeShellScript "runner-nix" ''
  fullName=localhost/${container.imageName}:${container.imageTag}
  # check whether image has been loaded
  ${podman}/bin/podman images $fullName | grep ${container.imageName} | grep ${container.imageTag} &> /dev/null
  # image has not been loaded, then load it
  if [[ $? != 0 ]]; then
    ${podman}/bin/podman load -i ${container}
  fi

  # run container
  OPTS=(
    --rm
    --network=host
    --env-merge PATH='${lib.concatMapStrings (pkg: pkg+"/bin:") pkgsInPATH}\''${PATH}'
    -v /nix:/nix:ro
    -it
    ${builtins.concatStringsSep " " extraPodmanOpts}
    "$fullName"
    /bin/sh ${runner_sh} $@
  )
  echo "${podman}/bin/podman run ''${OPTS[@]}"
  eval "${podman}/bin/podman run ''${OPTS[@]}"
''
