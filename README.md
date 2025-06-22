# Clutter
Clutter is a command-line image processing tool written in Nim that applies cinematic color grading using customizable color palettes to create and apply smooth LookUp Tables (LUTs).
## Examples
| **Original**    | ![clutter](https://github.com/user-attachments/assets/7e2b86cb-a531-4031-984c-3367b8982b74)            |
| --------------- | ------------------------------------------------------------------------------------------------------ |
| **Nord**        | ![nord-clutter](https://github.com/user-attachments/assets/e0223b0d-783d-4dbd-9dcf-42be1e35d27a)       |
| **Catppuccin**  | ![catppuccin-clutter](https://github.com/user-attachments/assets/4a80774a-f863-47a4-8342-70abda49fd08) |
| **Tokyo Night** | ![tokyo-clutter](https://github.com/user-attachments/assets/f8c8c7fb-d492-4e6f-a08f-1b8439c928ac)      |


## Installation
### Dependencies
**Build Dependencies**:
- nim
- nimble (should be included with your nim install)

**Program Dependencies**:
- libvips
### Building
Clutter can be built and installed from Nim's package manager, nimble.
```sh
nimble install gh:arashi-software/clutter
```
or you can build from source
```sh
git clone https://github.com/arashi-software/clutter
cd clutter
nimble build
cp clutter ~/.local/bin/
```

## Usage
You can easily generate a LUT like this
```sh
clutter -i image.png -o out-image.png decay
```

You can check the configured palettes with
```sh
clutter p ls
```

You can create a new palette using clutter as well
```sh
clutter p add sapphy "#6A6B69 #232421 #B0F601 #A8CF4A #FEFEFE #EEEEEE #FF715B #E88873 #F991CC #D8829D #AFCBFF #85BDBF #D7F9FF #74D3AE #F3E9D2 #F9FBB2 #FFB17A #DE6E4B"

# or from a file with space seperated hex codes
clutter p add sapphy "$(cat ~/sapphy.txt)"
```

Or you can even skip the palette system altogether and manually specify the colors
```sh
clutter -i image.png -o out-image.png "#6A6B69 #232421 #B0F601 #A8CF4A #FEFEFE #EEEEEE #FF715B #E88873 #F991CC #D8829D #AFCBFF #85BDBF #D7F9FF #74D3AE #F3E9D2 #F9FBB2 #FFB17A #DE6E4B"

# or likewise
clutter -i image.png -o out-image.png "$(cat ~/sapphy.txt)"
```

To see the full range of options and commands
```sh
clutter -h
```
