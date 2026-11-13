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
 -0.30665;-0.00068;0.14654;,
 -0.15333;0.26489;0.14654;,
 -0.22399;0.38729;0.00242;,
 -0.44798;-0.00068;0.00242;,
 0.15333;0.26489;0.14654;,
 0.22399;0.38729;0.00242;,
 0.30665;-0.00068;0.14654;,
 0.44798;-0.00068;0.00242;,
 0.15333;-0.26625;0.14654;,
 0.22399;-0.38865;0.00242;,
 -0.15332;-0.26625;0.14654;,
 -0.22399;-0.38865;0.00242;;
 
 12;
 4;0,1,2,3;,
 4;1,4,5,2;,
 4;4,6,7,5;,
 4;6,8,9,7;,
 4;8,10,11,9;,
 4;10,0,3,11;,
 3;4,8,6;,
 4;4,1,10,8;,
 3;1,0,10;,
 3;7,9,5;,
 4;9,11,2,5;,
 3;3,2,11;;
 
 MeshMaterialList {
  5;
  12;
  2,
  2,
  2,
  2,
  2,
  2,
  0,
  0,
  0,
  1,
  1,
  1;;
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
  16;
  -0.498683;-0.000001;0.866785;,
  -0.185976;0.322117;0.928253;,
  0.185976;0.322117;0.928253;,
  0.498684;-0.000001;0.866784;,
  0.185977;-0.322121;0.928251;,
  -0.185976;-0.322121;0.928252;,
  -0.713972;-0.000002;0.700175;,
  -0.356986;0.618313;0.700179;,
  0.356986;0.618313;0.700179;,
  0.713973;-0.000002;0.700173;,
  0.356987;-0.618319;0.700173;,
  -0.356986;-0.618319;0.700174;,
  -0.000002;0.000001;-1.000000;,
  -0.000001;0.000001;-1.000000;,
  0.000001;0.000001;-1.000000;,
  0.000002;0.000001;-1.000000;;
  12;
  4;0,1,7,6;,
  4;1,2,8,7;,
  4;2,3,9,8;,
  4;3,4,10,9;,
  4;4,5,11,10;,
  4;5,0,6,11;,
  3;2,4,3;,
  4;2,1,5,4;,
  3;1,0,5;,
  3;12,13,13;,
  4;13,14,14,13;,
  3;15,14,14;;
 }
}
