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
 19;
 0.10594;0.03093;0.05323;,
 0.12286;-0.00002;-0.00041;,
 0.10678;0.11098;-0.00006;,
 0.08872;0.15455;0.05096;,
 0.00000;-0.07083;0.10925;,
 0.00000;-0.11342;0.06779;,
 -0.10594;0.03093;0.05323;,
 -0.08872;0.15455;0.05096;,
 -0.10678;0.11098;-0.00006;,
 -0.12286;-0.00002;-0.00041;,
 0.05656;0.05418;0.13018;,
 0.09175;0.03093;0.05323;,
 0.07718;0.15455;0.05096;,
 0.05232;0.19502;0.09803;,
 0.00000;-0.05457;0.09988;,
 -0.05656;0.05418;0.13017;,
 -0.05232;0.19502;0.09803;,
 -0.07718;0.15455;0.05096;,
 -0.09175;0.03093;0.05323;;
 
 16;
 4;0,1,2,3;,
 4;0,4,5,1;,
 4;6,7,8,9;,
 4;6,9,5,4;,
 3;5,9,1;,
 3;0,6,4;,
 4;3,7,6,0;,
 4;3,2,8,7;,
 4;10,11,12,13;,
 3;10,14,11;,
 4;15,16,17,18;,
 3;15,18,14;,
 3;10,15,14;,
 4;10,13,16,15;,
 4;13,12,17,16;,
 4;8,2,1,9;;
 
 MeshMaterialList {
  5;
  16;
  2,
  2,
  2,
  2,
  1,
  1,
  1,
  1,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  1;;
  Material {
   0.000000;1.000000;0.000000;1.000000;;
   9.000000;
   1.000000;1.000000;1.000000;;
   1.000000;0.624000;0.275000;;
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
   0.162750;0.009750;0.005000;;
  }
  Material {
   1.000000;1.000000;1.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.048000;0.080500;0.144000;;
  }
 }
 MeshNormals {
  22;
  0.964745;0.138760;0.223635;,
  0.903710;-0.182472;0.387315;,
  0.721843;-0.479306;0.499209;,
  -0.964745;0.138760;0.223635;,
  -0.903709;-0.182471;0.387318;,
  0.915959;0.115216;0.384375;,
  0.864449;-0.207141;0.458062;,
  0.400485;-0.433216;0.807426;,
  -0.915960;0.115213;0.384375;,
  -0.864449;-0.207140;0.458061;,
  -0.721841;-0.479303;0.499214;,
  -0.000002;-0.515422;-0.856936;,
  -0.000002;-0.265900;-0.964001;,
  0.000001;0.257850;0.966185;,
  0.000000;0.482260;0.876028;,
  0.000002;0.018359;0.999831;,
  -0.000003;0.760482;-0.649358;,
  -0.000002;0.420177;-0.907442;,
  -0.716125;-0.506295;0.480448;,
  -0.000004;-0.023624;0.999721;,
  0.000000;0.222540;0.974924;,
  -0.000004;0.758205;-0.652016;;
  16;
  4;1,1,0,0;,
  4;1,2,2,1;,
  4;4,3,3,4;,
  4;4,4,10,10;,
  3;11,12,12;,
  3;13,13,14;,
  4;15,15,13,13;,
  4;16,17,17,16;,
  4;6,6,5,5;,
  3;6,7,6;,
  4;9,8,8,9;,
  3;9,9,18;,
  3;19,19,7;,
  4;19,20,20,19;,
  4;21,21,21,21;,
  4;17,17,12,12;;
 }
}
