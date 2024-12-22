import std/options, std/bitops

when defined(amd64):
  import nimsimd/sse2
elif defined(arm64):
  import nimsimd/neon

from std/unicode import Rune

export unicode.Rune, options

# when defined(amd64):
#   {.compile: "amd64.s".}

#   when defined(windows):
#     {.push importc, stdcall.}
#     proc validateUtf8_windows*(p: pointer, len: int): int
#     proc findControlCharacter_windows*(p: pointer, len: int): int
#     {.pop.}

#     when defined(nimHasQuirky):
#       {.push quirky: on.}

#     proc findControlCharacter*(s: openarray[char]): int {.inline, raises: [].} =
#       if s.len <= 0:
#         return -1
#       findControlCharacter_windows(s[0].addr, s.len)

#     when defined(nimHasQuirky):
#       {.pop.}

const
  replacementRune* = Rune(0xfffd)
  highSurrogateMin* = 0xd800'i32
  highSurrogateMax* = 0xdbff'i32
  lowSurrogateMin* = 0xdc00'i32
  lowSurrogateMax* = 0xdfff'i32
  utf8Max* = 0x0010ffff'i32

when defined(release):
  {.push checks: off.}

proc find*(s: openarray[char], target: char, start = 0): int =
  var i = start
  when nimvm:
    discard
  else:
    when defined(js):
      discard
    else:
      when defined(amd64):
        let vecTarget = mm_set1_epi8(target)
        while i + 16 <= s.len:
          let
            tmp = mm_loadu_si128(s[i].unsafeAddr)
            eq = mm_cmpeq_epi8(vecTarget, tmp)
            mask = mm_movemask_epi8(eq)
          if mask != 0:
            return i + countTrailingZeroBits(mask)
          i += 16
      elif defined(arm64):
        while i + 16 <= s.len:
          let
            v0 = vld1q_u8(s[i].unsafeAddr)
            v1 = vceqq_u8(v0, vmovq_n_u8(cast[uint8](target)))
            v2 = vshrn_n_u16(vreinterpretq_u16_u8(v1), 4)
            v3 = vget_lane_u64(vreinterpret_u64_u8(v2), 0)
          if v3 != 0:
            return i + countTrailingZeroBits(v3) div 4
          i += 16

  while i < s.len:
    if s[i] == target:
      return i
    inc i

  return -1

template `==`*(a, b: Rune): bool =
  a.int32 == b.int32

template isHighSurrogate*(rune: Rune): bool =
  rune.int32 >= highSurrogateMin and rune.int32 <= highSurrogateMax

template isLowSurrogate*(rune: Rune): bool =
  rune.int32 >= lowSurrogateMin and rune.int32 <= lowSurrogateMax

template isSurrogate*(rune: Rune): bool =
  rune.isHighSurrogate() or rune.isLowSurrogate()

template isValid*(rune: Rune): bool =
  not rune.isSurrogate() and rune.int32 <= utf8Max

template unsafeSize*(rune: Rune): int =
  ## Returns the number of bytes the rune takes without checking
  ## if the rune is valid.
  if rune.uint32 <= 0x7f'u32:
    1
  elif rune.uint32 <= 0x7ff'u32:
    2
  elif rune.uint32 <= 0xffff'u32:
    3
  else:
    4

proc size*(rune: Rune): int =
  ## Returns the number of bytes the rune takes.
  if not rune.isValid():
    raise newException(CatchableError, "Invalid rune")
  rune.unsafeSize()

# when defined(nimHasQuirky):
#   proc unsafeAdd*(s: var string, rune: Rune) {.quirky.}
# else:
#   proc unsafeAdd*(s: var string, rune: Rune)

