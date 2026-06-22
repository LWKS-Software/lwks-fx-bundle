// @Maintainer jwrl
// @Released 2026-06-22
// @Author jwrl
// @Created 2018-08-24

/**
 This effect is a pseudo random switch between two video sources.  Alternatively you
 could feed one input directly from a video source and the second from the same source
 through a colourgrade or a transform effect.  You could even just connect to In1,
 with nothing on In2.  That would give a hard flicker between black and video.

   [*]Opacity:  Self explanatory.
   [*]Switch settings
      [*]Speed:  Sets the rate at which switching takes place.
      [*]Random:  Varies how random the switching will be. Speed and Random interact.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RandomFlicker.fx
//
// Version history:
//
// Updated 2026-06-22 jwrl.
// Changed "Randomness" to "Random".
// Added settings description to header text.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-10 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Random flicker", "User", "Switches", "Does a pseudo random switch between two inputs.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (In1, In2);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup,          kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Speed,   "Speed",   "Switch settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Random,  "Random",  "Switch settings", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_Progress);
DeclareFloatParam (_LengthFrames);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define OFFS_1  1.8571428571
#define OFFS_2  1.3076923077

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (RandomFlicker)
{
   float freq = floor ((_LengthFrames * _Progress) + 0.5) * max (Speed, 0.01) * 19.0;
   float frq1 = max (0.5, Random + 0.5);
   float frq2 = pow (frq1, 3.0) * freq * OFFS_2;

   frq1 *= freq * OFFS_1;

   float strobe = max (sin (freq) + sin (frq1) + sin (frq2), 0.0);

   float4 Bgnd = ReadPixel (In2, uv2);
   float4 retval = strobe == 0.0 ? lerp (Bgnd, ReadPixel (In1, uv1), Opacity) : Bgnd;

   return lerp (Bgnd, retval, tex2D (Mask, uv1));
}
