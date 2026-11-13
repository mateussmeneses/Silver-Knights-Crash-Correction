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
 11;
 -0.15720;0.27673;0.28639;,
 0.00291;-0.00219;0.40107;,
 0.16303;0.27673;0.28639;,
 -0.15720;-0.28112;0.28639;,
 0.16303;-0.28112;0.28639;,
 0.28184;0.27673;0.24339;,
 -0.27601;0.27673;0.24339;,
 -0.27601;-0.28112;0.24339;,
 -0.27601;-0.00219;0.30018;,
 0.28184;-0.28112;0.24339;,
 0.28184;-0.00219;0.30018;;
 
 10;
 3;0,1,2;,
 3;3,4,1;,
 3;2,1,5;,
 3;6,1,0;,
 3;7,1,8;,
 3;9,10,1;,
 3;1,10,5;,
 3;4,9,1;,
 3;7,3,1;,
 3;6,8,1;;
 
 MeshMaterialList {
  1;
  10;
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0;;
  Material {
   1.000000;1.000000;1.000000;1.000000;;
   5.000000;
   0.000000;0.000000;0.000000;;
   0.250000;0.250000;0.250000;;
   TextureFilename {
    "emblem.bmp";
   }
  }
 }
 MeshNormals {
  11;
  0.334179;0.187934;0.923583;,
  0.340152;-0.000001;0.940371;,
  0.170334;0.289478;0.941907;,
  0.000000;-0.000001;1.000000;,
  -0.334179;0.187934;0.923583;,
  -0.340152;-0.000001;0.940371;,
  -0.170334;0.289478;0.941907;,
  0.334179;-0.187936;0.923583;,
  0.170334;-0.289480;0.941906;,
  -0.334179;-0.187936;0.923583;,
  -0.170334;-0.289480;0.941906;;
  10;
  3;6,3,2;,
  3;10,8,3;,
  3;2,3,0;,
  3;4,3,6;,
  3;9,3,5;,
  3;7,1,3;,
  3;3,1,0;,
  3;8,7,3;,
  3;9,10,3;,
  3;4,5,3;;
 }
 MeshTextureCoords {
  11;
  -0.212980;0.000000;
  -0.500000;0.500000;
  -0.787020;0.000000;
  -0.212980;1.000000;
  -0.787020;1.000000;
  -1.000000;0.000000;
  -0.000000;0.000000;
  -0.000000;1.000000;
  0.000000;0.500000;
  -1.000000;1.000000;
  -1.000000;0.500000;;
 }
}
