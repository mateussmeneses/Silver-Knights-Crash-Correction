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
 0.37161;-0.12691;0.00390;,
 0.57703;0.66474;0.00390;,
 0.32605;0.34013;0.05574;,
 0.32605;0.34013;-0.04794;,
 0.32605;0.34013;0.08234;,
 -0.08469;-0.00208;0.11567;,
 0.05068;-0.13893;0.06492;,
 0.32605;0.34013;-0.07455;,
 0.05068;-0.13893;-0.05713;,
 -0.08469;-0.00208;-0.10787;,
 0.21395;-0.55386;-0.05090;,
 0.11116;-0.73501;-0.04536;,
 0.11116;-0.73501;0.05314;,
 0.21395;-0.55386;0.05868;,
 0.25533;-2.43499;0.00390;,
 0.09212;-0.08575;0.06052;,
 0.09212;-0.08575;-0.05273;,
 0.38290;-0.20201;0.00390;,
 0.32605;0.34013;0.06473;,
 0.32605;0.34013;-0.05693;;
 
 19;
 3;0,1,2;,
 3;0,3,1;,
 3;1,3,2;,
 3;2,3,0;,
 3;4,5,6;,
 3;7,8,9;,
 4;7,9,5,4;,
 4;5,9,8,6;,
 4;7,10,11,8;,
 4;4,6,12,13;,
 4;7,4,13,10;,
 4;10,13,12,11;,
 4;6,8,11,12;,
 3;14,15,16;,
 3;14,17,18;,
 3;18,15,14;,
 3;19,17,14;,
 3;14,16,19;,
 3;19,18,17;;
 
 MeshMaterialList {
  5;
  19;
  0,
  0,
  0,
  1,
  4,
  4,
  1,
  1,
  4,
  4,
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
   0.250000;0.250000;0.250000;1.000000;;
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
  0.295982;-0.076802;0.952101;,
  0.295982;-0.076802;-0.952101;,
  0.094598;-0.089005;0.991529;,
  0.206652;-0.153927;0.966231;,
  0.094571;-0.088988;-0.991533;,
  0.206615;-0.153904;-0.966242;,
  -0.019120;-0.022524;-0.999564;,
  -0.019103;-0.022534;0.999564;,
  0.884501;0.040603;0.464768;,
  -0.997595;-0.069309;0.000000;,
  0.309067;-0.028713;0.950607;,
  0.309067;-0.028712;-0.950607;,
  -0.791110;0.611674;0.000000;,
  -0.960927;0.276801;0.000000;,
  -0.995275;-0.097096;0.000000;,
  -0.640109;0.768284;0.000000;,
  -0.710914;-0.703279;0.000000;,
  -0.904514;-0.426444;0.000000;,
  0.992230;-0.124418;-0.000000;,
  0.949100;-0.314975;-0.000000;,
  0.869741;-0.493508;-0.000000;,
  -0.994892;-0.100943;0.000000;,
  0.022995;-0.022494;0.999482;,
  0.569089;-0.032511;-0.821633;,
  0.023003;-0.022494;-0.999482;,
  0.994547;0.104290;0.000000;;
  19;
  3;0,0,0;,
  3;1,1,1;,
  3;12,13,13;,
  3;13,13,14;,
  3;2,3,2;,
  3;4,4,5;,
  4;15,15,15,15;,
  4;16,16,17,17;,
  4;4,6,6,4;,
  4;2,2,7,7;,
  4;18,18,19,19;,
  4;19,19,20,20;,
  4;17,17,21,21;,
  3;9,9,9;,
  3;10,8,10;,
  3;10,22,10;,
  3;11,23,11;,
  3;11,24,11;,
  3;25,25,8;;
 }
}
