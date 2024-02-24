import benchy, random, unicody

randomize()

block:
  var runes = newSeq[Rune](100_000)
  for i in 0 ..< runes.len:
    runes[i] = Rune(rand(0'i32 .. utf8Max))

  var s: string
  timeIt "unicody unsafeAdd rune":
    for rune in runes:
      s.unsafeAdd rune
    s.setLen(0)

block:
  var s: string
  for i in 0 ..< 100_000:
    s.add rand(32 .. 126).char

  timeIt "unicody validRuneAt ascii":
    var i: int
    while i != s.len:
      let rune = s.validRuneAt(i)
      i += rune.get.unsafeSize

block:
  var s: string
  for i in 0 ..< 100_000:
    let rune = Rune(rand(0'i32 .. utf8Max))
    if rune.isValid:
      s.unsafeAdd rune

  timeIt "unicody validRuneAt multi-byte":
    var i: int
    while i != s.len:
      let rune = s.validRuneAt(i)
      i += rune.get.unsafeSize

block:
  var strings: seq[string]
  for i in 0 ..< 10:
    var s: string
    for i in 0 ..< 1_000_000:
      let c = rand(127).char
      s.add(c)
    strings.add(s)

  timeIt "unicody validateUtf8 ascii":
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

  timeIt "unicody validateUtf8 multi-byte":
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

  timeIt "unicody containsControlCharacter false":
    for s in strings:
      doAssert not containsControlCharacter(s)

  # timeIt "unicody findControlCharacter -1":
  #   for s in strings:
  #     doAssert findControlCharacter(s) == -1

block:
  var strings: seq[string]
  for i in 0 ..< 10:
    var s: string
    for i in 0 ..< 1_000_000:
      let c = rand(32 .. 126).char
      s.add(c)
    s[rand(s.high)] = rand(0 .. 31).char
    strings.add(s)

  timeIt "unicody containsControlCharacter true":
    for s in strings:
      doAssert containsControlCharacter(s)

  # timeIt "unicody findControlCharacter != -1":
  #   for s in strings:
  #     doAssert findControlCharacter(s) != -1
