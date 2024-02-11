import benchy, random, unicody

randomize()

block:
  var strings: seq[string]
  for i in 0 ..< 10:
    var s: string
    for i in 0 ..< 1_000_000:
      let c = rand(127).char
      s.add(c)
    strings.add(s)

  timeIt "unicody validateUtf8":
    for s in strings:
      doAssert validateUtf8(s) == -1

block:
  var strings: seq[string]
  for i in 0 ..< 10:
    var s: string
    for i in 0 ..< 100_000:
      let rune = Rune(rand(0x0010ffff).int32)
      if rune.isValid():
        s.add(rune)
    strings.add(s)

  timeIt "unicody validateUtf8":
    for s in strings:
      discard validateUtf8(s)

# import std/unicode

# timeIt "std/unicode validateUtf8":
#   for s in strings:
#     discard unicode.validateUtf8(s)

block:
  var strings: seq[string]
  for i in 0 ..< 10:
    var s: string
    for i in 0 ..< 1_000_000:
      let c = rand(32 .. 126).char
      s.add(c)
    strings.add(s)

  timeIt "unicody containsControlCharacter":
    for s in strings:
      doAssert not containsControlCharacter(s)

block:
  var strings: seq[string]
  for i in 0 ..< 10:
    var s: string
    for i in 0 ..< 1_000_000:
      let c = rand(32 .. 126).char
      s.add(c)
    s[rand(s.high)] = rand(0 .. 31).char
    strings.add(s)

  timeIt "unicody containsControlCharacter 2":
    for s in strings:
      doAssert containsControlCharacter(s)
