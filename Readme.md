# TEx

## Intriduction

**TEx** is a wrapper for the [TypeExtractor](https://github.com/nmggithub/TypeExtractor) CLI tool. It is written in Swift. Currently, it only provides helper commands for Darwin header parsing.

## Usage

TEx is written with the help of [Swift Argument Parser](https://github.com/apple/swift-argument-parser). Thus, much of the help functionality is provided by that library. Please read the usage outputs provided by that library for more information on how to use the `TEx` command.

### Passing Arguments Directly to TypeExtractor/Clang

At the end of your `TEx` command, you may add `--` followed by additional argments to be passed directly to TypeExtractor/Clang. [The `--` is a special marker that is generally used to denote the end of the parseable options.](https://unix.stackexchange.com/questions/147143/) The following arguments are still used, but they are not parsed as options by the original exectuable and instead taken as-is. See below:

```
/path/to/TEx [subcommand] [args] -- [te/clang args]
```