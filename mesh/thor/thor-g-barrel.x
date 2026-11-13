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
 20;
 0.03775;-0.06921;0.03827;,
 -0.03775;-0.06921;0.03827;,
 -0.03775;-0.06930;2.47723;,
 0.03775;-0.06930;2.47723;,
 -0.06599;-0.16619;2.47723;,
 0.06599;-0.16619;2.47723;,
 -0.03775;-0.26308;2.47723;,
 0.03775;-0.26308;2.47723;,
 -0.03775;-0.26308;0.03827;,
 0.03775;-0.26308;0.03827;,
 -0.06599;-0.16619;0.03827;,
 0.06599;-0.16619;0.03827;,
 0.02533;0.07185;-0.04943;,
 -0.02533;0.07185;-0.04943;,
 -0.02533;0.07185;0.19711;,
 0.02533;0.07185;0.19711;,
 -0.02533;-0.06921;0.32041;,
 0.02533;-0.06921;0.32041;,
 -0.02533;-0.06921;-0.04943;,
 0.02533;-0.06921;-0.04943;;
 
 16;
 4;0,1,2,3;,
 4;3,2,4,5;,
 4;5,4,6,7;,
 4;7,6,8,9;,
 4;1,10,4,2;,
 4;10,8,6,4;,
 4;9,11,5,7;,
 4;11,0,3,5;,
 4;12,13,14,15;,
 4;15,14,16,17;,
 4;17,16,18,19;,
 4;19,18,13,12;,
 4;13,18,16,14;,
 4;19,12,15,17;,
 4;1,0,11,10;,
 4;11,9,8,10;;
 
 MeshMaterialList {
  5;
  16;
  2,
  3,
  3,
  2,
  2,
  2,
  2,
  2,
  2,
  2,
  1,
  2,
  2,
  2,
  1,
  1;;
  Material {
   1.000000;1.000000;1.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.089250;0.140250;0.170500;;
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
   0.000000;1.000000;0.000000;1.000000;;
   9.000000;
   1.000000;1.000000;1.000000;;
   0.741000;0.376000;0.122000;;
  }
  Material {
   1.000000;0.000000;0.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.038250;0.068750;0.093250;;
  }
 }
 MeshNormals {
  15;
  0.000000;1.000000;0.000036;,
  0.000000;0.000000;1.000000;,
  0.000000;-1.000000;0.000000;,
  1.000000;-0.000062;0.000003;,
  -1.000000;-0.000062;0.000003;,
  0.000000;1.000000;0.000000;,
  0.000000;0.910529;0.413446;,
  0.000000;0.658126;0.752908;,
  -0.960076;0.279739;0.000005;,
  -0.960042;-0.279858;0.000000;,
  0.960039;-0.279867;-0.000000;,
  0.960073;0.279748;0.000005;,
  0.000000;0.000000;-1.000000;,
  -1.000000;0.000000;0.000000;,
  1.000000;0.000000;0.000000;;
  16;
  4;0,0,0,0;,
  4;1,1,1,1;,
  4;1,1,1,1;,
  4;2,2,2,2;,
  4;8,4,4,8;,
  4;4,9,9,4;,
  4;10,3,3,10;,
  4;3,11,11,3;,
  4;5,5,6,6;,
  4;6,6,7,7;,
  4;2,2,2,2;,
  4;12,12,12,12;,
  4;13,13,13,13;,
  4;14,14,14,14;,
  4;12,12,12,12;,
  4;12,12,12,12;;
 }
}
