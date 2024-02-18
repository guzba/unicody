import std/options

when defined(amd64):
  import nimsimd/sse2
elif defined(arm64):
  import nimsimd/neon

from std/unicode import Rune

export unicode.Rune

const
  replacementRune* = Rune(0xfffd)
  highSurrogateMin* = 0xd800'i32
  highSurrogateMax* = 0xdbff'i32
  lowSurrogateMin* = 0xdc00'i32
  lowSurrogateMax* = 0xdfff'i32
  utf8Max = 0x0010ffff'i32

when defined(release):
  {.push checks: off.}

proc `==`*(a, b: Rune): bool {.inline.} =
  a.int32 == b.int32

proc isHighSurrogate*(rune: Rune): bool {.inline.} =
  rune.int32 >= highSurrogateMin and rune.int32 <= highSurrogateMax

proc isLowSurrogate*(rune: Rune): bool {.inline.} =
  rune.int32 >= lowSurrogateMin and rune.int32 <= lowSurrogateMax

proc isSurrogate*(rune: Rune): bool {.inline.} =
  rune.isHighSurrogate() or rune.isLowSurrogate()

proc isValid*(rune: Rune): bool {.inline.} =
  not rune.isSurrogate() and rune.int32 <= utf8Max

proc unsafeSize*(rune: Rune): int {.inline.} =
  ## Returns the number of bytes the rune takes without checking
  ## if the rune is valid.
  if rune.uint32 <= 0x7f'u32:
    result = 1
  elif rune.uint32 <= 0x7ff'u32:
    result = 2
  elif rune.uint32 <= 0xffff'u32:
    result = 3
  else:
    result = 4

proc size*(rune: Rune): int =
  ## Returns the number of bytes the rune takes.
  if not rune.isValid():
    raise newException(CatchableError, "Invalid rune")
  rune.unsafeSize()

proc unsafeAdd*(s: var string, rune: Rune) =
  ## Adds the rune to the string without checking if the rune is valid.
  if rune.uint32 <= 0x7f'u32:
    s.setLen(s.len + 1)
    s[s.high] = rune.char
  elif rune.uint32 <= 0x7ff'u32:
    s.setLen(s.len + 2)
    s[s.high - 1] = ((rune.uint32 shr 6) or 0b11000000).char
    s[s.high] = ((rune.uint32 and 0b00111111) or (0b10000000)).char
  elif rune.uint32 <= 0xffff'u32:
    s.setLen(s.len + 3)
    s[s.high - 2] = ((rune.uint32 shr 12) or 0b11100000).char
    s[s.high - 1] = ((rune.uint32 shr 6 and 0b00111111) or (0b10000000)).char
    s[s.high] = ((rune.uint32 and 0b00111111) or (0b10000000)).char
  else:
    s.setLen(s.len + 4)
    s[s.high - 3] = ((rune.uint32 shr 18) or 0b11110000).char
    s[s.high - 2] = ((rune.uint32 shr 12 and 0b00111111) or (0b10000000)).char
    s[s.high - 1] = ((rune.uint32 shr 6 and 0b00111111) or (0b10000000)).char
    s[s.high] = ((rune.uint32 and 0b00111111) or (0b10000000)).char

proc add*(s: var string, rune: Rune) =
  ## Adds the rune to the string.
  if not rune.isValid():
    raise newException(CatchableError, "Invalid rune")
  s.unsafeAdd(rune)

proc `$`*(rune: Rune): string {.inline.} =
  result.add(rune)

proc toUTF8*(rune: Rune): string {.inline.} =
  $rune

proc `$`*(runes: seq[Rune]): string =
  for rune in runes:
    result.add(rune)

proc validRuneAt*(s: openarray[char], i: int): Option[Rune] =
  if i >= s.len:
    return

  let c0 = s[i].uint8
  if (c0 and 0b10000000) == 0:
    return some(c0.Rune)

  if (c0 and 0b11100000) == 0b11000000:
    if i + 1 >= s.len:
      return
    let c1 = s[i + 1].uint8
    if (c1 and 0b11000000) != 0b10000000:
      return
    let codepoint =
      ((c0.int32 and 0b00011111) shl 6) or
      (c1.int32 and 0b00111111)
    if codepoint < 0x80:
      return
    return some(Rune(codepoint))

  if (c0 and 0b11110000) == 0b11100000:
    if i + 2 >= s.len:
      return
    let
      c1 = s[i + 1].uint8
      c2 = s[i + 2].uint8
    if (c1 and 0b11000000) != 0b10000000:
      return
    if (c2 and 0b11000000) != 0b10000000:
      return
    let codepoint =
      ((c0.int32 and 0b00001111) shl 12) or
      ((c1.int32 and 0b00111111) shl 6) or
      (c2.int32 and 0b00111111)
    if codepoint < 0x800 or Rune(codepoint).isSurrogate():
      return
    return some(Rune(codepoint))

  if (c0 and 0b11111000) == 0b11110000:
    if i + 3 >= s.len:
      return
    let
      c1 = s[i + 1].uint8
      c2 = s[i + 2].uint8
      c3 = s[i + 3].uint8
    if (c1 and 0b11000000) != 0b10000000:
      return
    if (c2 and 0b11000000) != 0b10000000:
      return
    if (c3 and 0b11000000) != 0b10000000:
      return
    let codepoint =
      ((c0.int32 and 0b00000111) shl 18) or
      ((c1.int32 and 0b00111111) shl 12) or
      ((c2.int32 and 0b00111111) shl 6) or
      (c3.int32 and 0b00111111)
    if codepoint < 0xffff or codepoint > utf8Max:
      return
    return some(Rune(codepoint))

