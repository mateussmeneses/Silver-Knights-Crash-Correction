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
 -0.15634;0.05607;0.12023;,
 -0.15634;-0.11273;0.12023;,
 0.01246;-0.11273;0.12023;,
 0.01246;0.05607;0.12023;,
 0.01246;0.08983;0.08647;,
 -0.15634;0.08983;0.08647;,
 -0.19011;0.05607;0.08647;,
 -0.19011;-0.11273;0.08647;,
 -0.15634;0.05607;-0.11610;,
 0.01246;0.05607;-0.11610;,
 0.01246;-0.11273;-0.11610;,
 -0.15634;-0.11273;-0.11610;,
 -0.15634;0.08983;-0.08234;,
 0.01246;0.08983;-0.08234;,
 -0.19011;-0.11273;-0.08234;,
 -0.19011;0.05607;-0.08234;;
 
 15;
 4;0,1,2,3;,
 4;3,4,5,0;,
 4;0,6,7,1;,
 3;6,0,5;,
 4;8,9,10,11;,
 4;9,8,12,13;,
 4;8,11,14,15;,
 3;15,12,8;,
 4;4,13,12,5;,
 4;12,15,6,5;,
 4;14,7,6,15;,
 4;13,4,3,9;,
 4;3,2,10,9;,
 4;1,11,10,2;,
 4;7,14,11,1;;
 
 MeshMaterialList {
  5;
  15;
  2,
  2,
  2,
  2,
  2,
  2,
  2,
  2,
  2,
  2,
  2,
  1,
  1,
  1,
  1;;
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
   0.180706;0.180706;0.180706;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.062745;0.062745;0.062745;;
  }
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
 }
 MeshNormals {
  18;
  0.000000;0.382683;0.923880;,
  0.000000;0.000000;1.000000;,
  -0.382677;0.000000;0.923882;,
  -0.366994;0.367002;0.854766;,
  0.000000;0.923880;0.382683;,
  -0.366994;0.854766;0.367002;,
  -0.854758;0.367007;0.367007;,
  -0.923877;0.000000;0.382690;,
  0.000000;0.382683;-0.923880;,
  0.000000;0.000000;-1.000000;,
  -0.382677;0.000000;-0.923882;,
  -0.366994;0.367002;-0.854766;,
  0.000000;0.923880;-0.382683;,
  -0.366994;0.854766;-0.367002;,
  -0.854758;0.367007;-0.367007;,
  -0.923877;0.000000;-0.382690;,
  1.000000;0.000000;0.000000;,
  0.000000;-1.000000;0.000000;;
  15;
  4;3,2,1,0;,
  4;0,4,5,3;,
  4;3,6,7,2;,
  3;6,3,5;,
  4;11,8,9,10;,
  4;8,11,13,12;,
  4;11,10,15,14;,
  3;14,13,11;,
  4;4,12,13,5;,
  4;13,14,6,5;,
  4;15,7,6,14;,
  4;16,16,16,16;,
  4;16,16,16,16;,
  4;17,17,17,17;,
  4;17,17,17,17;;
 }
}
