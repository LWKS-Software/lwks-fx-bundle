// @Maintainer jwrl
// @Released 2024-05-24
// @Author baopao
// @Created 2015-11-30

/**
 Unpremultiply does just that.  It removes the hard outline you can get with premultiplied
 mattes.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Unpremultiply.fx
//
// Version history:
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with explicit value.
//
// Updated 2023-05-15 jwrl.
// Header reformatted.
//
// Conversion 2023-02-17 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Unpremultiply", "Mix", "Blend Effects", "Removes the hard outline you can get with some blend effects", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Unpremultiply)
{
   float4 color = lerp (0.0.xxxx, ReadPixel (Inp, uv1), tex2D (Mask, uv1).x);

   return float4 (color.rgb /= color.a, color.a);
}
