# vcbprintf

Clean-room implementation of Amiga's `RawDoFmt` and `RawPutChar` functions.

## Files

- `vcbprintf.s` - Clean-room implementation
- `rawdofmt.s` - Wrapper calling Kickstart ROM (for baseline comparison)
- `kprintf.i` - Printf-style macro
- `test_main.s` - Test suite

## Usage

```bash
./bootstrap_fsuae.sh  # Build FS-UAE (first time only)
make                  # Build test executables
./run_test.sh         # Compare against ROM baseline
```

Requires a Kickstart ROM.

## Third-Party Tools

The `tb/` directory contains tools from Aminet used for testing:

- **SetPatch** - [SetPatch 43.6b](https://aminet.net/package/util/boot/SetPatch_43.6b)
- **MuForce, MuGuardianAngel, mmu.library** - [MMULib](https://aminet.net/package/util/libs/MMULib)
- **disassembler.library** - [DisLib](https://aminet.net/package/util/libs/DisLib)

## License

MIT
