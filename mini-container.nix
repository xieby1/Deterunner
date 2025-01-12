## Mini Container Image
#
# This script generates a mini container, whose size is less than 5MB.
# The generated image can be loaded by podman or docker.
# The utilities are all provided by a statically linked busybox.
{ dockerTools
, buildEnv
, busybox
, writeTextFile
}: dockerTools.buildImage {
  name = "mini-container";
  copyToRoot = buildEnv {
    name = "root";
    paths = [
      (busybox.override {enableStatic=true; useMusl=true;})
      (writeTextFile rec {
        name = "passwd";
        destination = "/etc/${name}";
        text = "root:x:0:0:System administrator:/root:/bin/bash";
      })
      # For ssl
      dockerTools.caCertificates
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
