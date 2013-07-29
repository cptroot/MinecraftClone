import std.stdio;
import std.conv;

string readString(const(byte[]) buffer, ref uint index) {
  string result;
  while (buffer[index] != 0) {
    result ~= to!char(buffer[index]);
    index++;
  }
  index++;
  return result;
}

float readFloat(const(byte[]) buffer, ref uint index) {
  int result;
  foreach (_;0..4) {
    result <<= 8;
    result += buffer[index] + 128;
    index++;
  }
  return *cast(float *)(&result);
}

int readInt(const(byte[]) buffer, ref uint index) {
  int result;
  foreach (_;0..4) {
    result <<= 8;
    result += buffer[index] + 128;
    index++;
  }
  return result;
}

byte[] writeString(string str) {
  byte[] result;
  result.length = str.length;
  foreach (i, c; str) 
    result[i] = c;
  result ~= [0];
  return result;
}

byte[4] writeFloat(float f) {
  byte[4] result;
  int castInt = *cast(int *)(&f);
  foreach (i; 0..4) {
    result[4 - i - 1] = cast(byte)(castInt % 256 - 128);
    castInt >>= 8;
  }
  return result;
}

byte[4] writeInt(int i) {
  byte[4] result;
  foreach (j; 0..4) {
    result [4 - j - 1] = cast(byte) (i % 256 - 128);
    i >>= 8;
  }
  return result;
}

unittest {
  int index = 0;
  assert (20 == readInt(writeInt(20), index));
  index = 0;
  assert ("Hello World" == readString(writeString("Hello World"), index));
  index = 0;
  assert (1.012f == readFloat(writeFloat(1.012f), index));
}