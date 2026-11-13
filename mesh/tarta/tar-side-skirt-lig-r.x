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
 0.01172;-0.01202;0.10845;,
 -0.04859;-0.08607;0.14744;,
 -0.03604;-0.13383;0.15559;,
 0.01669;-0.14640;0.14178;,
 0.13120;-0.12162;0.06148;,
 0.12729;-0.30600;0.04400;,
 0.01172;-0.01202;-0.10274;,
 0.01669;-0.14640;-0.13607;,
 -0.03604;-0.13383;-0.14988;,
 -0.04859;-0.08607;-0.14173;,
 0.13120;-0.12162;-0.05577;,
 0.12729;-0.30600;-0.03828;,
 0.01853;-0.01840;0.09561;,
 0.11477;-0.10713;0.05358;,
 0.07168;0.00916;0.03319;,
 0.03887;0.02514;0.05474;,
 0.01853;-0.01840;-0.08990;,
 0.03887;0.02514;-0.04903;,
 0.07168;0.00916;-0.02748;,
 0.11477;-0.10713;-0.04787;;
 
 17;
 4;0,1,2,3;,
 3;4,3,5;,
 3;4,0,3;,
 4;6,7,8,9;,
 3;10,11,7;,
 3;10,7,6;,
 4;4,5,11,10;,
 4;0,6,9,1;,
 4;1,9,8,2;,
 4;3,2,8,7;,
 4;5,3,7,11;,
 4;0,4,10,6;,
 4;12,13,14,15;,
 4;16,17,18,19;,
 4;15,14,18,17;,
 4;18,14,13,19;,
 4;17,16,12,15;;
 
 MeshMaterialList {
  5;
  17;
  4,
  4,
  4,
  4,
  4,
  4,
  4,
  1,
  1,
  1,
  1,
  1,
  3,
  3,
  3,
  3,
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
   0.180720;0.180720;0.180720;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.062750;0.062750;0.062750;;
  }
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
   0.250000;0.000000;0.000000;;
  }
 }
 MeshNormals {
  26;
  0.300100;0.238147;0.923702;,
  0.480440;0.126666;0.867832;,
  0.416792;0.232342;0.878807;,
  0.889538;-0.061744;0.452670;,
  0.835245;0.254644;0.487363;,
  0.300100;0.238147;-0.923702;,
  0.480440;0.126666;-0.867832;,
  0.416792;0.232342;-0.878807;,
  0.889538;-0.061744;-0.452670;,
  0.835245;0.254644;-0.487363;,
  0.628495;0.355219;0.691963;,
  0.597171;0.702318;0.387475;,
  0.754218;0.602780;0.260408;,
  0.846206;0.379680;0.373869;,
  0.628495;0.355219;-0.691963;,
  0.597171;0.702318;-0.387475;,
  0.754218;0.602780;-0.260408;,
  0.846206;0.379680;-0.373869;,
  -0.775307;0.631585;0.000000;,
  -0.977333;0.211710;0.000000;,
  -0.967170;-0.254129;0.000000;,
  -0.564161;-0.825665;0.000000;,
  -0.231927;-0.972733;0.000000;,
  -0.821921;-0.569601;0.000000;,
  0.675989;0.736911;0.000000;,
  -0.905985;0.423310;0.000000;;
  17;
  4;2,0,0,1;,
  3;4,1,3;,
  3;4,2,1;,
  4;7,6,5,5;,
  3;9,8,6;,
  3;9,6,7;,
  4;4,3,8,9;,
  4;18,18,19,19;,
  4;19,19,20,20;,
  4;21,22,22,21;,
  4;23,21,21,23;,
  4;24,4,9,24;,
  4;10,13,12,11;,
  4;14,15,16,17;,
  4;11,12,16,15;,
  4;16,12,13,17;,
  4;25,25,25,25;;
 }
}
