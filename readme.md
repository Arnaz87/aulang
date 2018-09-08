# Aulang

C-like programming language running on the [Auro VM](https://gitlab.com/aurovm). The language is complete enough to be written in itself, but it's not very practical yet.

[Doucumentation](/aulang.md).

To install it, you first need to install the [Auro VM implementation](https://gitlab.com/aurovm/aurovm), and then run `bash build.sh install`.

To compile a auro file, run `auro aulang <source.cu> <target>` and run it with `auro <target>`. Aditionally, that module can then be installed system-wide with `auro --install <target>`.

Running `bash build.sh bootstrap` compiles the source code with whatever version of aulang is already installed, and then compiles it again with the resulting modules.

**TODO**:

- Operator precedence
- Lexical scopes (currently a single scope per function)
- Good typechecking
- char type
- Multiple sized primitives
- Module independent arrays
- Module syntax
- for, switch, do while, break, continue *(Is it better to not include them?)*
- struct-like types
- unions
- maybe improve null syntax
- compiler.au is too big, 2100 LOC!
- inspect imported modules and import their items automatically
