# osc-tester — a minimal Lean OSC sender

A tiny [Lean 4](https://lean-lang.org) tool that encodes an [OSC 1.0](https://opensoundcontrol.stanford.edu/spec-1_0.html)
message and fires it as a UDP datagram — handy for poking the `/sinew` OSC stream
(the viewer listens on `39539`).

```
osctest [--host H] [--port P] <address> [arg...]
```

- `42` → int32, `1.5` → float32, anything else → string.
- Default target `127.0.0.1:39539` (the `/sinew` OSC port).

```console
$ osctest /sinew/test 1.0 42 hello
/sinew/test  (3 args, 36 B)  ->  127.0.0.1:39539
2f 73 69 6e 65 77 2f 74 65 73 74 00 2c 66 69 73 00 00 00 00 3f 80 00 00 00 00 00 2a 68 65 6c 6c 6f 00 00 00
sent ✓
```

## Build

```
lake build          # -> .lake/build/bin/osctest
```

Lean has no sockets and only `Float64`, so a ~40-line C FFI (`ffi/osc_ffi.c`)
provides three primitives — float32 bit-pattern, `strtod`, and UDP `sendto`; the
OSC wire encoding itself is pure Lean (`Osc.lean`). The executable is
self-contained (no Lean shared-library runtime dependency).
