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
 -0.11106;-0.17752;0.10367;,
 -0.10633;-0.25300;0.14514;,
 -0.00002;-0.25300;0.42069;,
 -0.00002;0.15601;0.26069;,
 0.11102;-0.17752;0.10367;,
 0.10629;-0.25300;0.14514;,
 -0.00002;0.40706;0.04399;,
 -0.05666;0.13794;-0.09101;,
 -0.03210;0.05254;-0.30451;,
 -0.03226;0.00465;-0.28456;,
 -0.03690;-0.02129;-0.22470;,
 -0.04665;-0.25300;-0.12284;,
 -0.05666;-0.25300;-0.04622;,
 0.05662;0.13794;-0.09101;,
 0.03686;-0.02129;-0.22470;,
 0.03222;0.00465;-0.28456;,
 0.03206;0.05254;-0.30451;,
 0.05662;-0.25300;-0.04622;,
 0.04661;-0.25300;-0.12284;;
 
 17;
 4;0,1,2,3;,
 4;4,3,2,5;,
 4;4,5,1,0;,
 3;5,2,1;,
 3;3,6,0;,
 3;6,3,4;,
 4;7,8,9,10;,
 4;10,11,12,7;,
 4;13,14,15,16;,
 4;14,13,17,18;,
 4;7,13,16,8;,
 4;16,15,9,8;,
 4;15,14,10,9;,
 4;10,14,18,11;,
 4;11,18,17,12;,
 4;13,7,12,17;,
 3;6,4,0;;
 
 MeshMaterialList {
  5;
  17;
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
  2,
  2,
  2,
  2,
  1,
  1;;
  Material {
   1.000000;0.000000;0.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.004800;0.268200;0.023400;;
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
   0.250000;0.234250;0.217750;;
  }
  Material {
   0.000000;1.000000;0.000000;1.000000;;
   5.000000;
   1.000000;1.000000;1.000000;;
   1.000000;0.251000;0.098000;;
  }
 }
 MeshNormals {
  22;
  -0.939068;0.172082;0.297556;,
  -0.923882;0.138731;0.356645;,
  0.939069;0.172079;0.297555;,
  0.923884;0.138724;0.356644;,
  -0.949713;0.204601;0.237029;,
  -0.993168;-0.027681;-0.113364;,
  -0.994411;-0.040472;-0.097512;,
  -0.991511;-0.014878;-0.129169;,
  0.993168;-0.027679;-0.113363;,
  0.994412;-0.040468;-0.097509;,
  0.991511;-0.014878;-0.129169;,
  -0.000000;-0.297462;-0.954734;,
  -0.000000;-0.481456;-0.876470;,
  0.000000;-1.000000;0.000000;,
  0.949713;0.204601;0.237029;,
  0.000000;0.928476;-0.371392;,
  -0.000000;-0.384587;-0.923089;,
  -0.000000;-0.702091;-0.712087;,
  -0.000000;-0.708960;-0.705248;,
  -0.000000;-0.402409;-0.915460;,
  0.000000;0.113825;0.993501;,
  0.000000;-0.101574;-0.994828;;
  17;
  4;0,1,1,0;,
  4;2,2,3,3;,
  4;11,12,12,11;,
  3;13,13,13;,
  3;0,4,0;,
  3;14,2,2;,
  4;5,6,6,5;,
  4;5,7,7,5;,
  4;8,8,9,9;,
  4;8,8,10,10;,
  4;15,15,15,15;,
  4;16,17,17,16;,
  4;17,18,18,17;,
  4;18,18,19,19;,
  4;13,13,13,13;,
  4;20,20,20,20;,
  3;21,11,11;;
 }
}
