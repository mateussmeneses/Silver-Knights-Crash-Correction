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
 15;
 0.08649;-0.70962;0.03677;,
 0.06075;-0.06285;0.03677;,
 0.00000;-0.06459;0.08019;,
 0.00000;-0.72365;0.09852;,
 -0.08649;-0.70962;0.03677;,
 -0.06075;-0.06285;0.03677;,
 -0.00000;-0.10888;-0.18710;,
 -0.00000;-1.09841;-0.33139;,
 -0.03293;0.07617;0.02696;,
 0.00000;0.10424;-0.08863;,
 -0.00000;-0.10712;-0.13428;,
 -0.04371;-0.06285;0.03677;,
 0.03293;0.07617;0.02696;,
 0.04371;-0.06285;0.03677;,
 -0.00000;-1.25004;-0.30774;;
 
 14;
 4;0,1,2,3;,
 4;4,3,2,5;,
 3;4,0,3;,
 3;5,2,1;,
 4;5,6,7,4;,
 4;1,0,7,6;,
 3;5,1,6;,
 4;8,9,10,11;,
 4;12,13,10,9;,
 4;12,8,11,13;,
 3;9,8,12;,
 3;7,14,4;,
 3;14,7,0;,
 3;0,4,14;;
 
 MeshMaterialList {
  5;
  14;
  2,
  2,
  2,
  1,
  4,
  4,
  1,
  2,
  2,
  2,
  0,
  0,
  0,
  0;;
  Material {
   0.000000;1.000000;0.000000;1.000000;;
   9.000000;
   1.000000;1.000000;1.000000;;
   1.000000;0.624000;0.275000;;
  }
  Material {
   0.050000;0.050000;0.050000;1.000000;;
   5.000000;
   0.000000;0.000000;0.000000;;
   0.012750;0.012750;0.012750;;
  }
  Material {
   0.250000;0.250000;0.250000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.062750;0.062750;0.062750;;
  }
  Material {
   1.000000;1.000000;1.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.237250;0.237250;0.237250;;
  }
  Material {
   1.000000;0.000000;0.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.086250;0.075500;0.250000;;
  }
 }
 MeshNormals {
  19;
  0.579664;0.022899;0.814533;,
  0.316749;-0.281223;0.905861;,
  -0.972421;0.003917;-0.233199;,
  -0.579664;0.022899;0.814533;,
  -0.316749;-0.281223;0.905861;,
  -0.962593;0.038639;-0.268183;,
  -0.963734;0.056330;-0.260853;,
  0.963734;0.056330;-0.260853;,
  -0.979793;-0.030815;-0.197627;,
  -0.000000;-0.975157;-0.221515;,
  0.000000;0.996691;-0.081289;,
  0.000000;0.999200;0.040001;,
  0.962593;0.038639;-0.268183;,
  0.972421;0.003917;-0.233199;,
  0.000000;0.979513;-0.201383;,
  0.000000;0.070419;0.997518;,
  0.000000;0.971754;0.235995;,
  0.979793;-0.030815;-0.197627;,
  0.000000;-0.537550;0.843232;;
  14;
  4;1,0,0,0;,
  4;4,3,3,3;,
  3;9,9,9;,
  3;10,11,10;,
  4;5,5,2,2;,
  4;12,13,13,12;,
  3;10,10,14;,
  4;6,6,6,6;,
  4;7,7,7,7;,
  4;15,15,15,15;,
  3;16,16,16;,
  3;2,8,2;,
  3;17,13,13;,
  3;1,4,18;;
 }
 MeshTextureCoords {
  15;
  0.000000;0.000000;
  0.000000;0.000000;
  0.000000;0.000000;
  0.000000;0.000000;
  0.000000;0.000000;
  0.000000;0.000000;
  0.000000;0.000000;
  0.000000;0.000000;
  0.000000;0.000000;
  0.000000;0.000000;
  0.000000;0.000000;
  0.000000;0.000000;
  0.000000;0.000000;
  0.000000;0.000000;
  0.000000;0.000000;;
 }
}
