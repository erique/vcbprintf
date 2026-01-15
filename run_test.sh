#!/bin/bash
#
# Test script - runs both printf implementations and compares output
#

set -e

# Check required tools
command -v socat >/dev/null || { echo "Error: socat not found"; exit 1; }

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
Wait 1
PRINTF:$test_name
endcli
EOF

    # Start socat to capture serial output
    socat -u pty,raw,echo=0,link=$SERIAL_SOCK - > "$output_log" &
    local socat_pid=$!
    sleep 1

    # Run FS-UAE in background
    ./fs-uae/fs-uae --stdout \
        --automatic_input_grab=0 \
        --floppy_drive_speed=0 \
        test.fs-uae > "/tmp/printf-test-${test_name}.log" 2>&1 &
    local fsuae_pid=$!

    # Wait for completion marker, enforcer hit, or timeout
    local max_wait=15
    local hit_detected=0
    for ((i=0; i<max_wait; i++)); do
        if grep -q '$$$ SHUTDOWN' "$output_log" 2>/dev/null; then
            sleep 1  # Let output flush
            break
        fi
        if grep -qE '(LONG|WORD|BYTE) (READ|WRITE) |Exception !!' "$output_log" 2>/dev/null; then
            sleep 2  # Let MuForce output full details
            hit_detected=1
            break
        fi
        sleep 1
    done

    if [[ $hit_detected -eq 1 ]]; then
        echo "ENFORCER HIT DETECTED:"
        cat "$output_log"
        kill $fsuae_pid 2>/dev/null || true
        kill $socat_pid 2>/dev/null || true
        rm -f "$SERIAL_SOCK"
        exit 1
    fi

    # Cleanup
    kill $fsuae_pid 2>/dev/null || true
    kill $socat_pid 2>/dev/null || true
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
