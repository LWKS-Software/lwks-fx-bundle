// @Maintainer jwrl
// @Released 2024-05-22
// @Author jwrl
// @Created 2019-01-01

/**
 This simulates the look of the classic film optical fade to or from black.  It applies
 an exposure shift and a degree of black crush to the transition the way that the lab
 optical printers did.  It isn't a transition, and requires one input only.  It must be
 applied in the same way as a title effect, i.e., by marking the region that the fade is
 to occupy.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect OpticalFades.fx
//
// Version history:
//
// Updated 2024-05-22 jwrl.
// Removed _utils.fx inclusion.
// Linux fixes:
// Added _OpaqueBlack declaration
// Changed kTransparentBlack to _TransparentBlack declaration.
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

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (Type, "Fade type", kNoGroup, 0, "Fade up|Fade down");

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

float4 _OpaqueBlack = float2 (0.0, 1.0).xxxy;
float4 _TransparentBlack = 0.0.xxxx;

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (OpticalFades)
{
   float level = Type ? Amount : 1.0 - Amount;

   float4 video = ReadPixel (Inp, uv1);
   float4 retval = pow (video, (0.33 + level) * 3.0);

   retval = lerp (retval, _OpaqueBlack, level);

   return lerp (_TransparentBlack, retval, tex2D (Mask, uv1).x);
}
