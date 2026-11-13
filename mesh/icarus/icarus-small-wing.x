xof 0302txt 0064
template Header {
 <3D82AB43-62DA-11cf-AB39-0020AF71E433>
 WORD major;
 WORD minor;
 DWORD flags;
}

template Vector {
 <3D82AB5E-62DA-11cf-AB39-0020AF71E433>
 FLOAT x;
 FLOAT y;
 FLOAT z;
}

template Coords2d {
 <F6F23F44-7686-11cf-8F52-0040333594A3>
 FLOAT u;
 FLOAT v;
}

template Matrix4x4 {
 <F6F23F45-7686-11cf-8F52-0040333594A3>
 array FLOAT matrix[16];
}

template ColorRGBA {
 <35FF44E0-6C7C-11cf-8F52-0040333594A3>
 FLOAT red;
 FLOAT green;
 FLOAT blue;
 FLOAT alpha;
}

template ColorRGB {
 <D3E16E81-7835-11cf-8F52-0040333594A3>
 FLOAT red;
 FLOAT green;
 FLOAT blue;
}

template IndexedColor {
 <1630B820-7842-11cf-8F52-0040333594A3>
 DWORD index;
 ColorRGBA indexColor;
}

template Boolean {
 <4885AE61-78E8-11cf-8F52-0040333594A3>
 WORD truefalse;
}

template Boolean2d {
 <4885AE63-78E8-11cf-8F52-0040333594A3>
 Boolean u;
 Boolean v;
}

template MaterialWrap {
 <4885AE60-78E8-11cf-8F52-0040333594A3>
 Boolean u;
 Boolean v;
}

template TextureFilename {
 <A42790E1-7810-11cf-8F52-0040333594A3>
 STRING filename;
}

template Material {
 <3D82AB4D-62DA-11cf-AB39-0020AF71E433>
 ColorRGBA faceColor;
 FLOAT power;
 ColorRGB specularColor;
 ColorRGB emissiveColor;
 [...]
}

template MeshFace {
 <3D82AB5F-62DA-11cf-AB39-0020AF71E433>
 DWORD nFaceVertexIndices;
 array DWORD faceVertexIndices[nFaceVertexIndices];
}

template MeshFaceWraps {
 <4885AE62-78E8-11cf-8F52-0040333594A3>
 DWORD nFaceWrapValues;
 Boolean2d faceWrapValues;
}

template MeshTextureCoords {
 <F6F23F40-7686-11cf-8F52-0040333594A3>
 DWORD nTextureCoords;
 array Coords2d textureCoords[nTextureCoords];
}

template MeshMaterialList {
 <F6F23F42-7686-11cf-8F52-0040333594A3>
 DWORD nMaterials;
 DWORD nFaceIndexes;
 array DWORD faceIndexes[nFaceIndexes];
 [Material]
}

template MeshNormals {
 <F6F23F43-7686-11cf-8F52-0040333594A3>
 DWORD nNormals;
 array Vector normals[nNormals];
 DWORD nFaceNormals;
 array MeshFace faceNormals[nFaceNormals];
}

template MeshVertexColors {
 <1630B821-7842-11cf-8F52-0040333594A3>
 DWORD nVertexColors;
 array IndexedColor vertexColors[nVertexColors];
}

template Mesh {
 <3D82AB44-62DA-11cf-AB39-0020AF71E433>
 DWORD nVertices;
 array Vector vertices[nVertices];
 DWORD nFaces;
 array MeshFace faces[nFaces];
 [...]
}

Header{
1;
0;
1;
}

Mesh {
 10;
 0.00000;-1.61883;0.00460;,
 0.00000;0.00000;0.00325;,
 -0.01759;-0.18105;-0.15730;,
 -0.03641;-0.12394;-0.25086;,
 0.01759;-0.18105;-0.15730;,
 0.03641;-0.12394;-0.25086;,
 -0.00000;-0.01221;-0.02178;,
 -0.00000;-0.02083;-0.18399;,
 -0.02699;-0.11108;-0.22449;,
 0.02699;-0.11108;-0.22449;;
 
 10;
 3;0,1,2;,
 3;1,3,2;,
 3;0,4,1;,
 3;1,4,5;,
 3;2,4,0;,
 4;3,5,4,2;,
 3;5,3,1;,
 3;6,7,8;,
 3;9,7,6;,
 3;7,9,8;;
 
 MeshMaterialList {
  6;
  10;
  3,
  3,
  3,
  3,
  0,
  1,
  1,
  2,
  2,
  0;;
  Material {
   0.000000;1.000000;0.000000;1.000000;;
   9.000000;
   1.000000;1.000000;1.000000;;
   0.000000;1.000000;0.000000;;
  }
  Material {
   0.051000;0.051000;0.051000;1.000000;;
   5.000000;
   0.000000;0.000000;0.000000;;
   0.012750;0.012750;0.012750;;
  }
  Material {
   0.180720;0.180720;0.180720;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.062750;0.062750;0.062750;;
  }
  Material {
   1.000000;0.000000;0.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.250000;0.000000;0.000000;;
  }
  Material {
   1.000000;1.000000;1.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.250000;0.250000;0.250000;;
  }
  Material {
   1.000000;1.000000;1.000000;1.000000;;
   5.000000;
   0.000000;0.000000;0.000000;;
   0.250000;0.250000;0.250000;;
   TextureFilename {
    "emblem.bmp";
   }
  }
 }
 MeshNormals {
  13;
  -0.990133;-0.025941;0.137706;,
  -0.994066;0.000091;0.108782;,
  -0.984687;-0.051933;0.166419;,
  0.990133;-0.025941;0.137706;,
  0.984687;-0.051933;0.166419;,
  -0.956010;0.292921;-0.015560;,
  0.956010;0.292921;-0.015560;,
  0.994066;0.000091;0.108782;,
  -0.000000;-0.537500;-0.843264;,
  -0.000000;-0.111900;-0.993720;,
  -0.000000;-0.853572;-0.520974;,
  0.000000;0.898795;-0.438369;,
  0.000000;0.409403;-0.912354;;
  10;
  3;1,0,0;,
  3;0,2,0;,
  3;7,3,3;,
  3;3,3,4;,
  3;8,8,9;,
  4;10,10,8,8;,
  3;11,11,11;,
  3;5,5,5;,
  3;6,6,6;,
  3;12,12,12;;
 }
}
