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
 26;
 -0.42951;0.09671;0.17040;,
 -0.47577;-0.04811;0.17040;,
 -0.34303;-0.12453;0.17040;,
 -0.19620;0.16107;0.17040;,
 -0.30883;-0.44634;0.17040;,
 -0.25453;-0.47852;0.17040;,
 -0.21036;0.00620;0.17040;,
 -0.00915;0.00620;0.17040;,
 0.01901;0.05447;0.17040;,
 -0.42951;0.09671;-0.27267;,
 -0.19620;0.16107;-0.27267;,
 -0.34303;-0.12453;-0.27267;,
 -0.47577;-0.04811;-0.27267;,
 -0.25453;-0.47852;-0.27267;,
 -0.30883;-0.44634;-0.27267;,
 -0.21036;0.00620;-0.27267;,
 0.01901;0.05447;-0.27267;,
 -0.00915;0.00620;-0.27267;,
 -0.38546;-0.34880;0.09605;,
 -0.31530;-0.38501;0.09605;,
 -0.34303;-0.12453;0.09605;,
 -0.44248;-0.06722;0.09605;,
 -0.38546;-0.34880;-0.19833;,
 -0.44248;-0.06722;-0.19833;,
 -0.34303;-0.12453;-0.19833;,
 -0.31530;-0.38501;-0.19833;;
 
 19;
 4;0,1,2,3;,
 4;2,4,5,3;,
 4;6,7,8,3;,
 4;9,10,11,12;,
 4;11,10,13,14;,
 4;15,10,16,17;,
 4;0,9,12,1;,
 4;1,12,11,2;,
 4;2,11,14,4;,
 4;14,13,5,4;,
 4;3,10,9,0;,
 4;3,8,16,10;,
 4;8,7,17,16;,
 4;15,17,7,6;,
 4;5,13,15,6;,
 4;18,19,20,21;,
 4;22,23,24,25;,
 4;21,23,22,18;,
 4;22,25,19,18;;
 
 MeshMaterialList {
  5;
  19;
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
  1,
  1,
  2,
  2,
  2,
  2;;
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
  16;
  0.000000;0.000000;1.000000;,
  0.000000;0.000000;-1.000000;,
  -0.692812;0.721118;0.000000;,
  -0.952578;0.304295;0.000000;,
  -0.498962;-0.866624;0.000000;,
  -0.838036;-0.545615;0.000000;,
  -0.841442;-0.540348;0.000000;,
  -0.509794;-0.860296;0.000000;,
  0.095224;0.995456;0.000000;,
  0.443861;0.896096;0.000000;,
  0.863780;-0.503870;-0.000000;,
  0.000000;-1.000000;-0.000000;,
  0.995873;-0.090754;-0.000000;,
  -0.980106;-0.198476;0.000000;,
  -0.797828;-0.602884;0.000000;,
  -0.458562;-0.888662;0.000000;;
  19;
  4;0,0,0,0;,
  4;0,0,0,0;,
  4;0,0,0,0;,
  4;1,1,1,1;,
  4;1,1,1,1;,
  4;1,1,1,1;,
  4;2,2,3,3;,
  4;4,4,5,5;,
  4;5,5,6,6;,
  4;6,7,7,6;,
  4;8,8,2,2;,
  4;8,9,9,8;,
  4;10,10,10,10;,
  4;11,11,11,11;,
  4;12,12,12,12;,
  4;0,0,0,0;,
  4;1,1,1,1;,
  4;13,13,14,14;,
  4;14,15,15,14;;
 }
}
