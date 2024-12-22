import random, std/options, unicody

randomize()

const
  goodSequences = [
    "a",
    "\xc3\xb1",
    "\xe2\x82\xa1",
    "\xf0\x90\x8c\xbc",
    "\xc2\x80",
    "\xf0\x90\x80\x80",
    "\xee\x80\x80",
    "\xef\xbb\xbf"
  ]
  badSequences = [
    "\xc3\x28",
    "\xa0\xa1",
    "\xe2\x28\xa1",
    "\xe2\x82\x28",
    "\xf0\x28\x8c\xbc",
    "\xf0\x90\x28\xbc",
    "\xf0\x28\x8c\x28",
    "\xc0\x9f",
    "\xf5\xff\xff\xff",
    "\xed\xa0\x81",
    "\xf8\x90\x80\x80\x80",
    "123456789012345\xed",
    "123456789012345\xf1",
    "123456789012345\xc2",
    "\xC2\x7F",
    "\xce",
    "\xce\xba\xe1",
    "\xce\xba\xe1\xbd",
    "\xce\xba\xe1\xbd\xb9\xcf",
    "\xce\xba\xe1\xbd\xb9\xcf\x83\xce",
    "\xce\xba\xe1\xbd\xb9\xcf\x83\xce\xbc\xce",
    "\xdf",
    "\xef\xbf",
    "\x80",
    "\x91\x85\x95\x9e",
    "\x6c\x02\x8e\x18",
    "\x25\x5b\x6e\x2c\x32\x2c\x5b\x5b\x33\x2c\x34\x2c\x05\x29\x2c\x33\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5d\x2c\x35\x2e\x33\x2c\x39\x2e\x33\x2c\x37\x2e\x33\x2c\x39\x2e\x34\x2c\x37\x2e\x33\x2c\x39\x2e\x33\x2c\x37\x2e\x33\x2c\x39\x2e\x34\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x20\x01\x01\x01\x01\x01\x02\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x23\x0a\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x7e\x7e\x0a\x0a\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5d\x2c\x37\x2e\x33\x2c\x39\x2e\x33\x2c\x37\x2e\x33\x2c\x39\x2e\x34\x2c\x37\x2e\x33\x2c\x39\x2e\x33\x2c\x37\x2e\x33\x2c\x39\x2e\x34\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x5d\x01\x01\x80\x01\x01\x01\x79\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01",
    "[[[[[[[[[[[[[[[\x80\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x010\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01",
    "\x20\x0b\x01\x01\x01\x64\x3a\x64\x3a\x64\x3a\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x5b\x30\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x80\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01",
    "\x0a\x04\x00\x00\xdb\xa1\xdd\xa1\xf1\xa0\xb6\x95\xe4\xb5\x89\xe7\x8f\x95\xe4\xa2\x83\xe7\x95\x89\xe7\x95\x91\xe7\x95\x89\x00\x01\x01\x1a\x20\x28\x00\x00\x60\x00\x00\x23\x00\xf1\xa0\xb6\x95\xe4\xb5\x89\xe7\x8f\x95\xe4\xa2\x83\xe7\x95\x89\xe7\x95\x91\xe7\x81\x00\x00\x01\x01\x1a\x20\x28\x00\x00\x60\x00\x00\x23\x00\x2f\x00\x00\x00\x00\x07\x04\x75\xc2\xa0\x34\x2f\x00\x00\x00\x00\x07\x04\x75\xc2\xa0\x33\x53\x2b",
    "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x1c\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
  ]

doAssert Rune(0x0394) == Rune(0x0394)

const a = block:
  var s: string
  s.unsafeAdd Rune(32)
  s

const ct = validateUtf8("0123456789")
doAssert ct == -1

for n in 0 .. 0xd800 - 1:
  doAssert not Rune(n).isSurrogate()
  doAssert Rune(n).isValid()

for n in 0xd800 .. 0xdfff:
  doAssert Rune(n).isSurrogate()
  doAssert not Rune(n).isValid()

for n in 0xdfff + 1 .. 0x0010ffff:
  doAssert not Rune(n).isSurrogate()
  doAssert Rune(n).isValid()

for s in goodSequences:
  doAssert validateUtf8(s) == -1

for s in badSequences:
  doAssert validateUtf8(s) >= 0

for s in goodSequences:
  var
    i: int
    s2: string
  while i < s.len:
    let rune = s.validRuneAt(i)
    s2.add(rune.get)
    i += rune.get.size
  doAssert s2 == s

for i in 0 ..< 10:
  var s: string
  for i in 0 ..< 100_000:
    let rune = Rune(rand(0x0010ffff).int32)
    if rune.isValid():
      s.add(rune)

  var
    i: int
    s2: string
  while i < s.len:
    let rune = s.validRuneAt(i)
    s2.add(rune.get)
    i += rune.get.size
  doAssert s2 == s

when not defined(js):
  block:
    let stressTest = readFile("tests/data/quickbrown.txt")
    doAssert validateUtf8(stressTest) == -1

block:
  let s = "añyóng:hÃllo;是$example"
  for i in 0 ..< 50:
    let truncated = truncateUtf8(s, i)
    doAssert truncated.len <= i
    doAssert truncated == s[0 ..< truncated.len]
    doAssert validateUtf8(truncated) == -1

block: # README
  doAssert truncateUtf8("🔒🔒🔒🔒🔒🔒🔒🔒🔒🔒", maxBytes = 10) == "🔒🔒"

  doAssert validateUtf8("abc🔒def") == -1 # Matches std/unicode proc signature

  let rune = "🔒".validRuneAt(0) # Returns Option[Rune]
  doAssert rune.isSome # A valid fune was found starting at offset 0

block:
  doAssert $Rune(0x20) == " "
  doAssert $Rune(0x0394) == "Δ"

block:
  doAssert $(@[Rune(0x0394), Rune(0x20), Rune(0x0394)]) == "Δ Δ"

block:
  doAssert " ".runeAt(0) == Rune(0x20)

  doAssertRaises CatchableError:
    discard "\xff".runeAt(0)

block:
  for i in 0 ..< 32:
    var s: string
    s.add i.char
    doAssert containsControlCharacter(s)

block:
  for _ in 0 ..< 100:
    var s: string
    let len = rand(1 .. 1000)
    for _ in 0 ..< len:
      s.add rand(32 .. 126).char
    s[rand(len - 1)] = rand(31).char
    doAssert containsControlCharacter(s)

block:
  let s = "some string goes here"
  doAssert s.find('s', start = 1) == 5

  doAssert "a".find("") == 0
  doAssert "a".find("a") == 0
  doAssert "a".find("ab") == -1

  doAssert "abc".find("c") == 2
  doAssert "abc".find("bc") == 1
  doAssert "abc".find("abc") == 0

  doAssert "abcdefghijklmnopqrstuvwxyz".find("yz") == 24
  doAssert "abcdefghijklmnopqrstuvwxyz".find("abcdefghijklmnopqrstuvwxy") == 0
  doAssert "abcdefghijklmnopqrstuvwxyz".find("bcdefghijklmnopqrstuvwxyz") == 1
  doAssert "abcdefghijklmnopqrstuvwxyz".find("fghijk") == 5

  doAssert "ab".find("b", start = 100) == -1

  doAssert "ab".find("b", last = 0) == -1
  doAssert "ab".find("b", start = 1, last = 0) == -1
