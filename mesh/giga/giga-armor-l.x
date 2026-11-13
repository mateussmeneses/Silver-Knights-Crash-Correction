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
 0.03786;-0.03973;0.10113;,
 0.07353;-0.00691;0.07497;,
 0.06517;0.03176;0.08000;,
 0.01877;0.02735;0.11286;,
 -0.18498;0.13706;0.16488;,
 -0.07550;-0.02653;0.12224;,
 -0.31550;0.18016;0.08123;,
 -0.19722;0.00822;0.04036;,
 0.03786;-0.03973;-0.10115;,
 0.01877;0.02735;-0.11288;,
 0.06517;0.03176;-0.08001;,
 0.07353;-0.00691;-0.07499;,
 -0.07550;-0.02653;-0.12225;,
 -0.18498;0.13706;-0.16490;,
 -0.19722;0.00822;-0.04038;,
 -0.31550;0.18016;-0.08125;,
 -0.30513;0.16635;0.03861;,
 -0.32732;0.14414;0.02539;,
 -0.23558;0.03396;0.01375;,
 -0.21687;0.03740;0.02090;,
 -0.30513;0.16635;-0.03863;,
 -0.21687;0.03740;-0.02092;,
 -0.23558;0.03396;-0.01376;,
 -0.32732;0.14414;-0.02541;;
 
 19;
 4;0,1,2,3;,
 4;3,4,5,0;,
 4;4,6,7,5;,
 4;8,9,10,11;,
 4;9,8,12,13;,
 4;13,12,14,15;,
 4;6,15,14,7;,
 4;5,7,14,12;,
 4;8,0,5,12;,
 4;1,0,8,11;,
 4;2,1,11,10;,
 4;10,9,3,2;,
 4;9,13,4,3;,
 4;15,6,4,13;,
 4;16,17,18,19;,
 4;20,21,22,23;,
 4;16,20,23,17;,
 4;23,22,18,17;,
 4;19,18,22,21;;
 
 MeshMaterialList {
  5;
  19;
  1,
  1,
  1,
  1,
  1,
  1,
  3,
  3,
  3,
  3,
  3,
  3,
  3,
  3,
  2,
  2,
  2,
  2,
  2;;
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
   0.251000;0.251000;0.251000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.062750;0.062750;0.062750;;
  }
 }
 MeshNormals {
  22;
  0.877802;0.130739;0.460838;,
  0.384810;-0.056460;0.921267;,
  -0.225469;-0.378481;0.897728;,
  -0.740045;-0.587749;0.326932;,
  -0.611697;-0.758180;0.225812;,
  0.877802;0.130739;-0.460838;,
  0.384810;-0.056460;-0.921267;,
  -0.225469;-0.378481;-0.897728;,
  -0.740045;-0.587749;-0.326932;,
  -0.611697;-0.758180;-0.225811;,
  -0.266356;-0.311252;0.912237;,
  -0.266356;-0.311252;-0.912237;,
  -0.195743;-0.980655;0.000000;,
  0.308818;-0.951121;0.000000;,
  0.677132;-0.735861;0.000000;,
  -0.094740;0.995502;0.000000;,
  0.198211;0.980159;0.000000;,
  0.395344;0.918533;0.000000;,
  0.313557;0.949569;0.000000;,
  -0.707616;0.706597;0.000000;,
  -0.768504;-0.639845;0.000000;,
  0.181014;-0.983481;0.000000;;
  19;
  4;1,0,0,1;,
  4;1,2,2,1;,
  4;2,3,4,2;,
  4;6,6,5,5;,
  4;6,6,7,7;,
  4;7,7,9,8;,
  4;3,8,9,4;,
  4;12,4,9,12;,
  4;13,13,12,12;,
  4;14,13,13,14;,
  4;0,0,5,5;,
  4;15,16,16,15;,
  4;16,17,17,16;,
  4;18,18,17,17;,
  4;10,10,10,10;,
  4;11,11,11,11;,
  4;19,19,19,19;,
  4;20,20,20,20;,
  4;21,21,21,21;;
 }
}
