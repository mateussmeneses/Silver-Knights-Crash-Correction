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
 -0.09656;0.07228;0.07087;,
 -0.01255;-0.06682;0.11158;,
 -0.04580;0.12872;0.07087;,
 0.11129;0.12896;0.07087;,
 0.20867;-0.00912;0.06976;,
 -0.09656;0.07228;-0.07087;,
 -0.04580;0.12872;-0.07087;,
 -0.01255;-0.06682;-0.11158;,
 0.11129;0.12896;-0.07087;,
 0.20867;-0.00912;-0.06976;;
 
 11;
 3;0,1,2;,
 3;2,1,3;,
 3;3,1,4;,
 3;5,6,7;,
 3;6,8,7;,
 3;8,9,7;,
 4;2,6,5,0;,
 4;8,6,2,3;,
 4;9,8,3,4;,
 4;9,4,1,7;,
 4;5,7,1,0;;
 
 MeshMaterialList {
  5;
  11;
  4,
  4,
  4,
  4,
  4,
  4,
  4,
  4,
  4,
  1,
  1;;
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
  16;
  -0.188340;0.169388;0.967386;,
  -0.010145;0.160779;0.986938;,
  -0.094761;0.187441;0.977694;,
  0.079470;0.154506;0.984791;,
  0.158549;0.103876;0.981872;,
  -0.188340;0.169388;-0.967386;,
  -0.010145;0.160779;-0.986938;,
  -0.094761;0.187441;-0.977694;,
  0.079470;0.154506;-0.984791;,
  0.158549;0.103876;-0.981872;,
  -0.407695;0.913118;0.000000;,
  -0.743526;0.668707;0.000000;,
  0.459570;0.888142;0.000000;,
  0.817207;0.576344;0.000000;,
  0.252367;-0.967632;0.000000;,
  -0.855996;-0.516983;0.000000;;
  11;
  3;0,1,2;,
  3;2,1,3;,
  3;3,1,4;,
  3;5,7,6;,
  3;7,8,6;,
  3;8,9,6;,
  4;10,10,11,11;,
  4;12,10,10,12;,
  4;13,12,12,13;,
  4;14,14,14,14;,
  4;15,15,15,15;;
 }
 MeshTextureCoords {
  10;
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
