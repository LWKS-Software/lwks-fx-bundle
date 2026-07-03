// @Maintainer jwrl
// @Released 2026-07-03
// @Author khaver
// @Created 2011-04-28

/**
 Breaks the image into a mosaic or into glass tiles.  It's a combination of two original
 effects by khaver, Tiles.fx and GlassTiles.fx.

   [*]Tile style selects between mosaic, i.e., a series of flat colour tiles, or
      glass, which emulates looking at the image through bevelled glass tiles.
   [*]Tiles sets the number of tiles that will break the image up.
   [*]Bevel width sets the width of the bevel at the tile edges.
   [*]Offset sets the apparent depth of the bevel.
   [*]Grout Colour sets the colour of the fill between the titles.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Tiling.fx
//
// Version history:
//
// Updated 2026-07-03 jwrl.
// Added settings description to header text.
// Changed "Edge/Grout Color" to "Grout colour".
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-25 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Tiling", "Stylize", "Textures", "Breaks the image into mosaic or glass tiles", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Tile style",   kNoGroup, 0, "Mosaic pattern|Glass tiles");
DeclareFloatParam (Tiles,      "Tiles",        kNoGroup, kNoFlags, 15.0, 0.0, 200.0);
DeclareFloatParam (BevelWidth, "Bevel width",  kNoGroup, kNoFlags, 15.0, 0.0, 200.0);
DeclareFloatParam (Offset,     "Offset",       kNoGroup, kNoFlags, 0.0, 0.0, 200.0);
DeclareColourParam (EdgeColor, "Grout colour", kNoGroup, kNoFlags, 0.0, 0.0, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Inp)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (MosaicTiles)
{
   float Size = Tiles / 200.0;
   float EdgeWidth = BevelWidth / 100.0;

   if (Size <= 0.0) return tex2D (Inp, uv2);

   float threshholdB = 1.0 - EdgeWidth;

   float2 Pbase = uv2 - fmod (uv2, Size.xx);
   float2 PCenter = Pbase + (Size / 2.0).xx;
   float2 st = (uv2 - Pbase) / Size;

   float3 cTop = 0.0.xxx;
   float3 cBottom = 0.0.xxx;
   float3 invOff = 1.0.xxx - EdgeColor.rgb;

   if ((st.x > st.y) && any (st > threshholdB)) { cTop = invOff; }

   if ((st.x > st.y) && any (st < EdgeWidth)) { cBottom = invOff; }

   float4 tileColor = tex2D (Inp, PCenter);

   return float4 (max (0.0.xxx, (tileColor.rgb + cBottom - cTop)), tileColor.a);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (GlassTiles)
{
   float2 newUV1 = uv1 + tan ((Tiles * 2.5) * (uv1 - 0.5) + Offset) * (BevelWidth / _OutputWidth);

   return IsOutOfBounds (newUV1) ? float4 (EdgeColor.rgb, 1.0) : tex2D (Input, newUV1);
}
