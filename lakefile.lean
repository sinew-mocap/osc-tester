import Lake
open Lake DSL System

package «osc-tester» where
  -- release-ish build flags
  leanOptions := #[⟨`autoImplicit, false⟩]

lean_lib Osc where

/-- Compile the C FFI to an object file. -/
target osc_ffi.o pkg : FilePath := do
  let oFile := pkg.buildDir / "ffi" / "osc_ffi.o"
  let srcJob ← inputTextFile <| pkg.dir / "ffi" / "osc_ffi.c"
  let weakArgs := #["-I", (← getLeanIncludeDir).toString]
  buildO oFile srcJob weakArgs #["-fPIC"] "cc" getLeanTrace

/-- Bundle the FFI object as a static lib linked into the executable. -/
extern_lib libosc_ffi pkg := do
  let name := nameToStaticLib "osc_ffi"
  let ffiO ← osc_ffi.o.fetch
  buildStaticLib (pkg.buildDir / "lib" / name) #[ffiO]

@[default_target]
lean_exe osctest where
  root := `Main
