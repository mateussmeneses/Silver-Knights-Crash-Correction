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
 -0.47480;0.00131;-0.00198;,
 -0.47480;0.04966;-0.18894;,
 -0.58977;-0.16496;-0.27829;,
 -0.61236;-0.26176;-0.07001;,
 -0.44142;-0.36557;-0.36180;,
 -0.45743;-0.48296;-0.12722;,
 -0.19050;-0.22464;-0.30313;,
 -0.19050;-0.32103;-0.08534;,
 -0.19050;0.01143;-0.20485;,
 -0.19050;-0.03839;-0.01225;,
 0.47480;0.00131;-0.00198;,
 0.61236;-0.26176;-0.07001;,
 0.58977;-0.16496;-0.27829;,
 0.47480;0.04966;-0.18894;,
 0.45743;-0.48296;-0.12722;,
 0.44142;-0.36557;-0.36180;,
 0.19050;-0.22464;-0.30313;,
 0.19050;-0.32103;-0.08534;,
 0.19050;0.01143;-0.20485;,
 0.19050;-0.03839;-0.01225;;
 
 18;
 4;0,1,2,3;,
 4;3,2,4,5;,
 4;6,7,5,4;,
 3;6,4,2;,
 4;1,8,6,2;,
 4;1,0,9,8;,
 4;8,9,7,6;,
 3;3,5,7;,
 4;3,7,9,0;,
 4;10,11,12,13;,
 4;11,14,15,12;,
 4;16,15,14,17;,
 3;16,12,15;,
 4;13,12,16,18;,
 4;13,18,19,10;,
 4;18,16,17,19;,
 3;11,17,14;,
 4;11,10,19,17;;
 
 MeshMaterialList {
  5;
  18;
  4,
  4,
  4,
  4,
  4,
  4,
  4,
  1,
  1,
  4,
  4,
  4,
  4,
  4,
  4,
  4,
  1,
  1;;
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
  24;
  -0.893390;0.435730;0.109517;,
  -0.818603;-0.485533;-0.306833;,
  0.142736;0.958235;0.247815;,
  0.000002;0.384340;-0.923192;,
  0.872481;-0.445887;-0.199904;,
  0.893390;0.435730;0.109517;,
  0.818603;-0.485533;-0.306833;,
  -0.142736;0.958235;0.247815;,
  -0.000002;0.384340;-0.923192;,
  -0.872481;-0.445887;-0.199904;,
  0.522447;-0.778056;-0.348824;,
  0.000002;0.384329;-0.923196;,
  0.000002;0.384318;-0.923201;,
  1.000000;0.000000;0.000000;,
  0.000000;-0.250382;0.968147;,
  0.000000;-0.250384;0.968147;,
  -0.000000;-0.250380;0.968148;,
  -0.522447;-0.778056;-0.348824;,
  -0.000002;0.384329;-0.923196;,
  -0.000002;0.384318;-0.923201;,
  -1.000000;0.000000;0.000000;,
  -0.000000;-0.250382;0.968147;,
  -0.000000;-0.250384;0.968147;,
  0.000000;-0.250380;0.968148;;
  18;
  4;0,0,0,0;,
  4;1,1,1,1;,
  4;4,4,10,10;,
  3;11,12,11;,
  4;3,3,11,11;,
  4;2,2,2,2;,
  4;13,13,4,4;,
  3;14,15,14;,
  4;14,14,16,16;,
  4;5,5,5,5;,
  4;6,6,6,6;,
  4;9,17,17,9;,
  3;18,18,19;,
  4;8,18,18,8;,
  4;7,7,7,7;,
  4;20,9,9,20;,
  3;21,21,22;,
  4;21,23,23,21;;
 }
}
