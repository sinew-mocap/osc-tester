import Plausible
import Osc

/-! Property-based tests for the OSC encoder, using Plausible. -/

-- Every OSC-string is padded to a 4-byte boundary (OSC alignment).
example : ∀ s : String, (Osc.oscString s).size % 4 = 0 := by plausible

-- An OSC-string always has room for the bytes plus a null terminator.
example : ∀ s : String, s.toUTF8.size < (Osc.oscString s).size := by plausible

-- A whole message stays 4-byte aligned regardless of the string args it carries.
example : ∀ (addr str : String),
    (Osc.message addr [Osc.Arg.str str]).size % 4 = 0 := by plausible

def main : IO Unit :=
  IO.println "osc-tester: property tests passed"
