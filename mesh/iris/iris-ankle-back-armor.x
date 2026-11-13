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
 10;
 -0.05034;-0.02798;-0.09082;,
 -0.03963;-0.20108;-0.04371;,
 -0.05370;-0.20108;0.02736;,
 -0.07207;-0.08598;0.05204;,
 -0.05452;0.08741;-0.04234;,
 0.05024;-0.02798;-0.09082;,
 0.07197;-0.08598;0.05204;,
 0.05361;-0.20108;0.02736;,
 0.03953;-0.20108;-0.04371;,
 0.05442;0.08741;-0.04234;;
 
 8;
 4;0,1,2,3;,
 3;3,4,0;,
 4;5,6,7,8;,
 3;6,5,9;,
 4;4,9,5,0;,
 4;5,8,1,0;,
 4;7,2,1,8;,
 4;6,3,2,7;;
 
 MeshMaterialList {
  5;
  8;
  1,
  1,
  1,
  1,
  1,
  1,
  3,
  3;;
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
   0.600000;0.000000;0.000000;;
  }
  Material {
   0.000000;1.000000;0.000000;1.000000;;
   5.000000;
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
 }
 MeshNormals {
  11;
  -0.984791;-0.045225;-0.167755;,
  -0.989728;0.023412;-0.141031;,
  -0.974487;-0.113616;-0.193564;,
  0.984791;-0.045228;-0.167751;,
  0.989728;0.023412;-0.141031;,
  0.974487;-0.113622;-0.193557;,
  0.000000;0.387308;-0.921950;,
  0.000000;0.065944;-0.997823;,
  -0.000000;-0.262609;-0.964902;,
  0.000000;-1.000000;0.000000;,
  0.000000;-0.209689;0.977768;;
  8;
  4;0,2,2,0;,
  3;0,1,0;,
  4;3,3,5,5;,
  3;3,3,4;,
  4;6,6,7,7;,
  4;7,8,8,7;,
  4;9,9,9,9;,
  4;10,10,10,10;;
 }
}
