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
 -0.13029;0.00000;0.18438;,
 -0.13029;-0.15967;0.09219;,
 0.00000;-0.32909;0.19000;,
 0.00000;0.00000;0.38000;,
 -0.13029;-0.15967;-0.09219;,
 0.00000;-0.32909;-0.19000;,
 -0.13029;0.00000;-0.18438;,
 0.00000;0.00000;-0.38000;,
 0.13029;0.00000;0.18438;,
 0.13029;-0.15967;0.09219;,
 0.13029;-0.15967;-0.09219;,
 0.13029;0.00000;-0.18438;,
 0.00000;0.32909;0.19000;,
 -0.13029;0.15967;0.09219;,
 0.00000;0.32909;-0.19000;,
 -0.13029;0.15967;-0.09219;,
 0.13029;0.15967;0.09219;,
 0.13029;0.15967;-0.09219;;
 
 16;
 4;0,1,2,3;,
 4;1,4,5,2;,
 4;4,6,7,5;,
 4;8,3,2,9;,
 4;9,2,5,10;,
 4;10,5,7,11;,
 4;6,4,1,0;,
 4;11,8,9,10;,
 4;0,3,12,13;,
 4;13,12,14,15;,
 4;15,14,7,6;,
 4;8,16,12,3;,
 4;16,17,14,12;,
 4;17,11,7,14;,
 4;6,0,13,15;,
 4;11,17,16,8;;
 
 MeshMaterialList {
  5;
  16;
  1,
  1,
  1,
  1,
  1,
  1,
  3,
  3,
  1,
  1,
  1,
  1,
  1,
  1,
  3,
  3;;
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
  24;
  -0.959266;0.000000;0.282505;,
  -0.925767;-0.327440;0.189047;,
  -0.925767;-0.327440;-0.189047;,
  -0.959266;0.000000;-0.282506;,
  -0.832297;0.000000;0.554329;,
  -0.832297;-0.480065;0.277164;,
  -0.832297;-0.480064;-0.277165;,
  -0.832297;0.000000;-0.554330;,
  0.959266;0.000000;0.282505;,
  0.925767;-0.327440;0.189047;,
  0.925767;-0.327440;-0.189047;,
  0.959266;0.000000;-0.282506;,
  -0.925767;0.327440;0.189047;,
  -0.925767;0.327440;-0.189047;,
  -0.832297;0.480065;0.277164;,
  -0.832297;0.480064;-0.277165;,
  0.925767;0.327440;0.189047;,
  0.925767;0.327440;-0.189047;,
  0.832297;0.000000;0.554329;,
  0.832297;-0.480065;0.277164;,
  0.832297;-0.480064;-0.277165;,
  0.832297;0.000000;-0.554330;,
  0.832297;0.480065;0.277164;,
  0.832297;0.480064;-0.277165;;
  16;
  4;0,1,5,4;,
  4;1,2,6,5;,
  4;2,3,7,6;,
  4;8,18,19,9;,
  4;9,19,20,10;,
  4;10,20,21,11;,
  4;3,2,1,0;,
  4;11,8,9,10;,
  4;0,4,14,12;,
  4;12,14,15,13;,
  4;13,15,7,3;,
  4;8,16,22,18;,
  4;16,17,23,22;,
  4;17,11,21,23;,
  4;3,0,12,13;,
  4;11,17,16,8;;
 }
}
