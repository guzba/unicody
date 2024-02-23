import random, unicody

randomize()

for i in 0 ..< 100_000:
  var s: string
  for i in 0 ..< 1 + rand(500):
    s.add rand(32 .. 126).char
  for i in 0 ..< 20:
    block:
      let
        pos = rand(s.high)
        oldValue = s[pos]
        newValue = rand(0 .. 31).char
      s[pos] = newValue
      doAssert containsControlCharacter(s)
      # doAssert findControlCharacter_windows(s.cstring, s.len) == pos
      s[pos] = oldValue
    block:
      let
        pos = rand(s.high)
        oldValue = s[pos]
        newValue = 127.char
      s[pos] = newValue
      doAssert containsControlCharacter(s)
      # doAssert findControlCharacter_windows(s.cstring, s.len) == pos
      s[pos] = oldValue
    block:
      let
        pos = rand(s.high)
        oldValue = s[pos]
        newValue = rand(128 .. 255).char
      s[pos] = newValue
      doAssert not containsControlCharacter(s)
      # doAssert findControlCharacter_windows(s.cstring, s.len) == -1
      s[pos] = oldValue

for i in 0 ..< 100_000:
  var s: string
  for i in 0 ..< 1 + rand(500):
    s.add rand(255).char

  try:
    if validateUtf8(s) > 0:
      continue
  except CatchableError:
    continue

  # s is valid so mess with it a bit
  for i in 0 ..< 100:
    let
      pos = rand(s.high)
      oldValue = s[pos]
      newValue = rand(255).char
    s[pos] = newValue
    try:
      discard validateUtf8(s)
    except CatchableError:
      discard
    s[pos] = oldValue
