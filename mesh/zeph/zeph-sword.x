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
 11;
 -0.00185;0.02641;2.36827;,
 -0.00185;0.08610;0.58972;,
 0.02320;0.00391;0.24973;,
 0.00541;0.00391;2.21307;,
 -0.00185;0.00391;2.57374;,
 -0.00910;0.00391;2.21307;,
 -0.02690;0.00391;0.24973;,
 -0.00185;-0.01859;2.36827;,
 0.00541;0.00391;2.21307;,
 -0.00185;-0.07828;0.58972;,
 -0.00910;0.00391;2.21307;;
 
 10;
 4;3,2,1,0;,
 3;0,4,3;,
 4;1,6,5,0;,
 3;4,0,5;,
 3;6,1,2;,
 4;9,2,8,7;,
 3;4,7,8;,
 4;10,6,9,7;,
 3;7,4,10;,
 3;9,6,2;;
 
 MeshMaterialList {
  5;
  10;
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0;;
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
  14;
  0.975765;0.218359;0.014217;,
  0.999960;-0.000002;0.008925;,
  0.966705;0.255749;0.008628;,
  0.999798;-0.000003;0.020114;,
  -0.975765;0.218361;0.014217;,
  -0.999960;-0.000002;0.008925;,
  0.975764;-0.218363;0.014216;,
  0.966704;-0.255752;0.008628;,
  -0.975763;-0.218366;0.014216;,
  -0.966703;0.255754;0.008628;,
  -0.999798;-0.000003;0.020114;,
  0.000000;0.972001;-0.234978;,
  -0.966703;-0.255757;0.008628;,
  0.000000;-0.972003;-0.234970;;
  10;
  4;0,1,2,0;,
  3;0,3,0;,
  4;9,5,4,4;,
  3;10,4,4;,
  3;11,11,11;,
  4;7,1,6,6;,
  3;3,6,6;,
  4;8,5,12,8;,
  3;8,10,8;,
  3;13,13,13;;
 }
}
