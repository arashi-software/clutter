import sequtils, math, algorithm, os
include lib/vips

type
  Color = object
    r, g, b: uint8

proc hexToColor(hex: string): Color =
  let cleaned = hex.strip().replace("#", "")
  if cleaned.len != 6:
    raise newException(ValueError, "Invalid hex color: " & hex)
  
  result.r = fromHex[uint8](cleaned[0..1])
  result.g = fromHex[uint8](cleaned[2..3]) 
  result.b = fromHex[uint8](cleaned[4..5])

proc colorToRGB(c: Color): array[3, float] =
  [c.r.float / 255.0, c.g.float / 255.0, c.b.float / 255.0]

proc rgbToColor(rgb: array[3, float]): Color =
  Color(
    r: clamp(rgb[0] * 255.0, 0.0, 255.0).uint8,
    g: clamp(rgb[1] * 255.0, 0.0, 255.0).uint8,
    b: clamp(rgb[2] * 255.0, 0.0, 255.0).uint8
  )

proc colorToHex(color: Color): string =
  # Direct conversion from uint8 values to hex
  result = "#" & color.r.toHex(2) & color.g.toHex(2) & color.b.toHex(2)

proc rgbToHsv(rgb: array[3, float]): array[3, float] =
  let r = rgb[0]
  let g = rgb[1] 
  let b = rgb[2]
  
  let maxVal = max(max(r, g), b)
  let minVal = min(min(r, g), b)
  let delta = maxVal - minVal
  
  var h, s, v: float
  
  v = maxVal
  
  if maxVal == 0.0:
    s = 0.0
  else:
    s = delta / maxVal
  
  if delta == 0.0:
    h = 0.0
  elif maxVal == r:
    h = (60.0 * ((g - b) / delta) + 360.0) mod 360.0
  elif maxVal == g:
    h = (60.0 * ((b - r) / delta) + 120.0) mod 360.0
  else:
    h = (60.0 * ((r - g) / delta) + 240.0) mod 360.0
  
  result = [h / 360.0, s, v]

proc getLuminance(rgb: array[3, float]): float =
  0.299 * rgb[0] + 0.587 * rgb[1] + 0.114 * rgb[2]

proc findBestPaletteMatch(inputRgb: array[3, float], palette: seq[Color]): array[3, float] =
  let inputHsv = rgbToHsv(inputRgb)
  let inputLuminance = getLuminance(inputRgb)
  
  var bestMatch = colorToRGB(palette[0])
  var bestScore = 1000.0
  
  for paletteColor in palette:
    let paletteRgb = colorToRGB(paletteColor)
    let paletteHsv = rgbToHsv(paletteRgb)
    let paletteLuminance = getLuminance(paletteRgb)
    
    let lumDiff = abs(inputLuminance - paletteLuminance)
    let hueDiff = min(abs(inputHsv[0] - paletteHsv[0]), 1.0 - abs(inputHsv[0] - paletteHsv[0]))
    let satDiff = abs(inputHsv[1] - paletteHsv[1]) * 0.3  # Less weight on saturation
    
    let score = lumDiff * 2.0 + hueDiff * 1.5 + satDiff
    
    if score < bestScore:
      bestScore = score
      bestMatch = paletteRgb
  
  result = bestMatch

proc smoothstep(edge0, edge1, x: float): float =
  let t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
  t * t * (3.0 - 2.0 * t)

proc generatePaletteLUT(targetColors: seq[string], strength: float = 0.8): ptr VipsImage =
  let lutSize = 256
  var lutData = newSeq[uint8](lutSize * 3)
  let palette = targetColors.map(hexToColor)
  
  if palette.len < 2:
    raise newException(ValueError, "Need at least 2 colors in palette")
  
  var sortedPalette = palette
  sortedPalette.sort(proc(a, b: Color): int =
    let lumA = getLuminance(colorToRGB(a))
    let lumB = getLuminance(colorToRGB(b))
    if lumA < lumB: -1 elif lumA > lumB: 1 else: 0
  )
  
  for i in 0..<lutSize:
    let intensity = i.float / 255.0
    let originalColor = [intensity, intensity, intensity]
    
    let paletteMatch = findBestPaletteMatch(originalColor, sortedPalette)
    
    var finalRgb: array[3, float]
    for channel in 0..2:
      let blendFactor = strength * smoothstep(0.1, 0.9, intensity)  # Stronger in midtones
      finalRgb[channel] = originalColor[channel] * (1.0 - blendFactor) + 
                         paletteMatch[channel] * blendFactor
      finalRgb[channel] = clamp(finalRgb[channel], 0.0, 1.0)
    
    let idx = i * 3
    lutData[idx] = (finalRgb[0] * 255.0).uint8
    lutData[idx + 1] = (finalRgb[1] * 255.0).uint8
    lutData[idx + 2] = (finalRgb[2] * 255.0).uint8
  
  result = vips_image_new_from_memory_copy(
    lutData[0].unsafeAddr,
    lutData.len.csize_t,
    lutSize.cint,
    1.cint,
    3.cint,
    VIPS_FORMAT_UCHAR.cint
  )
  
  if result == nil:
    raise newException(VipsError, "Failed to create palette LUT image")

