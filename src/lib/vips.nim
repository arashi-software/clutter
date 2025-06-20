# UHH- These are some pretty sketchy nim bindings to the libvips library that I wrote and kind of edited to work
# USE AT YOUR OWN RISK; even though they work with what I want them to do, I cannot guarantee they will work for you.

import strutils

type
  gint* = cint
  guint* = cuint
  gsize* = csize_t
  gpointer* = pointer
  gconstpointer* = pointer
  gboolean* = cint
  gdouble* = cdouble
  gchar* = cchar
  
type
  GObject* = object of RootObj
  GObjectClass* = object of RootObj
  
  GType* = csize_t

type
  VipsObject* = object of GObject
  VipsObjectClass* = object of GObjectClass
  
  VipsImage* {.importc: "VipsImage", header: "vips/vips.h".} = object of VipsObject

type
  VipsFormat* = cint
  Format* {.importc: "VipsFormat", header: "vips/vips.h", size: sizeof(cint).} = enum
    VIPS_FORMAT_NOTSET = -1.cint
    VIPS_FORMAT_UCHAR = 0.cint
    VIPS_FORMAT_CHAR = 1.cint
    VIPS_FORMAT_USHORT = 2.cint
    VIPS_FORMAT_SHORT = 3.cint
    VIPS_FORMAT_UINT = 4.cint
    VIPS_FORMAT_INT = 5.cint
    VIPS_FORMAT_FLOAT = 6.cint
    VIPS_FORMAT_COMPLEX = 7.cint
    VIPS_FORMAT_DOUBLE = 8.cint
    VIPS_FORMAT_DPCOMPLEX = 9.cint

type
  VipsInterpretation* {.importc: "VipsInterpretation", header: "vips/vips.h", size: sizeof(cint).} = enum
    VIPS_INTERPRETATION_ERROR = -1
    VIPS_INTERPRETATION_MULTIBAND = 0
    VIPS_INTERPRETATION_B_W = 1
    VIPS_INTERPRETATION_HISTOGRAM = 10
    VIPS_INTERPRETATION_XYZ = 12
    VIPS_INTERPRETATION_LAB = 13
    VIPS_INTERPRETATION_CMYK = 15
    VIPS_INTERPRETATION_LABQ = 16
    VIPS_INTERPRETATION_RGB = 17
    VIPS_INTERPRETATION_CMC = 18
    VIPS_INTERPRETATION_LCH = 19
    VIPS_INTERPRETATION_LABS = 21
    VIPS_INTERPRETATION_sRGB = 22
    VIPS_INTERPRETATION_YXY = 23
    VIPS_INTERPRETATION_FOURIER = 24
    VIPS_INTERPRETATION_RGB16 = 25
    VIPS_INTERPRETATION_GREY16 = 26
    VIPS_INTERPRETATION_MATRIX = 27
    VIPS_INTERPRETATION_scRGB = 28
    VIPS_INTERPRETATION_HSV = 29

type
  VipsRelational* {.importc: "VipsRelational", header: "vips/vips.h", size: sizeof(cint).} = enum
    VIPS_RELATIONAL_EQUAL = 0
    VIPS_RELATIONAL_NOTEQ = 1
    VIPS_RELATIONAL_LESS = 2
    VIPS_RELATIONAL_LESSEQ = 3
    VIPS_RELATIONAL_MORE = 4
    VIPS_RELATIONAL_MOREEQ = 5

type
  VipsError* = object of CatchableError

proc vips_init*(argv0: cstring): cint {.importc: "vips_init", header: "vips/vips.h".}
proc vips_shutdown*() {.importc: "vips_shutdown", header: "vips/vips.h".}

proc g_object_ref*(obj: pointer): pointer {.importc: "g_object_ref", header: "glib-object.h".}
proc g_object_unref*(obj: pointer) {.importc: "g_object_unref", header: "glib-object.h".}

proc vips_image_new*(): ptr VipsImage {.importc: "vips_image_new", header: "vips/vips.h".}

