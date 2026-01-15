#!/bin/bash
#
# Test script - runs both printf implementations and compares output
#

set -e

# Check required tools
for tool in socat timeout; do
    command -v "$tool" >/dev/null || { echo "Error: $tool not found"; exit 1; }
done

[[ -x ./fs-uae/fs-uae ]] || { echo "Error: fs-uae not built. Run ./bootstrap_fsuae.sh first"; exit 1; }

BASELINE_LOG="baseline_output.txt"
NEW_LOG="new_output.txt"
SERIAL_SOCK="/tmp/printf-test-serial.sock"

run_test() {
    local test_name="$1"
    local output_log="$2"

    echo "Running $test_name..."
    echo "=================================="
    rm -f "$output_log" "$SERIAL_SOCK"

    # Create startup-sequence
    mkdir -p tb/S
    cat > tb/S/startup-sequence <<EOF
SetPatch >NIL:
Run >NIL: <NIL: MuForce FATALHITS SHOWPC STACKCHECK AREGCHECK DREGCHECK DISPC DATESTAMP DEADLY VERBOSE CAPTURESUPER NEWVBR
Run >NIL: <NIL: MuGuardianAngel SHOWFAIL SHOWHUNK DATESTAMP STACKCHECK DUMPWALL WAITFORMUFORCE SHOWSTACK DREGCHECK AREGCHECK SHOWPC NAMETAG CONSISTENCY DISPC
Wait 10
PRINTF:$test_name
endcli
EOF

    # Start socat to capture serial output
    socat -u pty,raw,echo=0,link=$SERIAL_SOCK - > "$output_log" &
    local socat_pid=$!
    sleep 1

    # Run FS-UAE
    timeout -f 30 ./fs-uae/fs-uae --stdout \
        --automatic_input_grab=0 \
        --floppy_drive_speed=0 \
        test.fs-uae > "/tmp/printf-test-${test_name}.log" 2>&1 || true

    # Kill socat
    kill -9 $socat_pid 2>/dev/null || true
    rm -f "$SERIAL_SOCK"

    echo "Output:"
    cat "$output_log"
    echo ""
}

# Build both versions
echo "Building test programs..."
make clean
make

echo ""
run_test "test_baseline" "$BASELINE_LOG"
run_test "test_new" "$NEW_LOG"

# Compare outputs
echo "Comparing outputs..."
echo "=================================="
if diff -u "$BASELINE_LOG" "$NEW_LOG" > diff.txt; then
    echo "SUCCESS: Outputs match!"
    rm -f diff.txt
else
    echo "FAILURE: Outputs differ!"
    echo ""
    cat diff.txt
    exit 1
fi
