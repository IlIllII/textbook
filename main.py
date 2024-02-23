from ctypes import Structure, cdll, c_int32, c_void_p, c_char_p, c_float, c_bool, POINTER

lib = cdll.LoadLibrary('./libswift.dylib')

lib.initializePlatformLayer()
lib.processEvents()
lib.resizeWindow(800, 800)


class Event(Structure):
    _fields_ = [
        ('type', c_int32),
        ('keyCode', c_int32),
        ('mouseX', c_float),
        ('mouseY', c_float),
        ('mouseButton', c_int32),
        ('isPressed', c_bool),
    ]

class Color(Structure):
    _fields_ = [
        ('r', c_float),
        ('g', c_float),
        ('b', c_float),
        ('a', c_float),
    ]

def draw_rectangle(x, y, width, height, color, filled: bool, fill_color: Color, line_thickness: float):
    lib.drawRectangle(x, y, width, height, color, 1 if filled is True else 0, fill_color, line_thickness)


# lib.drawRectangle(0, 0, 800, 200, 1, 0, 0, 1)

def poll_events():
    queue_empty = False
    while not queue_empty:
        data = lib.pollEvent()
        if data is None:
            queue_empty = True
        else:
            event = Event.from_address(data)
            if event.type == 0:
                print('Key event: ', event.keyCode)
            elif event.type == 1:
                print('Mouse event: ', event.mouseX, event.mouseY, event.mouseButton, event.isPressed)
        
        data.free()


x_pos = 0
y_pos = 0
draw_rectangle(x_pos, y_pos, c_float(500), c_float(50), Color(1, 0.5, 0, 0), True, Color(0, 0, 1, 1), 1)
print("Hi!")
lib.processEvents()
while True:
    lib.processEvents()
    x_pos += 0.01
    y_pos += 0
    # draw_rectangle(x_pos, y_pos, 500, 50, Color(1, 0.5, 0, 1), True, Color(0, 0, 1, 1), 1)
    draw_rectangle(c_float(x_pos), c_float(y_pos), c_float(500), c_float(50), Color(1, 0.5, 0, 0), True, Color(0, 0, 1, 1), 1)
    # poll_events()
    # lib.update()

