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
 18;
 0.19197;0.08758;0.84573;,
 0.19197;0.08758;-1.28425;,
 0.24757;-0.06942;-1.80479;,
 0.34549;-0.34593;-1.00021;,
 0.23502;-0.03399;1.09019;,
 0.26261;0.04593;0.68893;,
 0.37418;-0.26911;-0.91641;,
 0.30017;-0.06011;-1.52579;,
 0.26261;0.04593;-1.16343;,
 0.28354;-0.01315;0.80788;,
 0.24731;0.01440;-0.68179;,
 0.03315;0.01440;-0.68179;,
 0.03315;0.01440;-0.50197;,
 0.24731;0.01440;-0.50197;,
 0.03315;-0.00624;-0.50197;,
 0.24731;-0.00624;-0.50197;,
 0.03315;-0.00624;-0.68179;,
 0.24731;-0.00624;-0.68179;;
 
 13;
 4;0,1,2,3;,
 3;4,0,3;,
 4;5,6,7,8;,
 3;9,6,5;,
 4;4,3,6,9;,
 4;7,6,3,2;,
 4;8,7,2,1;,
 4;1,0,5,8;,
 4;5,0,4,9;,
 4;10,11,12,13;,
 4;13,12,14,15;,
 4;15,14,16,17;,
 4;17,16,11,10;;
 
 MeshMaterialList {
  5;
  13;
  1,
  1,
  3,
  3,
  3,
  4,
  4,
  4,
  4,
  2,
  2,
  2,
  2;;
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
  18;
  -0.942640;-0.333811;0.000000;,
  -0.942641;-0.333808;-0.000000;,
  -0.942639;-0.333813;0.000001;,
  0.824888;0.563404;0.046224;,
  0.739344;0.671391;-0.051043;,
  0.938597;0.324421;-0.117416;,
  0.999818;0.009575;-0.016477;,
  0.975954;0.188063;0.110212;,
  0.000000;1.000000;0.000000;,
  0.000000;0.000000;1.000000;,
  0.000000;-1.000000;0.000000;,
  0.879956;-0.460930;0.114982;,
  0.945821;-0.323158;-0.031478;,
  0.930497;0.317084;-0.183393;,
  0.593050;0.801781;-0.073749;,
  0.646479;0.757596;0.090076;,
  0.760466;0.624869;0.176719;,
  0.000000;0.000000;-1.000000;;
  13;
  4;0,1,1,0;,
  3;2,0,0;,
  4;3,6,5,4;,
  3;7,6,3;,
  4;11,12,6,7;,
  4;5,6,12,13;,
  4;4,5,13,14;,
  4;14,15,3,4;,
  4;3,15,16,7;,
  4;8,8,8,8;,
  4;9,9,9,9;,
  4;10,10,10,10;,
  4;17,17,17,17;;
 }
}
