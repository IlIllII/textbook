from ctypes import (
    Structure,
    cdll,
    c_int32,
    c_void_p,
    c_char_p,
    c_float,
    c_bool,
    POINTER,
)
from time import sleep

lib = cdll.LoadLibrary("./libswift.dylib")

lib.initializePlatformLayer()
lib.processEvents()
lib.resizeWindow(800, 800)

width = 800
height = 800


class Event(Structure):
    _fields_ = [
        ("type", c_int32),
        ("keyCode", c_int32),
        ("mouseX", c_float),
        ("mouseY", c_float),
        ("mouseButton", c_int32),
        ("isPressed", c_bool),
    ]


class Color(Structure):
    _fields_ = [
        ("r", c_float),
        ("g", c_float),
        ("b", c_float),
        ("a", c_float),
    ]


class Point(Structure):
    _fields_ = [
        ("x", c_float),
        ("y", c_float),
    ]


lib.drawPath.argtypes = [POINTER(Point), c_int32, Color, c_int32, Color, c_float]


def draw_rectangle(
    x, y, width, height, color, filled: bool, fill_color: Color, line_thickness: float
):
    lib.drawRectangle(
        x,
        y,
        width,
        height,
        color,
        1 if filled is True else 0,
        fill_color,
        c_float(line_thickness),
    )


def draw_path(points, outline_color, filled, fill_color, line_thickness):
    points_array = (Point * len(points))(*points)
    lib.drawPath(
        points_array,
        c_int32(len(points)),
        outline_color,
        1 if filled is True else 0,
        fill_color,
        c_float(line_thickness),
    )


def poll_events():
    queue_empty = False
    while not queue_empty:
        data = lib.pollEvent()
        if data is None:
            queue_empty = True
        else:
            event = Event.from_address(data)
            if event.type == 0:
                print("Key event: ", event.keyCode)
            elif event.type == 1:
                print(
                    "Mouse event: ",
                    event.mouseX,
                    event.mouseY,
                    event.mouseButton,
                    event.isPressed,
                )

        data.free()


x_pos = 0
y_pos = 0
draw_rectangle(
    x_pos,
    y_pos,
    c_float(500),
    c_float(50),
    Color(1, 0.5, 0, 0),
    True,
    Color(0, 0, 1, 1),
    1,
)
print("Hi!")
lib.processEvents()
cached_x = 0

while True:
    sleep(0.0001)
    x_pos += 0.01
    y_pos += 0
    if int(x_pos) != cached_x:
        cached_x = int(x_pos)
        draw_path(
            [
                Point(c_float(0), c_float(0)),
                Point(c_float(0), c_float(100)),
                Point(c_float(100), c_float(x_pos)),
                Point(c_float(100), c_float(0)),
            ],
            Color(0.5, 0, 0, 1),
            True,
            Color(0, 1, 0, 1),
            1,
        )

        draw_rectangle(
            c_float(x_pos),
            c_float(y_pos),
            c_float(500),
            c_float(50),
            Color(1, 0.5, 0, 1),
            True,
            Color(0, 0, 1, 1),
            1,
        )
        width += 1
        lib.resizeWindow(width, height)
        print(lib.getWindowWidth())
        lib.processEvents()
    # poll_events()
    # lib.update()
