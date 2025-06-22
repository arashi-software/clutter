import strformat, therapist

const versionNum* = staticRead(fmt"../../clutter.nimble").splitLines()[0].split("=")[1]
  .strip()
  .replace("\"", "")

const release = defined(release)

var bType: string

if release:
  bType = "release"
else:
  bType = "debug"

let pals = toSeq parsePalettes().keys

let add = (
  help: newHelpArg(),
  name: newStringArg(@["<name>"], help = "The name of the palette"),
  colors: newStringArg(
    @["<colors>"],
    multi = true,
    help = "The colors in the palette (space-seperated list of hex codes)",
  ),
)

let palettescmd = (
  help: newHelpArg(),
  list:
    newMessageCommandArg(@["list", "ls"], pals.join("\n"), help = "List all palettes"),
  add: newCommandArg(@["add"], add, help = "Create a palette"),
)

let args* = (
  palettes: newCommandArg(@["palettes", "p"], palettescmd, help = "Palete Management"),
  output: newStringArg(
    @["--output", "-o"], help = "The file to write to", optional = true, defaultVal = ""
  ),
  input: newPathArg(@["--input", "-i"], help = "The file to convert", defaultVal = ""),
  strength:
    newFloatArg(@["--strength", "-s"], help = "The LUT strength", defaultVal = 0.375),
  interp: newIntArg(
    @["--interpolate", "-I"], help = "How many colors to generate", defaultVal = 32
  ),
  palette: newStringArg(
    @["<palette>"], help = "The palette to use", multi = true, optional = true
  ),
  version: newMessageArg(
    @["--version", "-v"],
    "clutter v$#\nrelease: $#" % @[versionNum, $release],
    help = "Show version information",
  ),
  help: newHelpArg(),
)

args.parseOrQuit(
  prolog = "cluter - fast as fuck interpolated LUT generator and applier",
  command = "clutter",
)

export therapist
