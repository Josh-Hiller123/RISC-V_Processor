
// Because this riscv implements neither Zicsr nor traps, the environment would diverge from
// Spike immediately. Here pass/fail is signaled by a store to `tohost`
// at 0x8000_3FF0 (== HALT_ADDR).
//    - PASS: store 1              
//    - FAIL: store (TESTNUM<<1)|1 -> halt monitor prints FAIL,
//                                    Spike HTIF exit code = TESTNUM
#ifndef _ENV_RISCV_TEST_H
#define _ENV_RISCV_TEST_H

#define TESTNUM gp

#define RVTEST_RV32U
#define RVTEST_RV32M
#define RVTEST_RV32S
#define RVTEST_RV64U
#define RVTEST_RV64M
#define RVTEST_RV64S

#define RVTEST_CODE_BEGIN       \
        .section .text;         \
        .globl _start;          \
_start:

#define RVTEST_CODE_END                            \
        .pushsection .tohost, "aw", @progbits;     \
        .align 3; .globl tohost;   tohost:   .dword 0; \
        .align 3; .globl fromhost; fromhost: .dword 0; \
        .popsection

// Pass
#define RVTEST_PASS             \
        li   gp, 1;             \
        la   t0, tohost;        \
        sw   gp, 0(t0);         \
1:      j 1b;

// Fail
#define RVTEST_FAIL             \
        slli gp, gp, 1;         \
        ori  gp, gp, 1;         \
        la   t0, tohost;        \
        sw   gp, 0(t0);         \
1:      j 1b;

#define RVTEST_DATA_BEGIN .align 4;
#define RVTEST_DATA_END

#endif // _ENV_RISCV_TEST_H
