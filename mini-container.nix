## Mini Container Image
#
# This script generates a mini container, whose size is less than 5MB.
# The generated image can be loaded by podman or docker.
# The utilities are all provided by a statically linked busybox.
{ pkgs ? import <nixpkgs> {}
}: pkgs.dockerTools.buildImage {
  name = "mini-container";
  copyToRoot = pkgs.buildEnv {
    name = "root";
    paths = [
      (pkgs.busybox.override {enableStatic=true; useMusl=true;})
      (pkgs.writeTextFile rec {
        name = "passwd";
        destination = "/etc/${name}";
        text = "root:x:0:0:System administrator:/root:/bin/bash";
      })
      # For ssl
      pkgs.dockerTools.caCertificates
    ];
  };
  extraCommands = ''
    # for /usr/bin/env
    mkdir usr
    ln -s ../bin usr/bin
    # make sure /tmp exists
    mkdir -m 1777 tmp
    # need a HOME
    mkdir -vp root
  '';
  config = {
    Cmd = [ "/bin/sh" ];
    Env = [ "PATH=/bin" ];
  };
}
