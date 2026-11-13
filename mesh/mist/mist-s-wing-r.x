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
 18;
 0.02740;0.06447;0.09566;,
 0.02740;0.06447;-0.08056;,
 0.08635;-0.03103;-0.29271;,
 0.08635;-0.03103;0.01619;,
 0.00133;-0.30555;0.00682;,
 0.00133;-0.30555;0.09949;,
 0.00133;0.06447;0.09949;,
 0.00133;0.06447;-0.07818;,
 0.04060;-0.03105;0.01334;,
 0.01931;0.05709;0.09086;,
 -0.20159;0.05297;-0.04653;,
 0.00209;0.05297;-0.04653;,
 0.00209;0.05297;0.02422;,
 -0.20159;0.05297;0.02422;,
 0.00209;-0.09063;0.02422;,
 -0.04957;-0.09063;0.02422;,
 0.00209;-0.09063;-0.04653;,
 -0.04957;-0.09063;-0.04653;;
 
 15;
 4;3,2,1,0;,
 4;3,5,4,2;,
 4;1,7,6,0;,
 4;7,4,5,6;,
 3;7,2,4;,
 3;1,2,7;,
 4;0,9,8,3;,
 3;3,8,5;,
 3;6,9,0;,
 4;9,6,5,8;,
 4;13,12,11,10;,
 4;15,14,12,13;,
 4;17,16,14,15;,
 4;10,11,16,17;,
 4;15,13,10,17;;
 
 MeshMaterialList {
  5;
  15;
  2,
  2,
  2,
  1,
  1,
  2,
  1,
  1,
  4,
  4,
  2,
  2,
  2,
  2,
  2;;
  Material {
   1.000000;1.000000;1.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.374400;0.397800;0.449400;;
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
   0.137250;0.155000;0.250000;;
  }
  Material {
   0.000000;1.000000;0.000000;1.000000;;
   5.000000;
   1.000000;1.000000;1.000000;;
   1.000000;0.016000;0.016000;;
  }
 }
 MeshNormals {
  22;
  0.487224;0.873277;0.000000;,
  0.312725;0.936056;-0.161252;,
  0.992032;0.125988;0.000000;,
  0.919561;-0.170901;0.353838;,
  0.955238;-0.295837;-0.000000;,
  0.000000;1.000000;0.000000;,
  -0.019626;0.976516;-0.214549;,
  0.328491;-0.476671;0.815401;,
  0.284440;-0.140784;0.948301;,
  0.000000;0.000000;1.000000;,
  -0.369492;-0.929234;0.000000;,
  0.000000;-1.000000;-0.000000;,
  -1.000000;0.000000;0.000000;,
  -0.984429;-0.039355;-0.171318;,
  -0.938203;-0.077484;-0.337301;,
  -0.038331;0.907167;-0.419021;,
  -0.022930;-0.189073;0.981695;,
  0.066385;-0.632600;0.771628;,
  -0.059264;0.306638;0.949979;,
  0.483575;-0.361284;0.797264;,
  0.000000;0.000000;-1.000000;,
  -0.686689;-0.726951;0.000000;;
  15;
  4;2,2,1,0;,
  4;2,3,4,2;,
  4;1,6,5,0;,
  4;13,13,12,12;,
  3;13,14,13;,
  3;1,15,6;,
  4;17,7,8,16;,
  3;16,8,18;,
  3;19,7,17;,
  4;7,19,3,8;,
  4;5,5,5,5;,
  4;9,9,9,9;,
  4;10,11,11,10;,
  4;20,20,20,20;,
  4;10,21,21,10;;
 }
}
