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
 24;
 -0.00000;-0.02261;0.16220;,
 0.01023;-0.00495;0.16358;,
 0.01709;0.00511;0.08633;,
 -0.00000;-0.02441;0.08400;,
 -0.01023;-0.00495;0.16358;,
 -0.01709;0.00511;0.08633;,
 0.02045;0.00705;0.08648;,
 0.03018;0.01929;0.00257;,
 -0.00000;-0.03283;-0.00154;,
 -0.00000;-0.02827;0.08370;,
 -0.02046;0.00705;0.08648;,
 -0.03018;0.01929;0.00256;,
 0.00970;-0.02742;-0.01698;,
 -0.00000;-0.05849;0.01424;,
 -0.00000;-0.03641;0.11789;,
 -0.00970;-0.02742;-0.01698;,
 -0.03141;0.01006;-0.01404;,
 -0.05126;0.03002;0.02121;,
 -0.02516;0.00703;0.12131;,
 -0.02170;0.02681;-0.01271;,
 0.03141;0.01006;-0.01404;,
 0.02516;0.00703;0.12131;,
 0.05126;0.03002;0.02121;,
 0.02170;0.02681;-0.01271;;
 
 21;
 4;3,2,1,0;,
 4;2,5,4,1;,
 4;5,3,0,4;,
 3;4,0,1;,
 4;9,8,7,6;,
 4;6,7,11,10;,
 4;10,11,8,9;,
 3;10,9,6;,
 3;11,7,8;,
 3;14,13,12;,
 3;13,14,15;,
 3;13,15,12;,
 3;14,12,15;,
 3;18,17,16;,
 3;17,18,19;,
 3;17,19,16;,
 3;18,16,19;,
 3;22,21,20;,
 3;21,22,23;,
 3;23,22,20;,
 3;20,21,23;;
 
 MeshMaterialList {
  5;
  21;
  4,
  4,
  4,
  0,
  3,
  3,
  3,
  1,
  3,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
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
  21;
  0.864882;-0.501842;0.011548;,
  0.000000;0.991632;0.129098;,
  0.864110;-0.502582;0.026917;,
  0.000001;0.989539;0.144267;,
  0.967113;-0.248765;0.052989;,
  -0.967126;-0.248717;0.052979;,
  -0.694702;-0.719121;0.015960;,
  0.272406;0.950825;0.147402;,
  0.694702;-0.719121;0.015960;,
  -0.272401;0.950826;0.147405;,
  -0.864916;-0.501784;0.011555;,
  -0.000000;-0.078363;0.996925;,
  -0.864127;-0.502554;0.026912;,
  0.000024;-0.078454;0.996918;,
  0.000016;0.078452;-0.996918;,
  0.000000;-0.708784;-0.705425;,
  0.000000;0.997782;0.066560;,
  -0.659881;0.430673;-0.615693;,
  0.865985;-0.497448;-0.051141;,
  0.659860;0.430701;-0.615696;,
  -0.865963;-0.497486;-0.051141;;
  21;
  4;0,0,0,0;,
  4;1,1,1,1;,
  4;10,10,10,10;,
  3;11,11,11;,
  4;2,2,2,2;,
  4;3,3,3,3;,
  4;12,12,12,12;,
  3;13,13,13;,
  3;14,14,14;,
  3;4,4,4;,
  3;5,5,5;,
  3;15,15,15;,
  3;16,16,16;,
  3;6,6,6;,
  3;7,7,7;,
  3;17,17,17;,
  3;18,18,18;,
  3;8,8,8;,
  3;9,9,9;,
  3;19,19,19;,
  3;20,20,20;;
 }
}
