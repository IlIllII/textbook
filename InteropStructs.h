typedef struct {
    int type;
    int keyCode;
    int mouseX, mouseY;
    int mouseButton;
    int isPressed;
} Event;

typedef struct {
    float r;
    float g;
    float b;
    float a;
} PythonColor;

typedef struct {
    float x;
    float y;
} PythonPoint;