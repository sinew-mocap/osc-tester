import Osc

/-- A token is a float if it isn't an int but looks numeric with a '.'/'e'. -/
private def looksFloat (s : String) : Bool :=
  s.any (·.isDigit) && s.any (fun c => c == '.' || c == 'e' || c == 'E')

/-- Map a CLI token to an OSC argument: int32 if integral, else float32 if it
    looks numeric, else a string. -/
private def parseArg (s : String) : Osc.Arg :=
  match s.toInt? with
  | some n =>
      -- two's-complement low 32 bits
      let m := ((n % 4294967296) + 4294967296) % 4294967296
      Osc.Arg.int (UInt32.ofNat m.toNat)
  | none =>
      if looksFloat s then Osc.Arg.float (Osc.parseFloat s) else Osc.Arg.str s

private partial def parseFlags
    (args : List String) (host : String) (port : Nat) : String × Nat × List String :=
  match args with
  | "--host" :: h :: rest => parseFlags rest h port
  | "--port" :: p :: rest => parseFlags rest host (p.toNat?.getD port)
  | rest => (host, port, rest)

def usage : String :=
  "usage: osctest [--host H] [--port P] <address> [arg...]\n" ++
  "  args: 42 -> int32, 1.5 -> float32, anything else -> string\n" ++
  "  default target 127.0.0.1:39539 (the /sinew OSC port)"

def main (argv : List String) : IO Unit := do
  let (host, port, rest) := parseFlags argv "127.0.0.1" 39539
  match rest with
  | [] => IO.eprintln usage
  | addr :: raw =>
      let args := raw.map parseArg
      let msg := Osc.message addr args
      IO.println s!"{addr}  ({args.length} args, {msg.size} B)  ->  {host}:{port}"
      IO.println (Osc.hex msg)
      Osc.udpSend host (UInt32.ofNat port) msg
      IO.println "sent ✓"
