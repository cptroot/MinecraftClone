#version 330

smooth in vec4 theColor;

layout(location = 0) out vec4 outputColor;

void main()
{
    outputColor = theColor;
}