// @Maintainer jwrl
// @Released 2025-07-26
// @Author jwrl
// @Created 2020-01-04

/**
 This simple effect adjusts the vibrance and saturation in a way similar to standard
 graphics software.  Adjusting vibrance selectively alters the saturation levels of
 the less saturation components of the video, while protecting flesh tones.

 Added in this version is the saturation control, which does just that.  Unlike the
 vibrance it affects all colours in the image.  It's been added to provide fine tuning
 of unexpected saturation drifts that may have been caused by the vibrance adjustment.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Vibrance.fx
//
// Version history:
//
// Updated 2025-07-26 jwrl.
// Added saturation adjustment to bring the effect into line with Photoshop and other
// graphics software.
//
// Updated 2023-05-15 jwrl.
// Header reformatted.
//
// Conversion 2023-05-08 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Vibrance", "Colour", "Colour Tools", "Makes your video POP!!!", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Vibrance,   "Vibrance",   kNoGroup, kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Saturation, "Saturation", kNoGroup, kNoFlags, 0.0, -1.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define VIBLUMA    float4(0.212656, 0.715158, 0.072186, 0.0)
#define LUMINOSITY float4(0.25, 0.65, 0.11, 0.0)

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Vibrance_2025)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 source = tex2D (Inp, uv1);

   // Calculate a saturation factor that gives more weight to less saturated colors
   // and flesh tones using the calculated luminance.  First, find the strongest color.
   // The square law makes the vibrance amount non-linear.

   float viblum = dot (source, VIBLUMA);
   float amount = pow (1.0 + Vibrance, 2.0) - 1.0;
   float maxval = max (source.r, max (source.g, source.b));
   float vibval = amount * (viblum - maxval);

   // Adjust the vibrance strength based on the calculated colour masking.
   // Saturation is adjusted using a fresh luminance value based on vibrance.

   float4 video  = float4 (saturate (lerp (source.rgb, maxval.xxx, vibval)), source.a);
   float4 luma   = float4 (dot (video, LUMINOSITY).xxx, 0.0);
   float4 retval = lerp (luma, video, Saturation + 1.0);

   return lerp (source, retval, tex2D (Mask, uv1).x);
}
