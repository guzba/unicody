import benchy, random, unicody

randomize()

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
