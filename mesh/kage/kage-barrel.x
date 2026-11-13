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
 21;
 0.14879;-0.18730;-0.12761;,
 0.07329;0.00000;0.00018;,
 0.05067;-0.05781;1.80491;,
 0.10134;-0.18730;1.80491;,
 -0.07329;0.00000;0.00018;,
 -0.14879;-0.18730;-0.12761;,
 -0.10134;-0.18730;1.80491;,
 -0.05067;-0.05781;1.80491;,
 -0.07329;-0.37461;0.00018;,
 -0.05067;-0.31680;1.80491;,
 0.07329;-0.37461;0.00018;,
 0.05067;-0.31680;1.80491;,
 0.00000;-0.18730;1.30222;,
 0.09310;-0.18730;1.52309;,
 0.04655;-0.06833;1.52309;,
 -0.04655;-0.06833;1.52309;,
 -0.09310;-0.18730;1.52309;,
 -0.04655;-0.30627;1.52309;,
 0.04655;-0.30627;1.52309;,
 -0.06287;-0.02661;0.83111;,
 0.06287;-0.02661;0.83111;;
 
 17;
 4;0,1,2,3;,
 4;4,5,6,7;,
 4;5,8,9,6;,
 4;8,10,11,9;,
 4;10,0,3,11;,
 3;12,3,2;,
 3;12,2,7;,
 3;12,7,6;,
 3;12,6,9;,
 3;12,9,11;,
 3;12,11,3;,
 4;4,1,0,5;,
 4;5,0,10,8;,
 4;13,14,15,16;,
 4;17,18,13,16;,
 4;4,19,20,1;,
 4;19,7,2,20;;
 
 MeshMaterialList {
  5;
  17;
  3,
  3,
  3,
  3,
  3,
  0,
  0,
  0,
  0,
  0,
  0,
  1,
  1,
  1,
  1,
  1,
  2;;
  Material {
   0.000000;1.000000;0.000000;1.000000;;
   5.000000;
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
   0.600000;0.000000;0.000000;;
  }
  Material {
   1.000000;1.000000;1.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.250000;0.250000;0.250000;;
  }
 }
 MeshNormals {
  22;
  0.999692;-0.000001;0.024801;,
  0.931785;0.362274;0.023117;,
  -0.931785;0.362274;0.023117;,
  -0.999692;-0.000001;0.024801;,
  -0.931784;-0.362276;0.023117;,
  -0.000000;-0.891554;-0.452914;,
  0.000000;-0.999487;0.032015;,
  -0.980279;0.000001;0.197617;,
  0.000000;0.000000;1.000000;,
  0.000000;0.999487;0.032014;,
  0.931784;-0.362276;0.023117;,
  -0.915264;-0.358117;0.184511;,
  0.000000;-0.968384;0.249465;,
  0.980279;0.000001;0.197617;,
  0.915264;-0.358117;0.184511;,
  0.915263;0.358120;0.184511;,
  0.000000;0.968384;0.249463;,
  -0.915263;0.358120;0.184511;,
  0.000000;0.891554;-0.452914;,
  0.000000;0.563581;-0.826061;,
  -0.000000;-0.563581;-0.826061;,
  0.000000;0.999487;0.032015;;
  17;
  4;0,1,1,0;,
  4;2,3,3,2;,
  4;3,4,4,3;,
  4;5,5,6,6;,
  4;10,0,0,10;,
  3;7,7,11;,
  3;12,12,12;,
  3;13,14,13;,
  3;13,13,15;,
  3;16,16,16;,
  3;7,17,7;,
  4;18,18,19,19;,
  4;20,20,5,5;,
  4;8,8,8,8;,
  4;8,8,8,8;,
  4;18,9,9,18;,
  4;9,21,21,9;;
 }
}