proc vips_image_new_from_file*(filename: cstring, args: pointer): ptr VipsImage {.
  importc: "vips_image_new_from_file", header: "vips/vips.h".}

proc vips_image_new_from_memory*(data: pointer, size: csize_t, width: cint, height: cint, 
                                bands: cint, format: VipsFormat): ptr VipsImage {.
  importc: "vips_image_new_from_memory", header: "vips/vips.h".}

proc vips_image_new_from_memory_copy*(data: pointer, size: csize_t, width: cint, height: cint,
                                     bands: cint, format: VipsFormat): ptr VipsImage {.
  importc: "vips_image_new_from_memory_copy", header: "vips/vips.h".}

proc vips_image_get_width*(image: ptr VipsImage): cint {.
  importc: "vips_image_get_width", header: "vips/vips.h".}

proc vips_image_get_height*(image: ptr VipsImage): cint {.
  importc: "vips_image_get_height", header: "vips/vips.h".}

proc vips_image_get_bands*(image: ptr VipsImage): cint {.
  importc: "vips_image_get_bands", header: "vips/vips.h".}

proc vips_image_get_format*(image: ptr VipsImage): VipsFormat {.
  importc: "vips_image_get_format", header: "vips/vips.h".}

proc vips_image_get_interpretation*(image: ptr VipsImage): VipsInterpretation {.
  importc: "vips_image_get_interpretation", header: "vips/vips.h".}

proc vips_image_write_to_file*(image: ptr VipsImage, filename: cstring, args: pointer): cint {.
  importc: "vips_image_write_to_file", header: "vips/vips.h".}

proc vips_image_write_to_memory*(image: ptr VipsImage, size: ptr csize_t): pointer {.
  importc: "vips_image_write_to_memory", header: "vips/vips.h".}

proc vips_maplut*(input: ptr VipsImage, output: ptr ptr VipsImage, lut: ptr VipsImage, 
                  args: pointer): cint {.
  importc: "vips_maplut", header: "vips/vips.h".}

proc vips_resize*(input: ptr VipsImage, output: ptr ptr VipsImage, scale: cdouble, 
                  args: pointer): cint {.
  importc: "vips_resize", header: "vips/vips.h".}

proc vips_hist_find*(input: ptr VipsImage, output: ptr ptr VipsImage, args: pointer): cint {.
  importc: "vips_hist_find", header: "vips/vips.h".}

proc vips_hist_find_indexed*(input: ptr VipsImage, output: ptr ptr VipsImage, 
                            index: ptr VipsImage, args: pointer): cint {.
  importc: "vips_hist_find_indexed", header: "vips/vips.h".}

proc vips_getpoint*(image: ptr VipsImage, vector: ptr cdouble, x: cint, y: cint, 
                    args: pointer): cint {.
  importc: "vips_getpoint", header: "vips/vips.h".}

proc vips_add*(left: ptr VipsImage, right: ptr VipsImage, output: ptr ptr VipsImage,
               args: pointer): cint {.
  importc: "vips_add", header: "vips/vips.h".}

proc vips_subtract*(left: ptr VipsImage, right: ptr VipsImage, output: ptr ptr VipsImage,
                    args: pointer): cint {.
  importc: "vips_subtract", header: "vips/vips.h".}

proc vips_multiply*(left: ptr VipsImage, right: ptr VipsImage, output: ptr ptr VipsImage,
                    args: pointer): cint {.
  importc: "vips_multiply", header: "vips/vips.h".}

proc vips_add_const*(input: ptr VipsImage, output: ptr ptr VipsImage, c: ptr cdouble, n: cint,
                     args: pointer): cint {.
  importc: "vips_linear", header: "vips/vips.h".}  # Note: vips_add_const is deprecated

proc vips_multiply_const*(input: ptr VipsImage, output: ptr ptr VipsImage, c: ptr cdouble, n: cint,
                          args: pointer): cint {.
  importc: "vips_linear", header: "vips/vips.h".}  # Use vips_linear instead

