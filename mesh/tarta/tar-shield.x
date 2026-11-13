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
 20;
 0.48330;-0.00219;0.22392;,
 0.24310;-0.41822;0.22392;,
 0.33841;-0.58328;0.01750;,
 0.67390;-0.00219;0.01750;,
 -0.23728;-0.41822;0.22392;,
 -0.33258;-0.58328;0.01750;,
 -0.47747;-0.00219;0.22392;,
 -0.66808;-0.00219;0.01750;,
 -0.23728;0.41383;0.22392;,
 -0.33258;0.57890;0.01750;,
 0.24310;0.41383;0.22392;,
 0.33841;0.57890;0.01750;,
 0.48330;-0.00219;0.22392;,
 0.67390;-0.00219;0.01750;,
 0.00291;-0.00219;0.39688;,
 0.00291;-0.00219;0.39688;,
 0.00291;-0.00219;0.39688;,
 0.00291;-0.00219;0.39688;,
 0.00291;-0.00219;0.39688;,
 0.00291;-0.00219;0.39688;;
 
 15;
 4;0,1,2,3;,
 4;1,4,5,2;,
 4;4,6,7,5;,
 4;6,8,9,7;,
 4;8,10,11,9;,
 4;10,12,13,11;,
 3;14,1,0;,
 3;15,4,1;,
 3;16,6,4;,
 3;17,8,6;,
 3;18,10,8;,
 3;19,12,10;,
 3;9,5,7;,
 4;11,2,5,9;,
 3;3,2,11;;
 
 MeshMaterialList {
  5;
  15;
  4,
  4,
  4,
  4,
  4,
  4,
  3,
  3,
  3,
  3,
  3,
  3,
  1,
  1,
  1;;
  Material {
   0.000000;1.000000;0.000000;1.000000;;
   9.000000;
   1.000000;1.000000;1.000000;;
   1.000000;0.624000;0.275000;;
  }
  Material {
   0.050000;0.050000;0.050000;1.000000;;
   5.000000;
   0.000000;0.000000;0.000000;;
   0.012750;0.012750;0.012750;;
  }
  Material {
   0.250000;0.250000;0.250000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.062750;0.062750;0.062750;;
  }
  Material {
   1.000000;1.000000;1.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.237250;0.237250;0.237250;;
  }
  Material {
   1.000000;0.000000;0.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.086250;0.075500;0.250000;;
  }
 }
 MeshNormals {
  14;
  0.000000;-0.000001;1.000000;,
  0.546005;-0.000001;0.837782;,
  0.273003;-0.472855;0.837781;,
  -0.273002;-0.472855;0.837782;,
  -0.546004;-0.000001;0.837783;,
  -0.273002;0.472853;0.837783;,
  0.273002;0.472852;0.837783;,
  0.734696;-0.000001;0.678396;,
  0.367348;-0.636266;0.678396;,
  -0.367347;-0.636266;0.678397;,
  -0.734694;-0.000001;0.678399;,
  -0.367347;0.636263;0.678400;,
  0.367348;0.636263;0.678399;,
  0.000000;0.000000;-1.000000;;
  15;
  4;1,2,8,7;,
  4;2,3,9,8;,
  4;3,4,10,9;,
  4;4,5,11,10;,
  4;5,6,12,11;,
  4;6,1,7,12;,
  3;0,2,1;,
  3;0,3,2;,
  3;0,4,3;,
  3;0,5,4;,
  3;0,6,5;,
  3;0,1,6;,
  3;13,13,13;,
  4;13,13,13,13;,
  3;13,13,13;;
 }
 MeshTextureCoords {
  20;
  0.000000;0.000000;
  0.166670;0.000000;
  0.166670;1.000000;
  0.000000;1.000000;
  0.333330;0.000000;
  0.333330;1.000000;
  0.500000;0.000000;
  0.500000;1.000000;
  0.666670;0.000000;
  0.666670;1.000000;
  0.833330;0.000000;
  0.833330;1.000000;
  1.000000;0.000000;
  1.000000;1.000000;
  0.083330;0.000000;
  0.250000;0.000000;
  0.416670;0.000000;
  0.583330;0.000000;
  0.750000;0.000000;
  0.916670;0.000000;;
 }
}
