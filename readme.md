# Culang

C-like programming language running on the [Cobre VM](https://github.com/Arnaz87/cobrevm). The language is complete enough to be written in itself, but it's not very practical yet.

[Doucumentation](/culang.md).

To install it, you first need to install the [Cobre VM](https://github.com/Arnaz87/cobrevm), and then run `bash build.sh install`.

To compile a cobre file, run `cobre culang <source.cu> <target>` and run it with `cobre <target>`. Aditionally, that module can then be installed system-wide with `cobre --install <target>`.

Running `bash build.sh bootstrap` compiles the source code with whatever version of culang is installed, and then compiles it again with the resulting modules.

**TODO**:

- scopes (currently a single scope per function)
- Typechecking
- float type
- char type
- Multiple sized primitives
- Array syntax
- Module syntax
- Statics/Constants
- boolean expressions and ternary
- for, switch, do while, break, continue *(Is it better to not include them?)*
- struct-like types
- unions
- maybe improve null syntax
- any syntax
- compiler.cu is stupid, 1800 LOC! that's too much
- inspect imported modules and import their items automatically
