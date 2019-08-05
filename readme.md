# Aulang

C-like programming language running on the [Auro VM](https://gitlab.com/aurovm/spec#auro). It's not designed for application development, but as a glue language between Auro and other better designed languages. The language is complete enough to be written in itself, but it's a pain to use because of the lack of advanced features and horrendous debugging (for now).

[Language Reference](/aulang.md).

[Online editor](http://arnaud.com.ve/auro/?lang=aulang).

To install it, you first need to install the [Auro VM implementation](https://gitlab.com/aurovm/aurovm), and then run `bash build.sh install`.

To compile a auro file, run `auro aulang <source.au> <target>` and run it with `auro <target>`. Aditionally, that module can then be installed system-wide with `auro --install <target>`.

Running `bash build.sh bootstrap` compiles the source code with whatever version of aulang is already installed, and then compiles it again with the resulting modules.

**TODO**:

- Good typechecking
- char type
- Multiple sized primitives
- Module independent arrays
- for, switch, do while, continue *(Is it better to not include them?)*
- Record type
- Union type
- Maybe improve null syntax
- Inspect imported modules and import their items automatically
- Anonymous function expressions

# Culang

The previous version of the language was named culang, and it's extension is `.cu`, to install that one checkout the *culang* branch and install it. The source of aulang is written in it.
