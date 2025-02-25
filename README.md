# Frame Drawer

## Overview

Frame Drawer is a DOS-based assembly program written in Intel 80186 Assembly Language. It allows users to draw customizable text-based frames around messages on the screen. The program provides various frame styles.

## Features

- Supports different frame styles
- Customizable frame width and height
- User-defined text message centered inside the frame
- Uses DOS interrupts for execution

## Requirements

- DOS environment or an emulator like DOSBox
- MASM/TASM assembler
- 16-bit compatible processor or emulator

## Usage

Run the program with the following command-line arguments:

```
frame.com <width> <height> <color> <style number> (<9 characters of style> if style number is zero) <message>'$'
```

### Arguments:

- `<width>`: Width of the frame (in characters)
- `<height>`: Height of the frame (in characters)
- `<color>`: Hexadecimal color attribute for text (e.g., `4e`)
- `<style>`: Frame style index (0-8)
- `<9 characters of style>`: User's provided frame style. (optional)
- `<message>`: Optional text message to be displayed in the center

### Example:

```
frame.com 10 6 4e 0 /-\-.-\-/ HELLO$
```

This will create a frame of 10x17 size, with '4e' color, custom style "/-\-.-\-/" and message "HELLO" in the senter of frame:

![example_1](img\frame1.jpg)

```
frame.com 40 10 0a 5 Hello, World!$
```

This will create a frame of 40x10 size, with green color '0A', using style 7, and displaying "Hello, World!":

![example_1](img\frame2.jpg)

## Implementation Details

### Main Functions:

- **DrawFrame**: Draws the frame using ASCII characters
- **ParseCmdLine**: Parses user input from the command line
- **DrawLine**: Draws a single line of the frame
- **DrawMessageLine**: Inserts the message in the center of the frame
- **Atoi & Atohex**: Convert string values to integer/hexadecimal

### Frame Styles:

The program includes predefined frame styles stored in `FrameStyleTable`.

## Notes

- You can change position of frame changing `RelativeFramePosition` constant.
