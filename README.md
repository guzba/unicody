# Unicody

`nimble install unicody`

[API reference](https://guzba.github.io/unicody/)

Unicody is an alternative to Nim's std/unicode module that is entirely focused on UTF-8.

Why create an alternative? Two primary motivating reasons:
* Currently, std/unicode handles invalid UTF-8 incorrectly. See [1](https://github.com/nim-lang/Nim/issues/10750) and [2](https://github.com/nim-lang/Nim/issues/19333).
* Working with UTF-8 for a web server has lead me to wanting different behavior and additional procs.

I created `unicody` so these changes and additions have a place to live and so all of my own projects can make use of this module.

Unicody is written entirely in Nim so no external linking, deps, compiler flags, or whatever is necessary.

### Drop-in replacement

A goal for Unicody is to be a drop-in replacement for std/unicode. To enable this, Unicody matches proc signatures where alternative implementations have been written.

Currently Unicody does not have implementations for most procs in std/unicode so it is not correct to say that Unicody is a complete drop-in replacement for everything.

While Unicody does not have every proc covered, a core set of procs are implemented that enable quite a lot of use-cases.

### Compatibility with std/unicode

Unicody does not currently have an implementation of most procs in std/unicode. For this reason, and for avoiding unnecessary annoyance, Unicody is set up to work co-operatively with std/unicode. You can import both and `Rune` is the same everywhere so you can mix and match procs as needed.

Note that you may need to specify which version of some procs you want to call if you import both, eg `unicody.validateUtf8` vs just `validateUtf8`.

## Examples

```nim
doAssert truncateUtf8("🔒🔒🔒🔒🔒🔒🔒🔒🔒🔒", maxBytes = 10) == "🔒🔒"
```

```nim
doAssert validateUtf8("abc🔒def") == -1 # Matches std/unicode proc signature
```

```nim
let rune = "🔒".validRuneAt(0) # Returns Option[Rune]
doAssert rune.isSome # A valid rune was found starting at offset 0
```

## Testing

`nimble test`

To prevent Unicody from causing a crash or otherwise misbehaving on bad input data, a fuzzer has been run against it. You can run the fuzzer any time by running `nim c -r tests/fuzz.nim`.
