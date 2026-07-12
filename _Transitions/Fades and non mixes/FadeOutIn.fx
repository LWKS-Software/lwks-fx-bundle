// @Maintainer jwrl
// @Released 2026-07-12
// @Author jwrl
// @Created 2024-08-16

/**
 This simple effect fades the first video source out to black and the second in from
 black.  Three fade profiles are available, a linear fade, a simulated film optical
 or an S curve.  It includes the ability to set a black dwell time of up to half the
 total fade out / fade in duration.

   [*]Amount:  The normal keyframed transition progress.
   [*]Black dwell:  The amount of the transition that will pause on black in the
      the middle.
   [*]Fade type:  Selects between a standard video fade, a film optical or an S curve.

 Even though it isn't a standard dissolve, it still requires that there is the same
 video overlap available.  This is a Lightworks design need.

 NOTE:  This effect has been revised for Lightworks version 2026 and higher.  In my
 opinion it's really pointless because LW 2026 has fade in and fade out capabilities
 built in.  It's just here if for some reason you want it.  In all respects it behaves
 as the earlier versions did, and can be installed on any Lightworks version above 2022.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FadeOutIn.fx
//
// Version history:
//
// Updated 2026-07-12 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Created 2024-08-16 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Fade out / fade in", "Mix", "Fades and non mixes", "Fades the first video out then the next in", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",      kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (BlackDwell,     "Black dwell", kNoGroup, "DisplayAsPercentage", 0.0, 0.0, 0.5);
DeclareIntParam   (FadeType,       "Fade type",   kNoGroup, 0, "Standard video|Film optical|S curve");

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI 3.14159265

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (FadeOutIn)
{
   float dwell   = clamp (BlackDwell, 0.0, 0.5) * 0.5;
   float fadeOut = smoothstep (0.0, 0.5 - dwell, Amount);
   float fadeIn  = 1.0 - smoothstep (0.5 + dwell, 1.0, Amount);

   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = ReadPixel (Bg, uv2);

   if (FadeType == 1) {
      Fgnd = pow (Fgnd, (0.33 + fadeOut) * 3.0);
      Bgnd = pow (Bgnd, (0.33 + fadeIn) * 3.0);
   }
   else if (FadeType == 2) {
      fadeOut = 1.0 - ((cos (PI * fadeOut) + 1.0) * 0.5);
      fadeIn  = 1.0 - ((cos (PI * fadeIn ) + 1.0) * 0.5);
   }

   float4 retval = lerp (Fgnd, float2 (0.0, 1.0).xxxy, fadeOut);

   return lerp (Bgnd, retval, fadeIn);
}
