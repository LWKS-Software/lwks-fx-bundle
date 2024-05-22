// @Maintainer jwrl
// @Released 2024-05-22
// @Author jwrl
// @Created 2018-12-31

/**
 This simple effect fades any video to which it's applied to or from from black.  It
 isn't a standard dissolve, since it requires one input only.  It must be applied in
 the same way as a title effect, i.e., by marking the region that the fade in or out
 is to occupy.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Fades.fx
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
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Fades", "Mix", "Fades and non mixes", "Fades video to or from black", CanSize);

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

DeclareEntryPoint (Fades)
{
   float level = Type ? 1.0 - Amount : Amount;

   float4 Input  = ReadPixel (Inp, uv1);
   float4 retval = lerp (_OpaqueBlack, Input, level);

   return lerp (_TransparentBlack, retval, tex2D (Mask, uv1).x);
}
