type LabColor = array[3, float]

proc applyGammaCorrection(val: float): float =
  if val > 0.04045:
    pow((val + 0.055) / 1.055, 2.4)
  else:
    val / 12.92

proc applyInverseGamma(val: float): float =
  if val > 0.0031308:
    1.055 * pow(val, 1.0 / 2.4) - 0.055
  else:
    12.92 * val

proc xyzToLabHelper(t: float): float =
  if t > 0.008856:
    pow(t, 1.0 / 3.0)
  else:
    (7.787 * t + 16.0 / 116.0)

proc labToXyzHelper(t: float): float =
  if t > 0.206893:
    pow(t, 3.0)
  else:
    (t - 16.0 / 116.0) / 7.787

proc rgbToLab(rgb: array[3, float]): LabColor =
  let r = applyGammaCorrection(rgb[0])
  let g = applyGammaCorrection(rgb[1])
  let b = applyGammaCorrection(rgb[2])

  let x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375
  let y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750
  let z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041

  let xn = x / 0.95047
  let yn = y / 1.00000
  let zn = z / 1.08883

  let fx = xyzToLabHelper(xn)
  let fy = xyzToLabHelper(yn)
  let fz = xyzToLabHelper(zn)

  let L = 116.0 * fy - 16.0
  let a = 500.0 * (fx - fy)
  let b_lab = 200.0 * (fy - fz)

  [L / 100.0, (a + 128.0) / 255.0, (b_lab + 128.0) / 255.0]

proc labToRgb(lab: LabColor): array[3, float] =
  let L = lab[0] * 100.0
  let a = lab[1] * 255.0 - 128.0
  let b_lab = lab[2] * 255.0 - 128.0

  let fy = (L + 16.0) / 116.0
  let fx = a / 500.0 + fy
  let fz = fy - b_lab / 200.0

  let x = labToXyzHelper(fx) * 0.95047
  let y = labToXyzHelper(fy) * 1.00000
  let z = labToXyzHelper(fz) * 1.08883

  let r = x * 3.2404542 + y * -1.5371385 + z * -0.4985314
  let g = x * -0.9692660 + y * 1.8760108 + z * 0.0415560
  let b = x * 0.0556434 + y * -0.2040259 + z * 1.0572252

  [
    clamp(applyInverseGamma(r), 0.0, 1.0),
    clamp(applyInverseGamma(g), 0.0, 1.0),
    clamp(applyInverseGamma(b), 0.0, 1.0),
  ]

proc calculateLabDistance(color1, color2: LabColor): float =
  sqrt(
    pow(color1[0] - color2[0], 2) + pow(color1[1] - color2[1], 2) +
      pow(color1[2] - color2[2], 2)
  )

proc isColorSufficientlyDifferent(
    newColor: LabColor, existingColors: seq[LabColor], minDistance: float = 0.05
): bool =
  for existing in existingColors:
    if calculateLabDistance(newColor, existing) < minDistance:
      return false
  true

proc interpolateLabColors(color1, color2: LabColor, t: float): LabColor =
  [
    color1[0] * (1.0 - t) + color2[0] * t,
    color1[1] * (1.0 - t) + color2[1] * t,
    color1[2] * (1.0 - t) + color2[2] * t,
  ]

proc generateLabVariation(
    baseColor: LabColor, variationType: int, intensity: float = 0.1
): LabColor =
  result = baseColor

  case variationType mod 8
  of 0:
    result[0] = clamp(baseColor[0] + intensity, 0.0, 1.0)
  of 1:
    result[0] = clamp(baseColor[0] - intensity, 0.0, 1.0)
  of 2:
    result[1] = clamp(baseColor[1] + intensity, 0.0, 1.0)
  of 3:
    result[1] = clamp(baseColor[1] - intensity, 0.0, 1.0)
  of 4:
    result[2] = clamp(baseColor[2] + intensity, 0.0, 1.0)
  of 5:
    result[2] = clamp(baseColor[2] - intensity, 0.0, 1.0)
  of 6:
    result[0] = clamp(baseColor[0] + intensity * 0.5, 0.0, 1.0)
    result[1] = clamp(baseColor[1] + intensity * 0.3, 0.0, 1.0)
  of 7:
    result[0] = clamp(baseColor[0] - intensity * 0.5, 0.0, 1.0)
    result[2] = clamp(baseColor[2] - intensity * 0.3, 0.0, 1.0)
  else:
    discard

