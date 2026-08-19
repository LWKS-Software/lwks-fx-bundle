// @Maintainer jwrl
// @Released 2026-07-12
// @Author jwrl
// @Created 2019-01-01

/**
 This simulates the look of the classic film optical fade to or from black.  It applies
 an exposure shift and a degree of black crush to the transition the way that the lab
 optical printers did.  It isn't a transition, and requires one input only.  It must be
 applied in the same way as a title effect, i.e., by marking the region that the fade is
 to occupy.

   [*]Amount:  The normal keyframed transition progress.
   [*]Fade type:  Can choose between fade up from transparent black and fade out
      to transparent black.

 NOTE:  This effect has been revised for Lightworks version 2026 and higher.  In my
 opinion it's really pointless because LW 2026 has fade in and fade out capabilities
 built in.  It's just here if for some reason you want it.  In all respects it behaves
 as the earlier versions did, and can be installed on any Lightworks version above 2022.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect OpticalFades.fx
//
// Version history:
//
// Updated 2026-07-12 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Updated 2024-08-17 jwrl.
// Replaced kTransparentBlack with float4 _TransparentBlack to fix Linux lerp()/mix() bug.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-08 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Optical fades", "Mix", "Fades and non mixes", "Simulates the black crush effect of a film optical fade to or from black", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",    kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam (Type,             "Fade type", kNoGroup, 0, "Fade up|Fade down");

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define _TransparentBlack 0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (OpticalFades)
{
   float level   = Type ? Amount : 1.0 - Amount;

   float4 Fgnd   = ReadPixel (Inp, uv1);
   float4 retval = pow (Fgnd, (0.33 + smoothstep (0.0, 1.0, level)) * 3.0);

   return lerp (retval, _TransparentBlack, level);
}
