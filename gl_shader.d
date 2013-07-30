module gl_shader;

import derelict.opengl3.gl3;

import std.string;
import std.stdio;
import std.conv : to;

uint CreateShader(uint shaderType, string strShaderFile)
{
  uint shader = glCreateShader(shaderType);
  const char *strFileData = strShaderFile.toStringz();
  glShaderSource(shader, 1, &strFileData, null);

  glCompileShader(shader);

  int status;
  glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
  if (status == GL_FALSE)
  {
    int infoLogLength;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLogLength);

    char[] strInfoLog = new char[infoLogLength + 1];
    glGetShaderInfoLog(shader, infoLogLength, null, strInfoLog.ptr);

    string strShaderType = null;
    final switch(shaderType)
    {
      case GL_VERTEX_SHADER: strShaderType = "vertex"; break;
      case GL_GEOMETRY_SHADER: strShaderType = "geometry"; break;
      case GL_FRAGMENT_SHADER: strShaderType = "fragment"; break;
    }

    stderr.writefln("Compile failure in %s shader:\n%s", strShaderType, to!string(strInfoLog));
  }

	return shader;
}

uint CreateProgram(const uint[] shaderList)
{
  uint program = glCreateProgram();

  for(size_t iLoop = 0; iLoop < shaderList.length; iLoop++)
    glAttachShader(program, shaderList[iLoop]);

  glLinkProgram(program);

  int status;
  glGetProgramiv (program, GL_LINK_STATUS, &status);
  if (status == GL_FALSE)
  {
    int infoLogLength;
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLogLength);

    char[] strInfoLog = new char[infoLogLength + 1];
    glGetProgramInfoLog(program, infoLogLength, null, strInfoLog.ptr);
    stderr.writefln("Linker failure: %s", strInfoLog);
  }

  for(size_t iLoop = 0; iLoop < shaderList.length; iLoop++)
    glDetachShader(program, shaderList[iLoop]);

  return program;
}

import std.file;

uint LoadProgram(string[] fileNames, uint[] shaderTypes) {
  uint[] shaderList = new uint[fileNames.length];

  string shaderStr;
  foreach (i; 0..fileNames.length) {
    shaderStr = readText(fileNames[i]);
    shaderList[i] = CreateShader(shaderTypes[i], shaderStr);
  }

  return CreateProgram(shaderList);
}