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
 -0.03731;0.01150;0.03294;,
 -0.09147;-0.59827;0.07557;,
 0.09164;-0.59825;0.07554;,
 0.03729;0.01151;0.03293;,
 0.00010;-0.72453;0.08438;,
 -0.04083;0.04737;-0.03629;,
 0.04078;0.04739;-0.03631;,
 0.11185;-0.69700;-0.03634;,
 -0.11169;-0.69703;-0.03631;,
 0.00010;-0.86791;-0.03633;;
 
 9;
 4;0,1,2,3;,
 3;2,1,4;,
 4;5,6,7,8;,
 3;7,9,8;,
 4;6,5,0,3;,
 4;7,6,3,2;,
 4;9,7,2,4;,
 4;4,1,8,9;,
 4;1,0,5,8;;
 
 MeshMaterialList {
  5;
  9;
  4,
  4,
  1,
  1,
  4,
  4,
  4,
  4,
  4;;
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
   1.000000;1.000000;1.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.250000;0.250000;0.250000;;
  }
  Material {
   1.000000;0.000000;0.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.250000;0.000000;0.000000;;
  }
 }
 MeshNormals {
  14;
  0.264152;-0.122293;0.956696;,
  0.000055;0.549058;0.835784;,
  0.403245;-0.226861;0.886525;,
  -0.263816;-0.122364;0.956780;,
  -0.000167;0.000035;-1.000000;,
  -0.000172;0.000034;-1.000000;,
  -0.000161;0.000035;-1.000000;,
  -0.000048;0.887870;0.460094;,
  0.916448;-0.200000;0.346589;,
  0.990758;0.094769;0.097042;,
  0.700377;-0.463832;0.542523;,
  -0.700071;-0.464022;0.542756;,
  -0.916277;-0.200253;0.346894;,
  -0.990752;0.094492;0.097373;;
  9;
  4;1,3,0,1;,
  3;0,3,2;,
  4;5,5,4,4;,
  3;4,6,4;,
  4;7,7,1,1;,
  4;8,9,9,9;,
  4;10,8,0,2;,
  4;11,3,12,11;,
  4;13,13,13,12;;
 }
}
