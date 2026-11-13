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
 0.09218;0.64842;0.04593;,
 -0.09218;0.64842;0.04593;,
 -0.09218;0.01279;0.26433;,
 0.09218;0.01279;0.26433;,
 -0.09218;-0.95603;0.09772;,
 0.09218;-0.95603;0.09772;,
 -0.13399;-1.11827;-0.19108;,
 0.13399;-1.11827;-0.19108;,
 -0.13399;0.36799;-0.19108;,
 0.13399;0.36799;-0.19108;,
 0.19969;0.01141;-0.19107;,
 -0.19969;0.01141;-0.19107;,
 -0.19969;0.19902;-0.00346;,
 0.19969;0.19902;-0.00346;,
 -0.19969;0.01141;0.18415;,
 0.19969;0.01141;0.18415;,
 -0.19969;-0.17620;-0.00346;,
 0.19969;-0.17620;-0.00346;;
 
 15;
 4;0,1,2,3;,
 4;3,2,4,5;,
 4;5,4,6,7;,
 4;7,6,8,9;,
 4;8,6,4,2;,
 4;7,9,3,5;,
 3;1,8,2;,
 4;1,0,9,8;,
 3;3,9,0;,
 4;10,11,12,13;,
 4;13,12,14,15;,
 4;15,14,16,17;,
 4;17,16,11,10;,
 4;11,16,14,12;,
 4;17,10,13,15;;
 
 MeshMaterialList {
  5;
  15;
  4,
  1,
  1,
  1,
  4,
  4,
  4,
  1,
  4,
  2,
  2,
  2,
  2,
  2,
  2;;
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
  19;
  0.000000;0.324944;0.945733;,
  0.000000;0.080238;0.996776;,
  0.000000;-0.576660;0.816984;,
  0.000000;-0.871849;0.489775;,
  0.000000;0.343689;-0.939084;,
  0.000000;0.707105;-0.707109;,
  0.000000;0.707103;0.707111;,
  0.000000;-0.707109;0.707105;,
  0.000000;0.000000;-1.000000;,
  -0.992825;0.017897;0.118233;,
  -0.993679;-0.006941;0.112047;,
  0.993679;-0.006941;0.112047;,
  0.992825;0.017897;0.118233;,
  -0.991319;0.042723;0.124342;,
  0.000000;0.645505;-0.763756;,
  0.991319;0.042723;0.124342;,
  0.000000;-0.707111;-0.707103;,
  -1.000000;0.000000;0.000000;,
  1.000000;0.000000;0.000000;;
  15;
  4;0,0,1,1;,
  4;1,1,2,2;,
  4;2,2,3,3;,
  4;8,8,4,4;,
  4;9,10,10,9;,
  4;11,12,12,11;,
  3;13,9,9;,
  4;14,14,4,4;,
  3;12,12,15;,
  4;5,5,5,5;,
  4;6,6,6,6;,
  4;7,7,7,7;,
  4;16,16,16,16;,
  4;17,17,17,17;,
  4;18,18,18,18;;
 }
}
