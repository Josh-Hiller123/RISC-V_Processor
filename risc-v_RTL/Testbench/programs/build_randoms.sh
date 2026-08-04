# build_randoms.sh -- build constrained-random programs into TB artifacts.
#   src/rand_<seed>.S  ->  build/rand_<seed>.{hex,spike.log,elf,dump}
# Random programs are self-contained (own _start / prologue / epilogue / tohost),
# Run in WSL Ubuntu:  bash build_randoms.sh
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # .../programs/randoms
SRC="$HERE/randoms/src"
OUT="$HERE/randoms/build"
LINK="$HERE/link.ld"
BIN2HEX="$HERE/bin2hex.py"
SPIKE="${SPIKE:-$HOME/riscv/bin/spike}"

GCC=riscv64-unknown-elf-gcc
OBJCOPY=riscv64-unknown-elf-objcopy
OBJDUMP=riscv64-unknown-elf-objdump
MARCH=rv32i          # no fence.i in random programs
MABI=ilp32
ISA=rv32i            # Spike ISA (matches; halt store at tohost = 0x8000_3FF0)

mkdir -p "$OUT"
shopt -s nullglob
files=("$SRC"/rand_*.S)
if [ ${#files[@]} -eq 0 ]; then
  echo "!! no rand_*.S in $SRC -- run the generator (gen_randoms.do) first"; exit 1
fi

built=0; fail=0
for f in "${files[@]}"; do
  name="$(basename "$f" .S)"
  if ! "$GCC" -march=$MARCH -mabi=$MABI -nostdlib -nostartfiles -T "$LINK" \
        "$f" -o "$OUT/$name.elf" 2> "$OUT/$name.gcc.log"; then
    echo "FAIL(gcc)  $name  (see build/$name.gcc.log)"; fail=$((fail+1)); continue
  fi
  "$OBJCOPY" -O binary "$OUT/$name.elf" "$OUT/$name.bin"
  python3 "$BIN2HEX" "$OUT/$name.bin" "$OUT/$name.hex"       # depth defaults to 1024 (16 KB)
  "$OBJDUMP" -d "$OUT/$name.elf" > "$OUT/$name.dump"
  # golden commit log, truncated at the store to tohost (0x8000_3FF0)
  "$SPIKE" --isa=$ISA -l --log-commits "$OUT/$name.elf" 2>&1 \
      | sed '/mem 0x80003ff0/q' > "$OUT/$name.spike.log"
  echo "BUILT  $name"; built=$((built+1))
done

echo "-----------------------------------------------------"
echo "built=$built  gcc-fail=$fail   -> $OUT"
