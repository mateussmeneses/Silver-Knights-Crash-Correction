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
 32;
 -0.01640;0.03270;0.09490;,
 -0.01640;-0.03263;0.09490;,
 0.01514;-0.03263;0.09490;,
 0.01514;0.03270;0.09490;,
 0.01514;-0.03263;-2.06607;,
 0.01514;0.03270;-2.06607;,
 -0.01640;0.03270;-2.06607;,
 -0.01640;-0.03263;-2.06607;,
 -0.02037;0.03559;-2.06607;,
 -0.02037;-0.03552;-2.06607;,
 0.01911;-0.03552;-2.06607;,
 0.01911;0.03559;-2.06607;,
 0.01911;-0.03552;-2.19614;,
 0.01911;0.03559;-2.14137;,
 -0.02037;-0.03552;-2.19614;,
 -0.02037;0.03559;-2.14137;,
 -0.02037;0.03559;0.08976;,
 -0.02037;-0.03552;0.08976;,
 0.01911;-0.03552;0.08976;,
 0.01911;0.03559;0.08976;,
 0.01911;-0.03552;0.06035;,
 0.01911;0.03559;0.06035;,
 -0.02037;-0.03552;0.06035;,
 -0.02037;0.03559;0.06035;,
 -0.02571;0.04824;0.04252;,
 -0.02571;-0.04816;0.04252;,
 0.02445;-0.04816;0.04252;,
 0.02445;0.04824;0.04252;,
 0.02445;-0.04816;-0.04258;,
 0.02445;0.04824;-0.04258;,
 -0.02571;-0.04816;-0.04258;,
 -0.02571;0.04824;-0.04258;;
 
 23;
 4;0,1,2,3;,
 4;3,2,4,5;,
 4;0,3,5,6;,
 4;1,0,6,7;,
 4;2,1,7,4;,
 4;8,9,10,11;,
 4;11,10,12,13;,
 4;13,12,14,15;,
 4;15,14,9,8;,
 4;9,14,12,10;,
 4;15,8,11,13;,
 4;16,17,18,19;,
 4;19,18,20,21;,
 4;21,20,22,23;,
 4;23,22,17,16;,
 4;17,22,20,18;,
 4;23,16,19,21;,
 4;24,25,26,27;,
 4;27,26,28,29;,
 4;29,28,30,31;,
 4;31,30,25,24;,
 4;25,30,28,26;,
 4;31,24,27,29;;
 
 MeshMaterialList {
  5;
  23;
  1,
  2,
  2,
  2,
  2,
  1,
  3,
  3,
  3,
  3,
  3,
  1,
  3,
  1,
  3,
  3,
  3,
  1,
  3,
  1,
  3,
  3,
  3;;
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
 }
 MeshNormals {
  8;
  0.000000;0.000000;1.000000;,
  1.000000;0.000000;0.000000;,
  0.000000;1.000000;0.000000;,
  -1.000000;0.000000;0.000000;,
  0.000000;0.897280;-0.441462;,
  0.000000;0.610222;-0.792230;,
  -0.000000;0.000000;-1.000000;,
  0.000000;-1.000000;0.000000;;
  23;
  4;0,0,0,0;,
  4;1,1,1,1;,
  4;2,2,2,2;,
  4;3,3,3,3;,
  4;7,7,7,7;,
  4;0,0,0,0;,
  4;1,1,1,1;,
  4;4,5,5,4;,
  4;3,3,3,3;,
  4;7,7,7,7;,
  4;4,2,2,4;,
  4;0,0,0,0;,
  4;1,1,1,1;,
  4;6,6,6,6;,
  4;3,3,3,3;,
  4;7,7,7,7;,
  4;2,2,2,2;,
  4;0,0,0,0;,
  4;1,1,1,1;,
  4;6,6,6,6;,
  4;3,3,3,3;,
  4;7,7,7,7;,
  4;2,2,2,2;;
 }
}
