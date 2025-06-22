version = "0.1.0"
author = "Licorice"
description = "Fast as Fuck interpolated LUT generator and applier"
license = "GPL-3.0-only"
srcDir = "src"
bin = @["clutter"]

# Dependencies
requires "nim >= 2.0.0"
requires "kdl >= 2.0.3"
requires "therapist >= 0.3.0"

# More Dependencies
import distros
if detectOs(Ubuntu) or detectOs(Debian):
  foreignDep "libvips"
  foreignDep "libvips-tools"
else:
  foreignDep "libvips"
