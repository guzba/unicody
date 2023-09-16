from std/unicode import Rune

export unicode.Rune

const
    surrogateMin = 0xd800'i32
    surrogateMax = 0xdfff'i32
    utf8Max = 0x0010ffff'i32

proc isSurrogate*(rune: Rune): bool {.inline.} =
  rune.int32 >= surrogateMin and rune.int32 <= surrogateMax

proc validateUtf8*(s: openarray[char]): int {.raises: [].} =
  var i: int
  while i < s.len:
    # Fast path: check if the next 8 bytes are ASCII
    if i + 8 <= s.len:
      var tmp: uint64
      copyMem(tmp.addr, s[i].unsafeAddr, 8)
      if (tmp and 0x8080808080808080'u64) == 0:
        i += 8
        continue

    var c0 = s[i].uint8
    while c0 < 0b10000000:
      inc i
      if i == s.len:
        return -1
      c0 = s[i].uint8

    if (c0 and 0b11100000) == 0b11000000:
      if i + 1 >= s.len:
        return i
      let c1 = s[i + 1].uint8
      if (c1 and 0b11000000) != 0b10000000:
        return i + 1
      let codePoint =
        ((c0.int32 and 0b00011111) shl 6) or
        (c1.int32 and 0b00111111)
      if codePoint < 0x80:
        return i
      i += 2
    elif (c0 and 0b11110000) == 0b11100000:
      if i + 2 >= s.len:
        return i
      let
        c1 = s[i + 1].uint8
        c2 = s[i + 2].uint8
      if (c1 and 0b11000000) != 0b10000000:
        return i + 1
      if (c2 and 0b11000000) != 0b10000000:
        return i + 2
      let codePoint =
        ((c0.int32 and 0b00001111) shl 12) or
        ((c1.int32 and 0b00111111) shl 6) or
        (c2.int32 and 0b00111111)
      if codePoint < 0x800:
        return i
      if Rune(codePoint).isSurrogate():
        return i
      i += 3
    elif (c0 and 0b11111000) == 0b11110000:
      if i + 3 >= s.len:
        return i
      let
        c1 = s[i + 1].uint8
        c2 = s[i + 2].uint8
        c3 = s[i + 3].uint8
      if (c1 and 0b11000000) != 0b10000000:
        return i + 1
      if (c2 and 0b11000000) != 0b10000000:
        return i + 2
      if (c3 and 0b11000000) != 0b10000000:
        return i + 3
      let codePoint =
        ((c0.int32 and 0b00000111) shl 18) or
        ((c1.int32 and 0b00111111) shl 12) or
        ((c2.int32 and 0b00111111) shl 6) or
        (c3.int32 and 0b00111111)
      if codePoint < 0xffff or codePoint > utf8Max:
        return i
      i += 4
    else:
      return i

  # Everything looks good
  return -1