proc runeAt*(s: openarray[char]; i: int): Rune =
  let rune = s.validRuneAt(i)
  if rune.isSome:
    return rune.unsafeGet
  raise newException(CatchableError, "Invalid rune at offset " & $i)

proc validateUtf8*(s: openarray[char]): int {.raises: [].} =
  var i: int
  while i < s.len:
    when nimvm:
      discard
    else:
      when defined(js):
        discard
      else:
        when defined(amd64):
          if i + 16 <= s.len:
            let tmp = mm_loadu_si128(s[i].unsafeAddr)
            if mm_movemask_epi8(tmp) == 0:
              i += 16
              continue
        elif defined(arm64):
          if i + 16 <= s.len:
            let
              tmp = vld1q_u8(s[i].unsafeAddr)
              cmp = vandq_u8(tmp, vmovq_n_u8(128))
              mask = vget_lane_u64(
                cast[uint64x1](vorr_u8(vget_low_u8(cmp), vget_high_u8(cmp))),
                0
              )
            if mask == 0:
              i += 16
              continue
        else:
          # Fast path: check if the next 8 bytes are ASCII
          if i + 8 <= s.len:
            var tmp: uint64
            copyMem(tmp.addr, s[i].unsafeAddr, 8)
            if (tmp and 0x8080808080808080'u64) == 0:
              i += 8
              continue

    # let rune = s.validRuneAt(i)
    # if rune.isSome:
    #   i += rune.unsafeGet.unsafeSize()
    # else:
    #   return i

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
      let codepoint =
        ((c0.int32 and 0b00011111) shl 6) or
        (c1.int32 and 0b00111111)
      if codepoint < 0x80:
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
      let codepoint =
        ((c0.int32 and 0b00001111) shl 12) or
        ((c1.int32 and 0b00111111) shl 6) or
        (c2.int32 and 0b00111111)
      if codepoint < 0x800 or Rune(codepoint).isSurrogate():
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
      let codepoint =
        ((c0.int32 and 0b00000111) shl 18) or
        ((c1.int32 and 0b00111111) shl 12) or
        ((c2.int32 and 0b00111111) shl 6) or
        (c3.int32 and 0b00111111)
      if codepoint < 0xffff or codepoint > utf8Max:
        return i
      i += 4
    else:
      return i

  # Everything looks good
  return -1

proc copyMem(dst: var string, src: openarray[char], len: int) =
  when nimvm:
    # result = s[0 ..< s.len] # seq[char]? wtf?
    dst.setLen(len)
    for i in 0 ..< len:
      dst[i] = src[i]
  else:
    when defined(js):
      dst.setLen(len)
      for i in 0 ..< len:
        dst[i] = src[i]
    else:
      dst.setLen(len)
      copyMem(dst[0].addr, src[0].unsafeAddr, len)

proc truncateUtf8*(s: openarray[char], maxBytes: int): string =
  if validateUtf8(s) != -1:
    raise newException(CatchableError, "Invalid UTF-8")

  if s.len < maxBytes:
    if s.len > 0:
      copyMem(result, s, s.len)
    return

  var i: int
  while i < s.len:
    let
      rune = s.validRuneAt(i) # Already validated above
      runeSize = rune.get.size
    if i + runeSize > maxBytes:
      if i > 0:
        copyMem(result, s, i)
      return
    i += runeSize

proc containsControlCharacter*(s: openarray[char]): bool =
  var i: int
  while i < s.len:
    when nimvm:
      discard
    else:
      when defined(js):
        discard
      else:
        when defined(amd64):
          if i + 16 <= s.len:
            let
              tmp = mm_loadu_si128(s[i].unsafeAddr)
              notMultiByte = mm_cmpgt_epi8(tmp, mm_set1_epi8(-1))
              c = mm_cmplt_epi8(tmp, mm_set1_epi8(32))
              e = mm_cmpeq_epi8(tmp, mm_set1_epi8(127))
              ce = mm_or_si128(c, e)
            if mm_movemask_epi8(mm_and_si128(ce, notMultiByte)) != 0:
              return true
            i += 16
            continue
        elif defined(arm64):
          if i + 16 <= s.len:
            let
              tmp = vld1q_u8(s[i].unsafeAddr)
              c = vcltq_u8(tmp, vmovq_n_u8(32))
              e = vceqq_u8(tmp, vmovq_n_u8(127))
              ce = vorrq_u8(c, e)
              mask = vget_lane_u64(
                cast[uint64x1](vorr_u8(vget_low_u8(ce), vget_high_u8(ce))),
                0
              )
            if mask != 0:
              return true
            i += 16
            continue

        # # Fast path: check the next 8 bytes
        # if i + 8 <= s.len:
        #   var tmp: uint64
        #   copyMem(tmp.addr, s[i].unsafeAddr, 8)
        #   # 0b10000000 (0x80) for 128, there are no multi-byte characters
        #   if (tmp and 0x8080808080808080'u64) == 0:
        #     let
        #       # 0b01100000 (0x60) for >= 32
        #       a = (tmp and 0x6060606060606060'u64)
        #       b = (a or (a shl 1))
        #       # 0b01000000 (0x40)
        #       c = (b and 0x4040404040404040'u64) != 0x4040404040404040'u64

        #       # 0b01111111 (127) + 1 becomes 0b100000000 (0x80)
        #       d = (tmp + 0x0101010101010101'u64)
        #       e = (d and 0x8080808080808080'u64) != 0

        #     if c or e:
        #       return true
        #     i += 8
        #     continue

    let c = cast[uint8](s[i])
    if c < 32'u8 or c == 127'u8:
      return true
    inc i

when defined(release):
  {.pop.}
