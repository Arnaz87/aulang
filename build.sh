#!/bin/env bash

if [ "$1" == "-h" -o "$1" == "--help" -o "$1" == "help" ]; then
  echo "bash build.sh [ -h | --help | help | test | dist | install | uninstall ]"
  exit
fi

FILES="aulang aulang.lexer aulang.parser aulang.compiler aulang.util aulang.writer"

# Este comando remplaza todas las palabras por aulang.palabra
# echo $X | sed -E 's/\w+/aulang.&/g'

if [ "$1" == "temp" ]; then
  cd dist; cp $FILES ..; cd ..
fi

if [ "$1" == "bootstrap" ]; then
  bash build.sh temp &&
  bash build.sh
  rm -f $FILES
  exit
fi

if [ "$1" == "test" ]; then
  bash build.sh &&
  echo compiling out &&
  auro --dir dist/ aulang test.au out &&
  echo running out &&
  auro out
  rm -f $FILES
  exit
fi

if [ "$1" == "uninstall" ]; then
  for a in $FILES; do
    auro --remove $a
  done
  exit
fi

if [ "$1" != "install" ]; then
  compile () { echo compiling $1; auro aulang $1.au dist/aulang.$1; }
  compile util &&
  compile lexer &&
  compile parser &&
  compile writer &&
  compile compiler &&
  echo compiling aulang &&
  auro aulang aulang.au dist/aulang ||
  (echo "Could not compile files"; exit)
fi

if [ "$1" == "install" -o "$1" == "install-build" ]; then
  cd dist
  for a in $FILES; do
    auro --install $a
  done
  exit
fi
