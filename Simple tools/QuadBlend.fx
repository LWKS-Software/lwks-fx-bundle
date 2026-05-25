// @Maintainer jwrl
// @Released 2026-05-26
// @Author jwrl
// @Created 2026-05-25

/**
 This effect provides a simple blend of four video inputs over a single background.
 It includes level adjustment of each input plus a master level control and video
 masking.  It's designed for use where simple compositing is all that's needed.
 The order of priority of the inputs is D-C-B-A, with D the lowest layer, under
 C, B and then A.  The controls are very simple.

   [*]Mix amount:  Allows all four inputs to be faded in or out simultaneously.
   [*]Individual inputs.
      [*]A opacity:  Fades A input in or out.
      [*]B opacity:  Fades B input in or out.
      [*]C opacity:  Fades C input in or out.
      [*]D opacity:  Fades D input in or out.
   [*]Mask fade:  Allows masking to be faded in.

 Any scaling, colourgrading or other image processing must be done externally to
 this effect.  As stated earlier, this is designed to be just a very simple
 compositing tool.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect QuadBlend.fx
//
// Updated 2026-05-26 by jwrl.
// Added ability to fade mask out to reveal unmasked video.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Quad blend", "Mix", "Simple tools", "Provides a simple blend for four inputs and a background", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (A, B, C, D, X);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount,   "Mix amount", kNoGroup,            kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Aopacity, "A opacity",  "Individual inputs", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Bopacity, "B opacity",  "Individual inputs", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Copacity, "C opacity",  "Individual inputs", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Dopacity, "D opacity",  "Individual inputs", kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (MaskFade, "Mask fade",  kNoGroup,            kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (QuadBlend)
{
   float4 FgA = ReadPixel (A, uv1);
   float4 FgB = ReadPixel (B, uv2);
   float4 FgC = ReadPixel (C, uv3);
   float4 FgD = ReadPixel (D, uv4);
   float4 Bgd = ReadPixel (X, uv5);
   float4 ret = lerp (Bgd, FgD, FgD.a * Dopacity);

   float msk = lerp (1.0, tex2D (Mask, uv6).x, MaskFade);

   ret = lerp (ret, FgC, FgC.a * Copacity);
   ret = lerp (ret, FgB, FgB.a * Bopacity);
   ret = lerp (ret, FgA, FgA.a * Aopacity);
   ret = lerp (Bgd, ret, Amount);

   return lerp (Bgd, ret, msk);
}
