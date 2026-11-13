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
 24;
 -0.10304;-0.12083;0.07274;,
 -0.18670;-0.12083;0.28831;,
 -0.16807;-0.03012;0.34158;,
 -0.10300;0.05937;0.22338;,
 -0.04751;-0.12083;0.46157;,
 0.10304;-0.12083;0.07274;,
 0.10300;0.05937;0.22338;,
 0.16807;-0.03012;0.34158;,
 0.18670;-0.12083;0.28831;,
 0.04751;-0.12083;0.46157;,
 -0.10300;0.31001;-0.32319;,
 -0.10300;-0.12085;-0.48951;,
 0.10300;-0.12085;-0.48951;,
 0.10300;0.31001;-0.32319;,
 -0.10300;-0.12083;-0.01252;,
 0.10300;-0.12083;-0.01252;,
 0.26141;0.18722;-0.51975;,
 -0.26141;0.18722;-0.51975;,
 -0.26141;-0.01393;-0.01254;,
 0.26141;-0.01393;-0.01254;,
 -0.26141;-0.12085;-0.01254;,
 0.26141;-0.12085;-0.01254;,
 -0.26141;-0.12085;-0.51975;,
 0.26141;-0.12085;-0.51975;;
 
 19;
 4;0,1,2,3;,
 3;1,4,2;,
 4;5,6,7,8;,
 3;8,7,9;,
 4;0,5,8,1;,
 4;1,8,9,4;,
 4;7,2,4,9;,
 4;3,2,7,6;,
 4;3,10,11,0;,
 4;5,12,13,6;,
 4;10,13,12,11;,
 4;6,13,10,3;,
 4;0,14,15,5;,
 4;16,17,18,19;,
 4;19,18,20,21;,
 4;21,20,22,23;,
 4;23,22,17,16;,
 4;17,22,20,18;,
 4;23,16,19,21;;
 
 MeshMaterialList {
  5;
  19;
  2,
  3,
  2,
  3,
  2,
  2,
  2,
  2,
  1,
  1,
  1,
  1,
  1,
  4,
  4,
  4,
  4,
  4,
  4;;
  Material {
   1.000000;1.000000;1.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.484500;0.451000;0.500000;;
  }
  Material {
   0.078000;0.078000;0.078000;1.000000;;
   5.000000;
   0.000000;0.000000;0.000000;;
   0.019500;0.019500;0.019500;;
  }
  Material {
   0.180720;0.180720;0.180720;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.062750;0.062750;0.062750;;
  }
  Material {
   0.000000;1.000000;0.000000;1.000000;;
   9.000000;
   1.000000;1.000000;1.000000;;
   0.278000;1.000000;0.247000;;
  }
  Material {
   1.000000;0.000000;0.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.226500;0.122500;0.025500;;
  }
 }
 MeshNormals {
  21;
  -0.975250;0.159855;-0.152754;,
  -0.902252;0.311715;-0.297951;,
  -0.763320;-0.203300;0.613198;,
  0.975250;0.159855;-0.152754;,
  0.902252;0.311715;-0.297951;,
  0.763320;-0.203300;0.613198;,
  -1.000000;0.000087;0.000001;,
  1.000000;0.000087;0.000001;,
  0.000000;-1.000000;0.000012;,
  0.000000;0.929566;0.368657;,
  0.000000;0.000000;1.000000;,
  0.000000;-1.000000;0.000000;,
  0.000000;-1.000000;0.000006;,
  0.000000;0.797490;0.603332;,
  0.000000;0.797704;0.603049;,
  0.000000;0.858227;0.513271;,
  0.000000;0.360129;-0.932903;,
  0.000000;0.908984;0.416831;,
  0.000000;0.000000;-1.000000;,
  -1.000000;0.000000;0.000000;,
  1.000000;0.000000;0.000000;;
  19;
  4;0,1,1,0;,
  3;2,2,2;,
  4;3,3,4,4;,
  3;5,5,5;,
  4;12,12,11,11;,
  4;11,11,11,11;,
  4;13,13,14,14;,
  4;15,13,13,15;,
  4;0,6,6,0;,
  4;3,7,7,3;,
  4;16,16,16,16;,
  4;15,17,17,15;,
  4;12,8,8,12;,
  4;9,9,9,9;,
  4;10,10,10,10;,
  4;11,11,11,11;,
  4;18,18,18,18;,
  4;19,19,19,19;,
  4;20,20,20,20;;
 }
}