proc unsafeAdd*(s: var string, rune: Rune) =
  ## Adds the rune to the string without checking if the rune is valid.

  template slow =
    if rune.uint32 <= 0x7f'u32:
      s.add rune.char
    elif rune.uint32 <= 0x7ff'u32:
      s.add ((rune.uint32 shr 6) or 0b11000000).char
      s.add ((rune.uint32 and 0b00111111) or 0b10000000).char
    elif rune.uint32 <= 0xffff'u32:
      s.add ((rune.uint32 shr 12) or 0b11100000).char
      s.add ((rune.uint32 shr 6 and 0b00111111) or 0b10000000).char
      s.add ((rune.uint32 and 0b00111111) or 0b10000000).char
    else:
      s.add ((rune.uint32 shr 18) or 0b11110000).char
      s.add ((rune.uint32 shr 12 and 0b00111111) or 0b10000000).char
      s.add ((rune.uint32 shr 6 and 0b00111111) or 0b10000000).char
      s.add ((rune.uint32 and 0b00111111) or (0b10000000)).char

  template fast =
    if rune.uint32 <= 0x7f'u32:
      s.add rune.char
    elif rune.uint32 <= 0x7ff'u32:
      s.setLen(s.len + 2)
      let p = cast[ptr UncheckedArray[char]](s.cstring)
      p[s.high - 1] = ((rune.uint32 shr 6) or 0b11000000).char
      p[s.high] = ((rune.uint32 and 0b00111111) or 0b10000000).char
    elif rune.uint32 <= 0xffff'u32:
      s.setLen(s.len + 3)
      let p = cast[ptr UncheckedArray[char]](s.cstring)
      p[s.high - 2] = ((rune.uint32 shr 12) or 0b11100000).char
      p[s.high - 1] = ((rune.uint32 shr 6 and 0b00111111) or 0b10000000).char
      p[s.high] = ((rune.uint32 and 0b00111111) or 0b10000000).char
    else:
      s.setLen(s.len + 4)
      when defined(js):
        s[s.high - 3] = ((rune.uint32 shr 18) or 0b11110000).char
        s[s.high - 2] = ((rune.uint32 shr 12 and 0b00111111) or 0b10000000).char
        s[s.high - 1] = ((rune.uint32 shr 6 and 0b00111111) or 0b10000000).char
        s[s.high] = ((rune.uint32 and 0b00111111) or (0b10000000)).char
      else:
        let p = cast[ptr UncheckedArray[char]](s.cstring)
        var
          a = ((rune.uint32 shr 18) or 0b11110000)
          b = ((rune.uint32 shr 12 and 0b00111111) or 0b10000000) shl 8
          c = ((rune.uint32 shr 6 and 0b00111111) or 0b10000000) shl 16
          d = ((rune.uint32 and 0b00111111) or (0b10000000)) shl 24
          tmp = a or b or c or d
        copyMem(p[s.high - 3].addr, tmp.addr, 4)

  when nimvm:
    slow()
  else:
    when defined(js):
      slow()
    else:
      fast()

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
  let readableBytes = s.len - i
  if readableBytes <= 0:
    return

  let c0 = s[i].uint8
  if c0 < 0b10000000:
    return some(Rune(c0))

  # Looks multi-byte

  if readableBytes == 1:
    return

  elif readableBytes >= 4:
    var tmp: uint32
    when defined(js):
      let
        x = s[i + 3].uint32
        y = s[i + 2].uint32
        z = s[i + 1].uint32
        w = s[i + 0].uint32
      tmp = (x shl 24) or (y shl 16) or (z shl 8) or w
    else:
      copyMem(tmp.addr, s[i].unsafeAddr, 4)
    let
      b = (tmp and 0b1100000011100000'u32)
      c = (tmp and 0b110000001100000011110000'u32)
      d = (tmp and 0b11000000110000001100000011111000'u32)
    if b == 0b1000000011000000'u32:
      let codepoint =
        ((c0.int32 and 0b00011111) shl 6) or
        (s[i + 1].int32 and 0b00111111)
      if codepoint >= 0x80:
        return some(Rune(codepoint))
    elif c == 0b100000001000000011100000'u32:
      let codepoint =
        ((c0.int32 and 0b00001111) shl 12) or
        ((s[i + 1].int32 and 0b00111111) shl 6) or
        (s[i + 2].int32 and 0b00111111)
      if codepoint >= 0x800 and not Rune(codepoint).isSurrogate():
        return some(Rune(codepoint))
    elif d == 0b10000000100000001000000011110000'u32:
      let codepoint =
        ((c0.int32 and 0b00000111) shl 18) or
        ((s[i + 1].int32 and 0b00111111) shl 12) or
        ((s[i + 2].int32 and 0b00111111) shl 6) or
        (s[i + 3].int32 and 0b00111111)
      if codepoint >= 0xffff and codepoint <= utf8Max:
        return some(Rune(codepoint))

  else: # 2 or 3 readable bytes
    let c1 = s[i + 1].uint8
    if (c1 and 0b11000000) != 0b10000000:
      return

    if (c0 and 0b11100000) == 0b11000000:
      let codepoint =
        ((c0.int32 and 0b00011111) shl 6) or
        (c1.int32 and 0b00111111)
      if codepoint >= 0x80:
        return some(Rune(codepoint))

    elif readableBytes == 3 and (c0 and 0b11110000) == 0b11100000:
      let c2 = s[i + 2].uint8
      if (c2 and 0b11000000) == 0b10000000:
        let codepoint =
          ((c0.int32 and 0b00001111) shl 12) or
          ((c1.int32 and 0b00111111) shl 6) or
          (c2.int32 and 0b00111111)
        if codepoint >= 0x800 and not Rune(codepoint).isSurrogate():
          return some(Rune(codepoint))

proc runeAt*(s: openarray[char]; i: int): Rune =
  let rune = s.validRuneAt(i)
  if rune.isSome:
    return rune.unsafeGet
  raise newException(CatchableError, "Invalid rune at offset " & $i)

proc validateUtf8*(s: openarray[char]): int {.raises: [].} =
  var i: int
  while true:
    when nimvm:
      discard
    else:
      when defined(js):
        discard
      else:
        when defined(amd64):
          while i + 16 <= s.len:
            let
              tmp = mm_loadu_si128(s[i].unsafeAddr)
              mask = mm_movemask_epi8(tmp)
            if mask == 0:
              i += 16
              continue
            # i += countTrailingZeroBits(mask) # slow for some reason
            break
        elif defined(arm64):
          if i + 16 <= s.len:
            let tmp = vld1q_u8(s[i].unsafeAddr)
            if vmaxvq_u8(vandq_u8(tmp, vmovq_n_u8(128))) == 0:
              i += 16
              continue
        else:
          # Fast path: check if the next 8 bytes are ASCII
          while i + 8 <= s.len:
            var tmp: uint64
            copyMem(tmp.addr, s[i].unsafeAddr, 8)
            if (tmp and 0x8080808080808080'u64) == 0:
              i += 8
              continue
            break

    # let rune = s.validRuneAt(i)
    # if rune.isSome:
    #   i += rune.unsafeGet.unsafeSize()
    # else:
    #   return i

    let readableBytes = s.len - i

    if readableBytes <= 0:
      break

    let c0 = s[i].uint8
    if c0 < 0b10000000:
      inc i
      continue

    if readableBytes == 1:
      return i

    elif readableBytes >= 4:
      var tmp: uint32
      when defined(js):
        let
          x = s[i + 3].uint32
          y = s[i + 2].uint32
          z = s[i + 1].uint32
          w = s[i + 0].uint32
        tmp = (x shl 24) or (y shl 16) or (z shl 8) or w
      else:
        copyMem(tmp.addr, s[i].unsafeAddr, 4)
      let
        b = (tmp and 0b1100000011100000'u32)
        c = (tmp and 0b110000001100000011110000'u32)
        d = (tmp and 0b11000000110000001100000011111000'u32)
      if b == 0b1000000011000000'u32:
        let codepoint =
          ((c0.int32 and 0b00011111) shl 6) or
          (s[i + 1].int32 and 0b00111111)
        if codepoint < 0x80:
          return i
        i += 2
      elif c == 0b100000001000000011100000'u32:
        let codepoint =
          ((c0.int32 and 0b00001111) shl 12) or
          ((s[i + 1].int32 and 0b00111111) shl 6) or
          (s[i + 2].int32 and 0b00111111)
        if codepoint < 0x800 or Rune(codepoint).isSurrogate():
          return i
        i += 3
      elif d == 0b10000000100000001000000011110000'u32:
        let codepoint =
          ((c0.int32 and 0b00000111) shl 18) or
          ((s[i + 1].int32 and 0b00111111) shl 12) or
          ((s[i + 2].int32 and 0b00111111) shl 6) or
          (s[i + 3].int32 and 0b00111111)
        if codepoint < 0xffff or codepoint > utf8Max:
          return i
        i += 4
      else: # Determine where the bad byte is
        let
          c1 = s[i + 1].uint8
          c2 = s[i + 2].uint8
        if (c0 and 0b11100000) == 0b11000000:
          return i + 1
        elif (c0 and 0b11110000) == 0b11100000:
          if (c1 and 0b11000000) != 0b10000000:
            return i + 1
          else:
            return i + 2
        elif (c0 and 0b11111000) == 0b11110000:
          if (c1 and 0b11000000) != 0b10000000:
            return i + 1
          elif (c2 and 0b11000000) != 0b10000000:
            return i + 2
          else:
            return i + 3
        else:
          return i

    else: # 2 or 3 readable bytes
      let c1 = s[i + 1].uint8
      if (c1 and 0b11000000) != 0b10000000:
        return i + 1

      if (c0 and 0b11100000) == 0b11000000:
        let codepoint =
          ((c0.int32 and 0b00011111) shl 6) or
          (c1.int32 and 0b00111111)
        if codepoint < 0x80:
          return i
        i += 2

      elif readableBytes == 3 and (c0 and 0b11110000) == 0b11100000:
        let c2 = s[i + 2].uint8
        if (c2 and 0b11000000) == 0b10000000:
          let codepoint =
            ((c0.int32 and 0b00001111) shl 12) or
            ((c1.int32 and 0b00111111) shl 6) or
            (c2.int32 and 0b00111111)
          if codepoint < 0x800 or Rune(codepoint).isSurrogate():
            return i
          i += 3
        else:
          return i + 2

      else:
        return i

  # Everything looks good
  return -1

proc truncateUtf8*(s: openarray[char], maxBytes: int): string =
  if validateUtf8(s) != -1:
    raise newException(CatchableError, "Invalid UTF-8")

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
        if len > 0:
          dst.setLen(len)
          copyMem(dst[0].addr, src[0].unsafeAddr, len)

  if s.len < maxBytes:
    copyMem(result, s, s.len)
    return

  var i: int
  while i < s.len:
    let
      rune = s.validRuneAt(i) # Already validated above
      runeSize = rune.get.size
    if i + runeSize > maxBytes:
      copyMem(result, s, i)
      return
    i += runeSize

proc containsControlCharacter*(s: openarray[char]): bool =
  var i: int
  when nimvm:
    discard
  else:
    when defined(js):
      discard
    else:
      when defined(amd64):
        while i + 16 <= s.len:
          let
            tmp = mm_loadu_si128(s[i].unsafeAddr)
            multiByte = mm_cmpgt_epi8(mm_setzero_si128(), tmp)
            c = mm_cmplt_epi8(tmp, mm_set1_epi8(32))
            e = mm_cmpeq_epi8(tmp, mm_set1_epi8(127))
            ceMasked = mm_andnot_si128(multibyte, mm_or_si128(c, e))
          if mm_movemask_epi8(ceMasked) != 0:
            return true
          i += 16
      elif defined(arm64):
        while i + 16 <= s.len:
          let
            tmp = vld1q_u8(s[i].unsafeAddr)
            c = vcltq_u8(tmp, vmovq_n_u8(32))
            e = vceqq_u8(tmp, vmovq_n_u8(127))
            ce = vorrq_u8(c, e)
          if vmaxvq_u8(ce) != 0:
            return true
          i += 16

  while i < s.len:
    let c = cast[uint8](s[i])
    if c < 32'u8 or c == 127'u8:
      return true
    inc i

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

when defined(release):
  {.pop.}
