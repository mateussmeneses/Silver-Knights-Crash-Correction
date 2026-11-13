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
 -0.05806;-0.11099;-0.02853;,
 -0.03933;-0.19864;0.07447;,
 -0.02851;-0.19879;0.12094;,
 -0.03213;-0.00890;0.05685;,
 -0.05297;0.11509;-0.03856;,
 0.05796;-0.11099;-0.02853;,
 0.03203;-0.00890;0.05685;,
 0.02841;-0.19879;0.12094;,
 0.03923;-0.19864;0.07447;,
 0.05287;0.11509;-0.03856;;
 
 9;
 4;0,1,2,3;,
 3;3,4,0;,
 4;5,6,7,8;,
 3;6,5,9;,
 4;9,4,3,6;,
 4;3,2,7,6;,
 4;7,2,1,8;,
 4;8,1,0,5;,
 4;4,9,5,0;;
 
 MeshMaterialList {
  5;
  9;
  1,
  1,
  1,
  1,
  1,
  1,
  3,
  3,
  3;;
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
   0.600000;0.000000;0.000000;;
  }
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
 }
 MeshNormals {
  13;
  -0.969648;0.045477;0.240237;,
  -0.972326;0.057911;0.226337;,
  -0.966627;0.033027;0.254052;,
  0.969649;0.045476;0.240233;,
  0.972329;0.057905;0.226324;,
  0.966625;0.033032;0.254057;,
  0.000000;0.609839;0.792526;,
  0.000000;0.471233;0.882009;,
  0.000000;0.319800;0.947485;,
  -0.000000;-0.999994;-0.003336;,
  -0.000000;-0.937933;-0.346817;,
  -0.000000;-0.439511;-0.898237;,
  -0.000000;-0.044313;-0.999018;;
  9;
  4;0,1,1,0;,
  3;0,2,0;,
  4;3,3,4,4;,
  3;3,3,5;,
  4;6,6,7,7;,
  4;7,8,8,7;,
  4;9,9,10,10;,
  4;10,10,11,11;,
  4;12,12,11,11;;
 }
}