proc vips_linear*(input: ptr VipsImage, output: ptr ptr VipsImage, a: ptr cdouble, b: ptr cdouble,
                  n: cint, args: pointer): cint {.
  importc: "vips_linear", header: "vips/vips.h".}

proc vips_relational*(left: ptr VipsImage, right: ptr VipsImage, output: ptr ptr VipsImage,
                      relational: VipsRelational, args: pointer): cint {.
  importc: "vips_relational", header: "vips/vips.h".}

proc vips_relational_const*(input: ptr VipsImage, output: ptr ptr VipsImage,
                           relational: VipsRelational, c: ptr cdouble, n: cint,
                           args: pointer): cint {.
  importc: "vips_relational_const", header: "vips/vips.h".}

proc vips_boolean*(left: ptr VipsImage, right: ptr VipsImage, output: ptr ptr VipsImage,
                   boolean: cint, args: pointer): cint {.
  importc: "vips_boolean", header: "vips/vips.h".}

proc vips_ifthenelse*(cond: ptr VipsImage, input1: ptr VipsImage, input2: ptr VipsImage,
                      output: ptr ptr VipsImage, args: pointer): cint {.
  importc: "vips_ifthenelse", header: "vips/vips.h".}

proc vips_colourspace*(input: ptr VipsImage, output: ptr ptr VipsImage,
                       space: VipsInterpretation, args: pointer): cint {.
  importc: "vips_colourspace", header: "vips/vips.h".}

proc vips_icc_transform*(input: ptr VipsImage, output: ptr ptr VipsImage,
                         output_profile: cstring, args: pointer): cint {.
  importc: "vips_icc_transform", header: "vips/vips.h".}

proc vips_avg*(input: ptr VipsImage, output: ptr cdouble, args: pointer): cint {.
  importc: "vips_avg", header: "vips/vips.h".}

proc vips_min*(input: ptr VipsImage, output: ptr cdouble, args: pointer): cint {.
  importc: "vips_min", header: "vips/vips.h".}

proc vips_max*(input: ptr VipsImage, output: ptr cdouble, args: pointer): cint {.
  importc: "vips_max", header: "vips/vips.h".}

proc vips_image_set_int*(image: ptr VipsImage, name: cstring, i: cint) {.
  importc: "vips_image_set_int", header: "vips/vips.h".}

proc vips_image_get_int*(image: ptr VipsImage, name: cstring, output: ptr cint): cint {.
  importc: "vips_image_get_int", header: "vips/vips.h".}

proc vips_malloc*(size: csize_t): pointer {.importc: "vips_malloc", header: "vips/vips.h".}

proc vips_error_buffer*(): cstring {.importc: "vips_error_buffer", header: "vips/vips.h".}
proc vips_error_clear*() {.importc: "vips_error_clear", header: "vips/vips.h".}

proc checkVipsResult*(result: cint, operation: string = "vips operation") =
  if result != 0:
    let errorMsg = $vips_error_buffer()
    vips_error_clear()
    raise newException(VipsError, operation & " failed: " & errorMsg)

proc createImageFromData*(data: seq[uint8], width, height, bands: int): ptr VipsImage =
  result = vips_image_new_from_memory_copy(
    data[0].unsafeAddr,
    data.len.csize_t,
    width.cint,
    height.cint,
    bands.cint,
    VIPS_FORMAT_UCHAR.cint
  )
  if result == nil:
    raise newException(VipsError, "Failed to create image from data")

proc getPixelSafe*(image: ptr VipsImage, x, y: int): seq[float] =
  let bands = vips_image_get_bands(image).int
  result = newSeq[float](bands)
  var values = newSeq[cdouble](bands)
  
  let status = vips_getpoint(image, values[0].addr, x.cint, y.cint, nil)
  if status != 0:
    checkVipsResult(status, "getpoint")
  
  for i in 0..<bands:
    result[i] = values[i].float

{.pragma: vipsLib, dynlib: "libvips.so.42".}

{.passC: gorge("pkg-config --cflags vips").}
{.passL: gorge("pkg-config --libs vips").}
