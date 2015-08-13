{ stdenv }:

{

  helloWorldPy = stdenv.mkDerivation rec {
    name = "hello_world.py";
    src = ./hello_world.py;
    buildCommand = ''
      mkdir -p $out
      cp ${src} $out/hello_world.py
    '';
  };

}
