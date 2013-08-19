#version 330

uniform sampler2D fbo_texture;
uniform sampler2D fbo_depth;
uniform vec2 size;
in vec4 gl_FragCoord;

out vec4 outputColor;

vec2 texCoords(vec4 screenCoord) {
  return screenCoord.xy / size;
}

bool NormalDiff(vec4 pix1, vec4 pix2) {
  float diff = 0;
  diff = diff + abs(pix1.r - pix2.r);
  diff = diff + abs(pix1.g - pix2.g);
  diff = diff + abs(pix1.b - pix2.b);

  if (diff > .01) return true;
  return false;
}

bool compareNormals(vec4 screenCoord, vec4 diff1, vec4 diff2) {
  vec4 color1 = texture2D(fbo_texture, texCoords(screenCoord + diff1));
  vec4 color2 = texture2D(fbo_texture, texCoords(screenCoord + diff2));
  return NormalDiff(color1, color2);
}

float LinearizeDepth(vec2 uv)
{
  float n = .2; // camera z near
  float f = 20.0; // camera z far
  float z = texture2D(fbo_depth, uv).x;
  return (2.0 * n) / (f + n - z * (f - n));	
}

bool DepthDiff(float pix1, float pix2) {
  float diff = 0;
  diff = abs(pix1 - pix2);

  if (diff > .05) return true;
  return false;
}

bool compareDepths(vec4 screenCoord, vec4 diff1, vec4 diff2) {
  float color1 = LinearizeDepth(texCoords(screenCoord + diff1));
  float color2 = LinearizeDepth(texCoords(screenCoord + diff2));
  return DepthDiff(color1, color2);
}
 
void main(void) {
  bool diffVert = compareNormals(gl_FragCoord, vec4(0, 1, 0, 0), vec4(0, -1, 0, 0));
  bool diffHoriz = compareNormals(gl_FragCoord, vec4(-1, 0, 0, 0), vec4(1, 0, 0, 0));
  
  bool diffVert2 = compareDepths(gl_FragCoord, vec4(0, 1, 0, 0), vec4(0, -1, 0, 0));
  bool diffHoriz2 = compareDepths(gl_FragCoord, vec4(-1, 0, 0, 0), vec4(1, 0, 0, 0));

  outputColor = diffVert || diffHoriz || diffVert2 || diffHoriz2 ? vec4(0, 0, 0, 1) : vec4(1, 1, 1, 1);
  //outputColor = texture2D(fbo_depth, texCoords(gl_FragCoord));
  //outputColor = compareDepths(gl_FragCoord, vec4(0, 1, 0, 0), vec4(0, -1, 0, 0)) ? vec4(0, 0, 0, 1) : vec4(1, 1, 1, 1);
  //outputColor = LinearizeDepth(texCoords(gl_FragCoord));
}