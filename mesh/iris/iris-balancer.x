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
 16;
 -0.02827;-0.25357;-0.25122;,
 -0.02827;-0.04645;-0.14479;,
 -0.01272;-0.88497;-0.83308;,
 -0.01570;-0.83959;-0.76104;,
 -0.01268;-1.03733;-0.90586;,
 -0.01563;-0.90328;-0.79019;,
 -0.02907;-0.16644;-0.09436;,
 -0.02827;0.04949;0.05552;,
 0.02817;-0.25357;-0.25122;,
 0.01560;-0.83959;-0.76104;,
 0.01263;-0.88497;-0.83308;,
 0.02817;-0.04645;-0.14479;,
 0.01554;-0.90328;-0.79019;,
 0.01258;-1.03733;-0.90586;,
 0.02817;0.04949;0.05552;,
 0.02897;-0.16644;-0.09436;;
 
 14;
 4;0,1,2,3;,
 4;2,4,5,3;,
 4;0,6,7,1;,
 4;8,9,10,11;,
 4;10,9,12,13;,
 4;8,11,14,15;,
 4;1,11,10,2;,
 4;10,13,4,2;,
 4;11,1,7,14;,
 4;4,13,12,5;,
 4;12,9,3,5;,
 4;8,0,3,9;,
 4;15,6,0,8;,
 4;14,7,6,15;;
 
 MeshMaterialList {
  5;
  14;
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  3,
  3,
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
  18;
  -0.999300;0.017979;-0.032800;,
  -0.997867;0.028595;-0.058677;,
  -0.998056;0.025876;-0.056701;,
  -0.999977;0.004626;-0.004916;,
  0.999301;0.017966;-0.032785;,
  0.997870;0.028574;-0.058646;,
  0.998059;0.025855;-0.056663;,
  0.999977;0.004620;-0.004910;,
  0.000000;0.786866;-0.617124;,
  0.000000;0.536673;-0.843790;,
  0.000000;0.431051;-0.902327;,
  0.000000;0.901882;-0.431983;,
  0.000000;-0.653294;0.757105;,
  0.000000;-0.540161;0.841561;,
  0.000000;-0.541862;0.840467;,
  0.000000;-0.776996;0.629506;,
  0.000000;-0.741478;0.670977;,
  0.000000;-0.570204;0.821503;;
  14;
  4;0,0,1,1;,
  4;1,2,2,1;,
  4;0,3,3,0;,
  4;4,5,5,4;,
  4;5,5,6,6;,
  4;4,4,7,7;,
  4;8,8,9,9;,
  4;9,10,10,9;,
  4;8,8,11,11;,
  4;12,12,13,13;,
  4;13,14,14,13;,
  4;15,15,14,14;,
  4;16,16,15,15;,
  4;17,17,16,16;;
 }
}
