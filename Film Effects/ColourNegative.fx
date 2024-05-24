// @Maintainer jwrl
// @Released 2024-05-24
// @Author jwrl
// @Created 2016-05-14

/**
 This simulates the look of 35 mm colour masked negative film.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourNegative.fx
//
// Version history:
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with float4 0.0.xxxx for Linux fix.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Colour negative", "Colour", "Film Effects", "Simulates the look of 35 mm colour film dye-masked negative", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (ColourNegative)
{
   float4 source = ReadPixel (Input, uv1);
   float4 retval = source;

   retval.rgb = (float3 (2.0, 1.33, 1.0) - retval.rgb) / 2.0;

   retval = lerp (0.0.xxxx, retval, retval.a);

   return lerp (source, retval, tex2D (Mask, uv1).x);
}
