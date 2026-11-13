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
 0.04922;0.09887;0.13355;,
 -0.00003;0.04236;0.19011;,
 0.07283;0.06011;0.13162;,
 0.05258;0.02094;0.14343;,
 0.06940;0.02334;0.13004;,
 0.04297;-0.02192;0.11337;,
 0.08936;0.07968;0.09723;,
 0.07971;0.10323;0.09241;,
 0.05410;-0.01171;0.10133;,
 0.08167;0.02811;0.10198;,
 0.04097;0.02111;0.12416;,
 0.00006;0.03750;0.15892;,
 0.04578;0.09224;0.12090;;
 
 13;
 3;0,1,2;,
 4;1,3,4,2;,
 3;3,5,4;,
 4;6,7,0,2;,
 4;8,9,4,5;,
 4;6,2,4,9;,
 4;6,9,8,7;,
 4;8,5,10,7;,
 3;3,10,5;,
 4;1,11,10,3;,
 3;7,12,0;,
 4;0,12,11,1;,
 4;7,10,11,12;;
 
 MeshMaterialList {
  5;
  13;
  2,
  2,
  2,
  2,
  2,
  2,
  1,
  1,
  1,
  1,
  1,
  1,
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
   0.180706;0.180706;0.180706;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.062745;0.062745;0.062745;;
  }
  Material {
   1.000000;0.000000;0.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.250000;0.000000;0.000000;;
  }
  Material {
   1.000000;1.000000;1.000000;1.000000;;
   13.000000;
   0.500000;0.500000;0.500000;;
   0.250000;0.250000;0.250000;;
  }
 }
 MeshNormals {
  21;
  0.740700;0.133476;0.658443;,
  0.638774;0.355907;0.682128;,
  0.604901;0.103180;0.789588;,
  0.770526;-0.346510;0.534996;,
  0.617721;-0.335509;0.711235;,
  0.693790;-0.567728;0.443103;,
  0.712261;0.406929;0.571921;,
  0.851657;0.159433;0.499260;,
  0.881280;-0.338623;0.329666;,
  0.791530;-0.555041;0.255753;,
  -0.714488;0.065405;-0.696584;,
  -0.257653;-0.954911;0.147513;,
  -0.729295;0.531907;-0.430353;,
  0.195168;-0.118934;-0.973532;,
  -0.250147;-0.061363;-0.966261;,
  -0.774947;0.121403;-0.620257;,
  -0.700792;0.511425;-0.497328;,
  -0.845143;-0.166688;0.507886;,
  -0.664774;0.720771;-0.196379;,
  -0.807526;0.339915;-0.482037;,
  -0.795803;0.597907;-0.095945;;
  13;
  3;1,2,0;,
  4;2,4,3,0;,
  3;4,5,3;,
  4;7,6,1,0;,
  4;9,8,3,5;,
  4;7,0,3,8;,
  4;13,13,13,14;,
  4;15,15,10,16;,
  3;17,17,17;,
  4;11,11,11,11;,
  3;16,12,18;,
  4;18,12,19,20;,
  4;14,10,19,12;;
 }
}
