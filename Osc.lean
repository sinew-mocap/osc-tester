/-! Minimal OSC 1.0 message encoder + the C FFI primitives. -/
namespace Osc

@[extern "lean_osc_float32_bits"]
opaque float32Bits (d : Float) : UInt32

@[extern "lean_osc_parse_float"]
opaque parseFloat (s : @& String) : Float

@[extern "lean_osc_udp_send"]
opaque udpSend (host : @& String) (port : UInt32) (data : @& ByteArray) : IO Unit

/-- Pad a byte array with zeros up to a multiple of 4 (OSC alignment). -/
private def pad4 (b : ByteArray) : ByteArray :=
  let r := b.size % 4
  if r == 0 then b else b ++ ByteArray.mk (Array.replicate (4 - r) (0 : UInt8))

/-- An OSC-string: UTF-8 bytes, a null terminator, padded to 4 bytes. -/
def oscString (s : String) : ByteArray :=
  pad4 (s.toUTF8.push 0)

/-- Big-endian 4-byte encoding of a UInt32 (OSC is big-endian). -/
def be32 (n : UInt32) : ByteArray :=
  ByteArray.mk #[(n >>> 24).toUInt8, (n >>> 16).toUInt8, (n >>> 8).toUInt8, n.toUInt8]

/-- An OSC argument: int32, float32, or string. -/
inductive Arg where
  | int   (bits : UInt32)
  | float (x : Float)
  | str   (s : String)

def Arg.tag : Arg → Char
  | .int _   => 'i'
  | .float _ => 'f'
  | .str _   => 's'

def Arg.bytes : Arg → ByteArray
  | .int b   => be32 b
  | .float x => be32 (float32Bits x)
  | .str s   => oscString s

/-- Encode a complete OSC message: address, type-tag string, then the arguments. -/
def message (addr : String) (args : List Arg) : ByteArray :=
  let tags := "," ++ String.ofList (args.map Arg.tag)
  let header := oscString addr ++ oscString tags
  args.foldl (fun acc a => acc ++ a.bytes) header

/-- Hex dump (space-separated bytes) for inspection. -/
def hex (b : ByteArray) : String :=
  let digits := "0123456789abcdef".toList
  let nib := fun (k : UInt8) => digits.getD k.toNat '?'
  String.intercalate " " (b.toList.map (fun x =>
    s!"{nib (x >>> (4 : UInt8))}{nib (x &&& (0x0f : UInt8))}"))

end Osc
