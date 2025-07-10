@ Estos mnemonics (UMUL, SMUL, DIV, .F32, .F16) no existen, tenemos que asignar algo que no este usado por ARMv7

.data
@ Integer (32-bit)
res_umul: .word 0x00000000
res_smul: .word 0x00000000
res_div: .word 0x00000000

@ Floating Point Single-Precision (32-bit)
res_fp32_add: .word 0x00000000
res_fp32_mul: .word 0x00000000

@ Floating Point Half-Precision (16-bit)
res_fp16_add: .hword 0x0000
res_fp16_mul: .hword 0x0000

.global main
main:
  @ --- Prueba 1: UMUL (Unsigned Multiplication) res_umul: 10000 (0x00002710) ---
  MOV r0, #200           @ Operando A
  MOV r1, #50            @ Operando B
  UMUL r2, r0, r1        @ r2 = r0 * r1  (200 * 50 = 10000)
  LDR r3, =res_umul      @ Cargar la direccion de memoria del resultado
  STR r2, [r3]           @ Almacenar el resultado en memoria

  @ --- Prueba 2: SMUL (Signed Multiplication) res_smul: -150 (0xFFFFFF6A) ---
  MOV r0, #-15           @ Operando A
  MOV r1, #10            @ Operando B
  SMUL r2, r0, r1        @ r2 = r0 * r1  (-15 * 10 = -150)
  LDR r3, =res_smul      @ Cargar la direccion de memoria del resultado
  STR r2, [r3]           @ Almacenar el resultado en memoria

  @ --- Prueba 3: DIV (Integer Division) res_div: 64 (0x00000040) ---
  MOV r0, #1024          @ Dividendo
  MOV r1, #16            @ Divisor
  DIV r2, r0, r1         @ r2 = r0 / r1 (1024 / 16 = 64)
  LDR r3, =res_div       @ Cargar la direccion de memoria del resultado
  STR r2, [r3]           @ Almacenar el resultado en memoria
    
  @ --- Prueba 4: ADD_FP32 res_fp32_add: 0x41640000 (14.25) ---
  LDR r0, #0x40600000    @ Operando A (3.5 en IEEE 754)
  LDR r1, #0x412C0000    @ Operando B (10.75 en IEEE 754)
  ADD.F32 r2, r0, r1     @ r2 = r0 + r1 (3.5 + 10.75 = 14.25)
  LDR r3, =res_fp32_add  @ Cargar la direccion de memoria del resultado
  STR r2, [r3]           @ Almacenar el resultado

  @ --- Prueba 5: MUL_FP32 res_fp32_mul: 0xC1200000 (-10.0) ---
  LDR r0, #0x40200000    @ Operando A (2.5 en IEEE 754)
  LDR r1, #0xC0800000    @ Operando B (-4.0 en IEEE 754)
  MUL.F32 r2, r0, r1     @ r2 = r0 * r1 (2.5 * -4.0 = -10.0)
  LDR r3, =res_fp32_mul  @ Cargar la direccion de memoria del resultado
  STR r2, [r3]           @ Almacenar el resultado

  @ --- Prueba 6: ADD_FP16 res_fp16_add: 0x4780 (7.5) ---
  MOV r0, #0x48A0        @ Operando A (9.25 en IEEE 754)
  MOV r1, #0xBF00        @ Operando B (-1.75 en IEEE 754)
  ADD.F16 r2, r0, r1     @ r2 = r0 + r1 (9.25 + -1.75 = 7.5)
  LDR r3, =res_fp16_add  @ Cargar la direccion de memoria del resultado
  STRH r2, [r3]          @ Almacenar el resultado de 16-bit (Store Halfword)

  @ --- Prueba 7: MUL_FP16 res_fp16_mul: 0x4180 (2.75) ---
  MOV r0, #0x4580        @ Operando A (5.5 en IEEE 754)
  MOV r1, #0x3800        @ Operando B (0.5 en IEEE 754)
  MUL.F16 r2, r0, r1     @ r2 = r0 * r1 (5.5 * 0.5 = 2.75)
  LDR r3, =res_fp16_mul  @ Cargar la direccion de memoria del resultado
  STRH r2, [r3]          @ Almacenar el resultado de 16-bit (Store Halfword)