proc findBestCandidateColor(existingColors: seq[LabColor]): LabColor =
  var maxDistance = 0.0
  var bestCandidate = existingColors[0]

  for l in 0 .. 9:
    for a in 0 .. 9:
      for b in 0 .. 9:
        let candidate: LabColor = [l.float / 9.0, a.float / 9.0, b.float / 9.0]

        var minDist = 2.0
        for existing in existingColors:
          let dist = calculateLabDistance(candidate, existing)
          minDist = min(minDist, dist)

        if minDist > maxDistance:
          maxDistance = minDist
          bestCandidate = candidate

  bestCandidate

proc addInterpolatedColors(
    labPalette: seq[LabColor], expandedLab: var seq[LabColor], targetCount: int
) =
  if labPalette.len < 2:
    return

  var sortedIndices = toSeq(0 ..< labPalette.len)
  sortedIndices.sort(
    proc(a, b: int): int =
      if labPalette[a][0] < labPalette[b][0]:
        -1
      elif labPalette[a][0] > labPalette[b][0]:
        1
      else:
        0
  )

  let interpolationsNeeded = min(targetCount - labPalette.len, (labPalette.len - 1) * 3)
  let stepsPerPair = max(1, interpolationsNeeded div (labPalette.len - 1))

  for i in 0 ..< (sortedIndices.len - 1):
    let idx1 = sortedIndices[i]
    let idx2 = sortedIndices[i + 1]
    let color1 = labPalette[idx1]
    let color2 = labPalette[idx2]

    for j in 1 .. stepsPerPair:
      if expandedLab.len >= targetCount:
        break
      let t = j.float / (stepsPerPair + 1).float
      let interpolated = interpolateLabColors(color1, color2, t)
      expandedLab.add(interpolated)

proc addVariationColors(
    labPalette: seq[LabColor], expandedLab: var seq[LabColor], targetCount: int
) =
  var variationIndex = 0

  while expandedLab.len < targetCount and variationIndex < labPalette.len * 8:
    let baseIdx = variationIndex mod labPalette.len
    let baseColor = labPalette[baseIdx]
    let variationType = variationIndex div labPalette.len

    let newColor = generateLabVariation(baseColor, variationType)

    if isColorSufficientlyDifferent(newColor, expandedLab):
      expandedLab.add(newColor)

    variationIndex += 1

proc addUniformSampledColors(expandedLab: var seq[LabColor], targetCount: int) =
  while expandedLab.len < targetCount:
    let bestNewColor = findBestCandidateColor(expandedLab)

    if calculateLabDistance(bestNewColor, expandedLab[0]) > 0.01:
      expandedLab.add(bestNewColor)
    else:
      let baseIdx = expandedLab.len mod (expandedLab.len div 2 + 1)
      let baseColor = expandedLab[baseIdx]
      let variation: LabColor = [
        clamp(baseColor[0] + (expandedLab.len.float * 0.01) mod 0.2 - 0.1, 0.0, 1.0),
        clamp(baseColor[1] + (expandedLab.len.float * 0.007) mod 0.14 - 0.07, 0.0, 1.0),
        clamp(baseColor[2] + (expandedLab.len.float * 0.013) mod 0.26 - 0.13, 0.0, 1.0),
      ]
      expandedLab.add(variation)

proc convertLabPaletteToHex(labColors: seq[LabColor]): seq[string] =
  result = @[]
  for labColor in labColors:
    let rgb = labToRgb(labColor)
    let color = rgbToColor(rgb)
    result.add(colorToHex(color))

proc expandPalette(originalColors: seq[string], targetCount: int = 256): seq[string] =
  if originalColors.len == 0:
    raise newException(ValueError, "Original palette is empty")

  if originalColors.len >= targetCount:
    return originalColors[0 ..< targetCount]

  let originalPalette = originalColors.map(hexToColor)

  var labPalette: seq[LabColor] = @[]
  for color in originalPalette:
    let rgb = colorToRGB(color)
    labPalette.add(rgbToLab(rgb))

  var expandedLab = labPalette

  addInterpolatedColors(labPalette, expandedLab, targetCount)
  addVariationColors(labPalette, expandedLab, targetCount)
  addUniformSampledColors(expandedLab, targetCount)

  result = convertLabPaletteToHex(expandedLab[0 ..< targetCount])
  echo "Expanded palette from ",
    originalColors.len, " to ", result.len, " colors using LAB color space"
