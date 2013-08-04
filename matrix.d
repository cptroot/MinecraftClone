module matrix;

import std.math;

// Row major
public struct Matrix {
  float[] mat = new float[16];

  size_t iterator = 0;

  Matrix opBinary(string op)(Matrix b) if (op == "*") {
    return matrixMult(this, b);
  }

  Matrix opOpAssign(string op)(Matrix b) if (op == "*") {
    mat = matrixMult(this, b);
    return this;
  }

  alias mat this;
}

@property Matrix identityMatrix() {
  static Matrix identityMatrix = Matrix();
  static initialized = false;
  if (!initialized)
  identityMatrix = [
    1f, 0f, 0f, 0f,
    0f, 1f, 0f, 0f,
    0f, 0f, 1f, 0f,
    0f, 0f, 0f, 1f,
  ];
  initialized = true;
  return identityMatrix;
}

private Matrix mat = Matrix();

Matrix translationMatrix(bool permanent, float x, float y, float z) {
  mat[0] = 1;
  mat[1] = 0;
  mat[2] = 0;
  mat[3] = x;

  mat[4] = 0;
  mat[5] = 1;
  mat[6] = 0;
  mat[7] = y;

  mat[8] = 0;
  mat[9] = 0;
  mat[10] = 1;
  mat[11] = z;

  mat[12] = 0;
  mat[13] = 0;
  mat[14] = 0;
  mat[15] = 1;

  if (permanent) {
    Matrix result = Matrix();
    result = mat.dup;
    return result;
  } else 
    return mat;
}

Matrix rotationMatrix(bool permanent, double angle, float x, float y, float z) {
  float C = cos(angle);
  float S = sin(angle);
  float iC = 1 - C;
  float iS = 1 - S;

  mat[0]  = x * x + (1 - x * x) * C;
  mat[1]  = iC * x * y - z * S;
  mat[2]  = iC * x * z + y * S;
  mat[3]  = 0;

  mat[4]  = iC * y * x + z * S;
  mat[5]  = y * y + (1 - y * y) * C;
  mat[6]  = iC * y * z - x * S;
  mat[7]  = 0;

  mat[8]  = iC * z * x - y * S;
  mat[9]  = iC * z * y + x * S;
  mat[10] = z * z + (1 - z * z) * C;
  mat[11] = 0;
  
  mat[12] = 0;
  mat[13] = 0;
  mat[14] = 0;
  mat[15] = 1;

  if (permanent) {
    Matrix result = Matrix();
    result = mat.dup;
    return result;
  } else
    return mat;
}

private int row, column, i;
private float sum;
Matrix matrixMult(Matrix mat1, Matrix mat2) {
  Matrix result = Matrix();

  foreach (row; 0..4) {
    foreach (column; 0..4) {
      sum = 0;
      foreach (i; 0..4) {
        sum += mat1[4 * row + i] * mat2[4 * i + column];
      }
      result[4 * row + column] = sum;
    }
  }
  return result;
}