#version 330

layout (location = 0) in vec4 position;
layout (location = 1) in vec4 color;

uniform mat4 perspectiveMatrix;

smooth out vec4 theColor;

void main()
{
	vec4 relPosition = position + vec4(.75f, .75f, 0, 0);
	gl_Position = perspectiveMatrix * relPosition;
    theColor = color;
}