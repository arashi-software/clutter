import kdl, kdl/decoder
import tables, os, strutils

const ExamplePalettes* = staticRead("../../examples/palettes.kdl")

type PaletteFile* = Table[string, seq[string]]

let paletteFilePath* = getConfigDir() / "clutter" / "palettes.kdl"

proc installPalettes*() {.inline.} =
  if not fileExists(paletteFilePath):
    echo "Initialized Palettes at " & paletteFilePath
    createDir(getConfigDir() / "clutter")
    writeFile(paletteFilePath, ExamplePalettes)

proc parsePalettes*(): PaletteFile {.inline.} =
  let palettes = parseKdl paletteFilePath.readFile()
  return palettes.decodeKdl(PaletteFile)

proc addPalette*(name: string, colors: seq[string]) =
  if not (name in parsePalettes()):
    var res = name
    for color in colors:
      res &= " \"" & color & "\""
    writeFile(paletteFilePath, paletteFilePath.readFile() & "\n" & res)
  else:
    echo "Palette $# already exists" % [name]
