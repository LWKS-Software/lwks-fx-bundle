// @Maintainer jwrl
// @Released 2026-07-03
// @Author jwrl
// @Created 2016-05-14

/**
 Acidulate takes us back to the '60s.  Back then, to see something like this you'd have
 to have been doing something illegal.  Simply apply the effect and adjust the amount
 that you want.  I was going to call this LSD, but this name will do.  Original effect.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Acidulate.fx
//
// Version history:
//
// Updated 2026-07-03 jwrl.
// Masking now uses RGBA rather than just R.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-12 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Acidulate", "Stylize", "Textures", "I was going to call this LSD, but this name will do", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Inp)
{ return ReadPixel (Input, uv1); }

DeclarePass (Image)
{
   float4 Img = tex2D (Inp, uv2);

   if (Amount == 0.0) return Img;

   float2 xy = float2 (Img.b - Img.r, Img.g);

   return tex2D (Inp, frac (abs (uv2 + frac (xy * Amount))));
}

DeclareEntryPoint (Acidulate)
{
   float4 Img = tex2D (Image, uv2);

   if (Amount == 0.0) return Img;

   float2 xy = float2 (Img.b, Img.g - Img.r - 1.0);

   Img = tex2D (Image, frac (abs (uv2 + frac (xy * Amount))));

   return lerp (tex2D (Inp, uv2), Img, tex2D (Mask, uv2));
}
