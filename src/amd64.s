.intel_syntax noprefix
.global validateUtf8_windows, findControlCharacter_windows, findControlCharacter_windows_nosimd

.data
  mm_set1_epi8_32:
    .fill 16, 1, 32
  mm_set1_epi8_127:
    .fill 16, 1, 127

.text
  validateUtf8_windows: // (ptr, len)
    // rcx = ptr
    // rdx = len
    ret

  findControlCharacter_windows: // (ptr, len)
    // rcx = ptr
    // rdx = len

    mov rax, -1
    mov r9, rcx

    cmp rdx, 16
    jl findControlCharacter_windows_loop

    findControlCharacter_windows_loop_simd:
      movdqu xmm0, [rcx]
      movdqu xmm1, mm_set1_epi8_32[rip]
      movdqu xmm2, xmm0
      pcmpgtb xmm1, xmm0
      pcmpeqb xmm0, mm_set1_epi8_127[rip]
      por xmm0, xmm1
      pxor xmm3, xmm3
      pcmpgtb xmm3, xmm2
      pandn xmm3, xmm0
      pmovmskb r10d, xmm3
      cmp r10d, 0
      jne found_control_character_by_simd
      add rcx, 16
      sub rdx, 16
      cmp rdx, 16
      jge findControlCharacter_windows_loop_simd

    cmp rdx, 0
    jle findControlCharacter_windows_end

    findControlCharacter_windows_loop:
      mov r8b, [rcx]
      cmp r8b, 32
      jb found_control_character
      cmp r8b, 127
      je found_control_character
      add rcx, 1
      sub rdx, 1
      jnz findControlCharacter_windows_loop
    
    jmp findControlCharacter_windows_end

    found_control_character_by_simd:
      // Move rcx forward to the bad index based on the mask
      bsf r11, r10
      add rcx, r11

    found_control_character:
      mov rax, rcx
      sub rax, r9

    findControlCharacter_windows_end:

    ret
