// @Maintainer jwrl
// @Released 2025-07-27
// @Author jwrl
// @Created 2020-01-04

/**
 This simple effect adjusts the vibrance and saturation in a way similar to standard
 graphics software.  The vibrance component selectively alters the saturation levels
 of the less saturated elements of the video, while having little effect on the more
 heavily saturated colours.  This means that clipping is minimised as colours near
 full saturation.

 Added in this version is a saturation control, which does just that.  Unlike vibrance
 it affects all colours in the image.  It's been added to provide a means of overiding
 any unexpected saturation drifts that may be caused by the vibrance adjustment.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Vibrance.fx
//
// Version history:
//
// Updated 2025-07-27 jwrl.
// Added saturation adjustment to bring the effect into line with Photoshop and other
// graphics software.
// Improved the descriptive text.
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

#define LUMINOSITY float4(0.212656, 0.715158, 0.072186, 0.0)

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Vibrance_2025)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 source = tex2D (Inp, uv1);
   float4 luma   = float4 (dot (source, LUMINOSITY).xxx, source.a);

   // Calculate a saturation factor that gives more weight to less saturated colors
   // and flesh tones using the calculated luminance.  First, find the strongest color.
   // The square law makes the vibrance amount non-linear.

   float amount = pow (1.0 + Vibrance, 2.0) - 1.0;
   float maxval = max (source.r, max (source.g, source.b));
   float vibval = amount * (luma.x - maxval);

   // Adjust the vibrance strength based on the calculated colour masking.
   // Saturation is then adjusted after the vibrance.

   float4 video  = float4 (saturate (lerp (source.rgb, maxval.xxx, vibval)), source.a);
   float4 retval = lerp (luma, video, Saturation + 1.0);

   retval.a = source.a;

   return lerp (source, retval, tex2D (Mask, uv1).x);
}
