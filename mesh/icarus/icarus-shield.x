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
 9;
 0.00352;0.39063;0.28617;,
 0.31007;0.34281;0.01346;,
 0.00352;0.91040;0.01346;,
 0.00352;-0.23287;0.15154;,
 0.00352;-0.32743;0.18315;,
 0.17356;-0.22856;0.01346;,
 0.00352;-1.64865;0.01346;,
 -0.30302;0.34281;0.01346;,
 -0.16651;-0.22856;0.01346;;
 
 13;
 3;0,1,2;,
 3;0,3,1;,
 3;3,4,1;,
 3;4,5,1;,
 3;4,6,5;,
 3;0,2,7;,
 3;0,7,3;,
 3;3,7,4;,
 3;4,7,8;,
 3;4,8,6;,
 3;1,7,2;,
 4;1,5,8,7;,
 3;6,8,5;;
 
 MeshMaterialList {
  5;
  13;
  3,
  3,
  0,
  3,
  3,
  3,
  3,
  0,
  3,
  3,
  1,
  1,
  1;;
  Material {
   0.000000;1.000000;0.000000;1.000000;;
   9.000000;
   1.000000;1.000000;1.000000;;
   0.145000;1.000000;0.337000;;
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
   1.000000;0.000000;0.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.112750;0.020500;0.232250;;
  }
  Material {
   1.000000;1.000000;1.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.241250;0.241250;0.250000;;
  }
 }
 MeshNormals {
  16;
  0.652156;0.352219;0.671293;,
  0.527510;0.091516;0.844606;,
  0.669981;0.098565;0.735806;,
  0.000001;0.089109;0.996022;,
  -0.416914;0.101840;0.903223;,
  0.737762;-0.132788;0.661872;,
  0.728665;-0.087247;0.679291;,
  -0.527509;0.091515;0.844606;,
  -0.737764;-0.132790;0.661869;,
  -0.669980;0.098565;0.735807;,
  -0.652155;0.352219;0.671294;,
  -0.728667;-0.087246;0.679289;,
  -0.000001;0.000000;-1.000000;,
  -0.000002;-0.000001;-1.000000;,
  -0.000000;0.000001;-1.000000;,
  -0.000000;0.000000;-1.000000;;
  13;
  3;2,1,0;,
  3;2,3,1;,
  3;3,4,1;,
  3;5,5,1;,
  3;5,6,5;,
  3;9,10,7;,
  3;9,7,3;,
  3;3,7,4;,
  3;4,7,8;,
  3;4,8,11;,
  3;12,12,13;,
  4;12,14,14,12;,
  3;15,14,14;;
 }
}
