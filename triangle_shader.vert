#version 330

layout (location = 0) in vec4 position;
layout (location = 1) in vec4 color;

// Row major
uniform mat4 perspectiveMatrix;
uniform mat4 worldMatrix;

smooth out vec4 theColor;

void main()
{
	vec4 relPosition = position;
	relPosition = worldMatrix * relPosition;
	gl_Position = perspectiveMatrix * relPosition;
    theColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);
}