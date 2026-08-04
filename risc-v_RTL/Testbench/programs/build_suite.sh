#!/usr/bin/env bash
# Build the riscv-tests rv32ui suite into artifacts the UVM testbench runs:
# Uses the CSR-free env
# Run in WSL Ubuntu

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS="${RISCV_TESTS:-$HOME/riscv-tests}/isa/rv32ui"
MACROS="${RISCV_TESTS:-$HOME/riscv-tests}/isa/macros/scalar"
ENVDIR="$HERE"                       # our riscv_test.h lives here
LINK="$HERE/link.ld"
BIN2HEX="$HERE/bin2hex.py"
SPIKE="${SPIKE:-$HOME/riscv/bin/spike}"
OUT="$HERE/rv32ui/build"

GCC=riscv64-unknown-elf-gcc
OBJCOPY=riscv64-unknown-elf-objcopy
OBJDUMP=riscv64-unknown-elf-objdump
MARCH=rv32i_zifencei                 # zifencei so fence.i (fence_i.S) assembles
MABI=ilp32
ISA=rv32i_zifencei                   # Spike ISA string (must allow fence.i)

# Tests that need CSR/trap support this core does not implement -> skip.
SKIP="ma_data"

mkdir -p "$OUT"
built=0; gccfail=0; skipped=0
: > "$OUT/_build_summary.txt"

for f in "$TESTS"/*.S; do
  name="$(basename "$f" .S)"
  case " $SKIP " in *" $name "*) echo "SKIP   $name"; skipped=$((skipped+1)); continue;; esac

  if ! "$GCC" -march=$MARCH -mabi=$MABI -nostdlib -nostartfiles \
        -I "$ENVDIR" -I "$MACROS" -T "$LINK" \
        "$f" -o "$OUT/$name.elf" 2> "$OUT/$name.gcc.log"; then
    echo "FAIL   $name  (gcc/link -- see build/$name.gcc.log)"
    gccfail=$((gccfail+1)); continue
  fi

  "$OBJCOPY" -O binary "$OUT/$name.elf" "$OUT/$name.bin"
  python3 "$BIN2HEX" "$OUT/$name.bin" "$OUT/$name.hex"
  "$OBJDUMP" -d "$OUT/$name.elf" > "$OUT/$name.dump"

  # Golden commit log, truncated at the store to tohost (halt point).
  "$SPIKE" --isa=$ISA -l --log-commits "$OUT/$name.elf" 2>&1 \
      | sed '/mem 0x80003ff0/q' > "$OUT/$name.spike.log"

  echo "BUILT  $name" | tee -a "$OUT/_build_summary.txt"
  built=$((built+1))
done

echo "-----------------------------------------------------"
echo "built=$built  gcc-fail=$gccfail  skipped=$skipped"
echo "artifacts in: $OUT"
