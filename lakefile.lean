import Lake
open Lake DSL System

package «osc-tester» where
  leanOptions := #[⟨`autoImplicit, false⟩]

require plausible from git
  "https://github.com/leanprover-community/plausible" @ "v4.30.0"

lean_lib Osc where

/-- Compile the C FFI to an object file (with Lean's own `leanc`, so it works on
    Linux/macOS/Windows). -/
target osc_ffi.o pkg : FilePath := do
  let oFile := pkg.buildDir / "ffi" / "osc_ffi.o"
  let srcJob ← inputTextFile <| pkg.dir / "ffi" / "osc_ffi.c"
  let weakArgs := #["-I", (← getLeanIncludeDir).toString]
  let pic := if Platform.isWindows then #[] else #["-fPIC"]
  -- `leanc`'s bundled clang has no system-header search path, so use a real
  -- compiler: `cc` on Linux/macOS, the runner's `clang` (Windows SDK headers,
  -- incl. winsock2.h) on Windows.
  let compiler := if Platform.isWindows then "clang" else "cc"
  buildO oFile srcJob weakArgs pic compiler getLeanTrace

extern_lib libosc_ffi pkg := do
  let name := nameToStaticLib "osc_ffi"
  let ffiO ← osc_ffi.o.fetch
  buildStaticLib (pkg.buildDir / "lib" / name) #[ffiO]

/-- Winsock is needed on Windows for the UDP send in the FFI. -/
def winLink : Array String := if Platform.isWindows then #["-lws2_32"] else #[]

@[default_target]
lean_exe osctest where
  root := `Main
  moreLinkArgs := winLink

@[test_driver]
lean_exe test where
  root := `Test
  moreLinkArgs := winLink
