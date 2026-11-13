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
 13;
 0.26256;0.17745;0.24644;,
 0.16799;0.16500;0.33355;,
 0.17885;0.08251;0.40510;,
 0.28507;0.09585;0.35053;,
 0.27413;0.17897;0.24029;,
 0.26924;-0.03763;0.24360;,
 0.30208;-0.03331;0.22568;,
 0.19594;-0.04728;0.33054;,
 0.08702;0.15434;0.26103;,
 0.07348;0.06269;0.31144;,
 0.06185;0.15102;0.23763;,
 0.08980;-0.06125;0.20063;,
 0.11916;-0.05739;0.22551;;
 
 8;
 3;0,1,2;,
 4;3,4,0,2;,
 4;2,5,6,3;,
 3;7,5,2;,
 3;8,2,1;,
 4;9,2,8,10;,
 4;2,9,11,12;,
 3;7,2,12;;
 
 MeshMaterialList {
  6;
  8;
  5,
  5,
  5,
  5,
  5,
  5,
  5,
  5;;
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
  Material {
   1.000000;1.000000;1.000000;1.000000;;
   5.000000;
   0.000000;0.000000;0.000000;;
   0.250000;0.250000;0.250000;;
  }
 }
 MeshNormals {
  13;
  0.494404;0.605814;0.623341;,
  0.753752;-0.249911;0.607785;,
  0.352646;0.709761;0.609819;,
  0.199926;0.791647;0.577343;,
  0.434907;-0.593852;0.676901;,
  0.611763;-0.434257;0.661186;,
  -0.641570;0.440261;0.628138;,
  -0.451515;-0.626431;0.635389;,
  -0.632985;0.451874;0.628602;,
  -0.591648;-0.529595;0.607851;,
  -0.724588;0.178096;0.665774;,
  -0.624267;0.463392;0.628934;,
  -0.714166;-0.416991;0.562215;;
  8;
  3;2,0,2;,
  4;3,3,2,2;,
  4;5,5,4,4;,
  3;1,5,5;,
  3;8,10,11;,
  4;6,10,8,6;,
  4;7,7,7,9;,
  3;12,10,9;;
 }
 MeshTextureCoords {
  13;
  -0.945710;-0.002190;
  -0.500000;-0.002190;
  -0.500000;0.386570;
  -1.000250;0.389580;
  -1.000250;-0.002190;
  -0.845470;0.998310;
  -1.000250;0.998310;
  -0.500000;0.998310;
  -0.118390;-0.002190;
  0.000250;0.414140;
  0.000250;-0.002190;
  0.000250;0.998310;
  -0.138140;0.998310;;
 }
}
