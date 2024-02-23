from ctypes import Structure, cdll, c_int32, c_void_p, c_char_p, c_float, c_bool, POINTER

lib = cdll.LoadLibrary('./libExampleLib.dylib')

lib.startCocoaApplication()
lib.resizeWindow(800, 200)

class Event(Structure):
    _fields_ = [
        ('type', c_int32),
        ('keyCode', c_int32),
        ('mouseX', c_float),
        ('mouseY', c_float),
        ('mouseButton', c_int32),
        ('isPressed', c_bool),
    ]

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

while True:
    poll_events()
    lib.update()

