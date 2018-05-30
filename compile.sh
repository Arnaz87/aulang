#!/bin/env bash

if [ "$1" == "-h" -o "$1" == "--help" -o "$1" == "help" ]; then
  echo "bash compile.sh [-h | --help | help ] [test | dist | install | uninstall]"
  exit
fi

FILES=$'culang culang\x1flexer culang\x1fparser culang\x1fcompiler culang\x1futil'

if [ "$1" == "clean" ]; then
  rm -f $FILES
  exit
fi

if [ "$1" == "test" ]; then sh compile.sh; fi

compile () { echo compiling $1; cobre6 culang $1.cu culang$'\x1f'$1; }
compile util &&
compile lexer &&
compile parser &&
compile compiler &&
echo compiling culang &&
cobre6 culang culang.cu culang

if [ "$1" == "dist" -o "$1" == "install" ]; then
  cp $FILES dist/
fi

if [ "$1" == "install" ]; then
  cd dist
  for a in $FILES; do
    cobre --install $a
  done
  exit
fi

if [ "$1" == "uninstall" ]; then
  for a in $FILES; do
    cobre --unnstall $a
  done
  exit
fi
