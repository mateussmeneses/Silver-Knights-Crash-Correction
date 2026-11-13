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
 16;
 0.09581;0.00314;-0.00010;,
 0.07310;0.07316;-0.00031;,
 0.07314;0.13293;0.23080;,
 0.09581;0.05439;0.19806;,
 0.06918;0.11906;0.28354;,
 0.10678;-0.01197;0.23453;,
 -0.09581;0.00314;-0.00010;,
 -0.09581;0.05439;0.19806;,
 -0.07314;0.13293;0.23080;,
 -0.07310;0.07316;-0.00031;,
 -0.10678;-0.01197;0.23453;,
 -0.06918;0.11906;0.28354;,
 0.09493;-0.01197;0.23453;,
 0.09520;-0.03894;0.03861;,
 -0.09520;-0.03894;0.03861;,
 -0.09493;-0.01197;0.23453;;
 
 13;
 4;0,1,2,3;,
 4;2,4,5,3;,
 4;6,7,8,9;,
 4;8,7,10,11;,
 4;2,8,11,4;,
 4;1,9,8,2;,
 4;1,0,6,9;,
 4;4,11,10,5;,
 4;3,12,13,0;,
 4;7,6,14,15;,
 4;3,5,10,7;,
 4;0,13,14,6;,
 4;14,13,12,15;;
 
 MeshMaterialList {
  5;
  13;
  3,
  3,
  3,
  3,
  3,
  3,
  1,
  1,
  4,
  4,
  1,
  1,
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
  0.987948;0.149846;-0.038793;,
  0.948318;0.307195;-0.079518;,
  0.962910;0.268657;0.025054;,
  0.984157;0.176398;0.017838;,
  0.965337;0.226725;0.129310;,
  -0.987948;0.149847;-0.038792;,
  -0.948318;0.307195;-0.079518;,
  -0.962910;0.268657;0.025054;,
  -0.984157;0.176399;0.017839;,
  -0.965337;0.226725;0.129310;,
  0.999927;-0.011698;0.003018;,
  -0.999927;-0.011695;0.003020;,
  0.000000;0.999998;0.002096;,
  0.000000;0.967088;0.254443;,
  0.000000;0.968146;-0.250387;,
  0.000000;-0.002900;-0.999996;,
  0.000001;-0.364685;-0.931131;,
  0.000000;-0.350318;0.936631;,
  0.000000;-0.481591;-0.876396;,
  0.000001;-0.941017;-0.338360;,
  -0.000000;-0.990663;0.136334;;
  13;
  4;0,1,2,3;,
  4;2,4,4,3;,
  4;5,8,7,6;,
  4;7,8,9,9;,
  4;12,12,13,13;,
  4;14,14,12,12;,
  4;15,16,16,15;,
  4;17,17,17,17;,
  4;3,10,10,0;,
  4;8,5,11,11;,
  4;18,18,18,18;,
  4;16,19,19,16;,
  4;19,19,20,20;;
 }
}
