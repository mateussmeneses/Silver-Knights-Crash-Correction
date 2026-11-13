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
 12;
 -0.12105;-0.75562;0.23841;,
 0.10778;-0.75562;0.23841;,
 0.10308;0.34320;0.32554;,
 -0.12575;0.34320;0.32554;,
 -0.66331;0.28283;-0.00270;,
 -0.12575;0.93746;-0.00270;,
 0.10308;0.93746;-0.00270;,
 0.64064;0.28283;-0.00270;,
 0.58466;-0.19203;-0.00270;,
 -0.60732;-0.19203;-0.00270;,
 0.10308;-1.77148;-0.00270;,
 -0.12575;-1.77148;-0.00270;;
 
 12;
 4;0,1,2,3;,
 4;4,5,6,7;,
 4;8,9,4,7;,
 4;7,2,1,8;,
 3;8,1,10;,
 3;2,7,6;,
 4;6,5,3,2;,
 3;5,4,3;,
 4;3,4,9,0;,
 3;9,11,0;,
 4;1,0,11,10;,
 4;9,8,10,11;;
 
 MeshMaterialList {
  5;
  12;
  3,
  1,
  1,
  3,
  4,
  3,
  3,
  3,
  3,
  4,
  4,
  1;;
  Material {
   0.000000;1.000000;0.000000;1.000000;;
   9.000000;
   1.000000;1.000000;1.000000;;
   1.000000;0.624000;0.275000;;
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
  16;
  -0.000002;-0.000002;-1.000000;,
  -0.274781;0.203824;0.939655;,
  -0.290861;-0.146248;0.945522;,
  -0.315223;-0.217785;0.923690;,
  -0.000001;0.000000;-1.000000;,
  -0.000001;-0.000001;-1.000000;,
  0.275276;0.204427;0.939379;,
  0.294685;-0.146763;0.944257;,
  0.321773;-0.220065;0.920887;,
  0.526335;0.182265;0.830513;,
  0.563449;-0.125012;0.816638;,
  0.262942;0.466491;0.844540;,
  -0.262941;0.466491;0.844540;,
  -0.525541;0.181160;0.831257;,
  -0.556680;-0.124387;0.821362;,
  -0.000002;-0.000001;-1.000000;;
  12;
  4;2,7,6,1;,
  4;5,0,0,5;,
  4;4,4,5,5;,
  4;9,6,7,10;,
  3;10,7,8;,
  3;6,9,11;,
  4;11,12,1,6;,
  3;12,13,1;,
  4;1,13,14,2;,
  3;14,3,2;,
  4;7,2,3,8;,
  4;4,4,15,15;;
 }
}
