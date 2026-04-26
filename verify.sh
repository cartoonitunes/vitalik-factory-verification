#!/bin/bash
# verify.sh — compile factory.se with Serpent 2.0.7 and compare to on-chain runtime
# Compiler: ethereum/serpent tag 2.0.7 (Docker image serpent-compiler)
# Note: Serpent 2.0.7 appends 4 trailing dead bytes (5b6000f3) to every output.
#       These were stripped before deployment. The compiled runtime minus 4 bytes = on-chain bytecode.

set -e

ADDRESS="0x42dd263af905666eff278d9c9602478407351457"
IMAGE="serpent-compiler"
ONCHAIN="onchain-runtime.hex"

echo "Compiling factory.se + moose.se with Serpent 2.0.7..."
COMPILED=$(docker run --rm \
  -v "$(pwd):/work" \
  "$IMAGE" \
  bash -c "cd /work && PYTHONPATH=/serpent/build/lib.linux-aarch64-2.7 python2 -c \"
import serpent, os
os.chdir('/work')
result = serpent.compile(open('/work/factory.se').read())
runtime = result[14:]
# Strip 4 trailing dead bytes (5b6000f3 = JUMPDEST PUSH1 0 RETURN) added by Serpent 2.0.7
deployed = runtime[:-4]
print deployed.encode('hex'),
\"" 2>/dev/null)

echo "Compiled (stripped): $((${#COMPILED}/2)) bytes"

ONCHAIN_HEX=$(cat "$ONCHAIN")

if [ "$COMPILED" = "$ONCHAIN_HEX" ]; then
    echo "✅ EXACT MATCH — bytecode is identical ($((${#ONCHAIN_HEX}/2)) bytes)"
else
    echo "❌ MISMATCH"
    python3 -c "
a='$ONCHAIN_HEX'; b='$COMPILED'
print(f'On-chain: {len(a)//2} bytes, Compiled: {len(b)//2} bytes')
for i in range(min(len(a),len(b))//2):
    if a[i*2:i*2+2] != b[i*2:i*2+2]:
        print(f'First diff at byte {i} (0x{i:04x}): onchain=0x{a[i*2:i*2+2]} compiled=0x{b[i*2:i*2+2]}')
        break
"
fi
