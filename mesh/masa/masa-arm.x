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
 22;
 0.05009;-0.06538;0.05020;,
 -0.05023;-0.06538;0.05020;,
 -0.06739;-0.20483;0.06736;,
 0.06726;-0.20483;0.06736;,
 -0.05023;-0.34428;0.05020;,
 0.05009;-0.34428;0.05020;,
 0.05009;-0.34428;-0.05012;,
 -0.05023;-0.34428;-0.05012;,
 -0.06739;-0.20483;-0.06729;,
 0.06726;-0.20483;-0.06729;,
 -0.05023;-0.06538;-0.05012;,
 0.05009;-0.06538;-0.05012;,
 -0.05658;-0.34428;0.05858;,
 -0.05658;-0.34428;-0.05851;,
 -0.05658;-0.48165;-0.08531;,
 -0.05658;-0.48161;0.08864;,
 -0.05658;-0.53841;0.00004;,
 0.05645;-0.34428;0.05858;,
 0.05645;-0.48161;0.08864;,
 0.05645;-0.48165;-0.08531;,
 0.05645;-0.34428;-0.05851;,
 0.05645;-0.53841;0.00004;;
 
 17;
 4;0,1,2,3;,
 4;3,2,4,5;,
 4;6,7,8,9;,
 4;9,8,10,11;,
 4;10,8,2,1;,
 4;8,7,4,2;,
 4;6,9,3,5;,
 4;9,11,0,3;,
 4;12,13,14,15;,
 3;14,16,15;,
 4;17,18,19,20;,
 3;19,18,21;,
 4;20,13,12,17;,
 4;17,12,15,18;,
 4;15,16,21,18;,
 4;14,19,21,16;,
 4;14,13,20,19;;
 
 MeshMaterialList {
  5;
  17;
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
  1,
  2,
  2,
  2,
  2;;
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
   0.180720;0.180720;0.180720;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.062750;0.062750;0.062750;;
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
  21;
  0.000000;0.122152;-0.992511;,
  0.000000;0.122152;0.992511;,
  0.000000;0.000000;1.000000;,
  0.000000;-0.122151;0.992512;,
  -0.000000;-0.122151;-0.992512;,
  0.000000;0.000000;-1.000000;,
  -1.000000;0.000000;0.000000;,
  -1.000000;0.000000;0.000000;,
  1.000000;0.000000;0.000000;,
  1.000000;0.000000;0.000000;,
  -0.992511;0.122152;0.000000;,
  -1.000000;0.000000;0.000000;,
  -0.992512;-0.122151;0.000000;,
  0.992512;-0.122151;0.000000;,
  1.000000;0.000000;0.000000;,
  0.992511;0.122152;0.000000;,
  0.000000;1.000000;0.000000;,
  0.000000;0.213765;0.976885;,
  0.000000;-0.841861;0.539694;,
  -0.000000;-0.832704;-0.553718;,
  0.000000;0.191500;-0.981493;;
  17;
  4;1,1,2,2;,
  4;2,2,3,3;,
  4;4,4,5,5;,
  4;5,5,0,0;,
  4;10,11,11,10;,
  4;11,12,12,11;,
  4;13,14,14,13;,
  4;14,15,15,14;,
  4;6,6,6,6;,
  3;6,7,6;,
  4;8,8,8,8;,
  3;8,8,9;,
  4;16,16,16,16;,
  4;17,17,17,17;,
  4;18,18,18,18;,
  4;19,19,19,19;,
  4;20,20,20,20;;
 }
}