proc applyPaletteLUT(image: ptr VipsImage, lut: ptr VipsImage, 
                    preserveDetails: bool = true, detailStrength: float = 0.3): ptr VipsImage =
  var lutResult: ptr VipsImage
  let status = vips_maplut(image, lutResult.addr, lut, nil)
  checkVipsResult(status, "maplut with palette LUT")
  
  if not preserveDetails:
    return lutResult
    
  var detailMask: ptr VipsImage
  let blurStatus = vips_resize(image, detailMask.addr, 0.5, nil)  # Simple detail detection
  checkVipsResult(blurStatus, "resize for detail detection")
  
  let a = [1.0 - detailStrength, 1.0 - detailStrength, 1.0 - detailStrength]
  let b = [detailStrength, detailStrength, detailStrength]
  
  var preservedResult: ptr VipsImage
  let linearStatus = vips_linear(lutResult, preservedResult.addr, 
                                a[0].unsafeAddr, b[0].unsafeAddr, 3, nil)
  checkVipsResult(linearStatus, "linear blend for detail preservation")
  
  g_object_unref(detailMask)
  g_object_unref(lutResult)
  
  result = preservedResult

proc processImageWithPaletteGrading(inputPath: string, outputPath: string, 
                                   targetColors: seq[string], 
                                   strength: float = 0.7, 
                                   preserveDetails: bool = true,
                                   saveHaldReference: bool = true) =
  checkVipsResult(vips_init("clutter"), "vips_init")
  
  try:
    let inputImage = vips_image_new_from_file(inputPath.cstring, nil)
    if inputImage == nil:
      raise newException(VipsError, "Failed to load image: " & inputPath)

    echo "Using palette: ", targetColors.join(", ")
    
    let lut = generatePaletteLUT(targetColors, strength)
    
    let outputImage = applyPaletteLUT(inputImage, lut, preserveDetails, 0.2)
    
    checkVipsResult(
      vips_image_write_to_file(outputImage, outputPath.cstring, nil),
      "write_to_file"
    )
    
    echo "Successfully processed with palette grading: ", inputPath, " -> ", outputPath
    
    g_object_unref(inputImage)
    g_object_unref(lut)
    g_object_unref(outputImage)
    
  except Exception as e:
    echo "Error: ", e.msg
    quit 1

include lib/interpolation

proc clutter(input: string, output: string, strength = 0.25, interpolation = 64, palette: seq[string]) =
  try:
    echo "Processing with palette strength: ", strength
    processImageWithPaletteGrading(input, output, 
                                  palette.expandPalette(interpolation), strength=strength, 
                                  preserveDetails=true)       
  except VipsError as e:
    echo "VipsError: ", e.msg
  except Exception as e:
    echo "Error: ", e.msg

when isMainModule:
  putEnv("VIPS_WARNING", "0")
  putEnv("G_MESSAGES_DEBUG", "")
  import cligen; clCfg.longPfxOk = false
  from std/tables import toTable 
  const
    Help  = { "input": "the input file (the file to recolor)",
              "output": "the output file (where to save the recolor)",
              "strength": "the recolor strength (best to leave at default but expirement if you wish)",
              "interpolation": "how large to make the color palette (expirement if you wish)",
              "palette": "the color palette (a space seperated list of hex codes)",
              "help": "print this message" }.toTable()
    Short = { "input": 'i', "output": 'o', "strength": 's', "interpolation": 'I' }.toTable()
  dispatch(clutter, help = Help, short = Short)
