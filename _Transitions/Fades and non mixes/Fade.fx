// @Maintainer jwrl
// @Released 2026-07-12
// @Author khaver
// @Created 2012-12-18

/**
 This simple effect fades the video source out to black or in from black.  It was
 originally created by khaver in December 2012.  This conversion compiles in all
 modern versions of Lightworks.

   [*]Fade Direction:  Selects between fading the video in from black or out to black.
   [*]Amount:  The normal keyframed transition progress.

 NOTE:  This effect has been revised for Lightworks version 2026 and higher.  In my
 opinion it's really pointless because LW 2026 has fade in and fade out capabilities
 built in.  It's just here if for some reason you want it.  In all respects it behaves
 as the earlier versions did, and can be installed on any Lightworks version above 2022.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Fade.fx
//
// Version history:
//
// Updated 2026-07-12 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Updated 2025-08-01 jwrl.  Renamed from "Fade".
//
// Converted from HLSL 2025-07-31 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Fade to black", "Mix", "Fades and non mixes", "Fades video out or in.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Direction,        "Fade Direction", kNoGroup, 0, "In|Out");
DeclareFloatParamAnimated (Amount, "Amount",         kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Fade)
{
   float direction = Direction ? Amount : 1.0 - Amount;

   float4 fgPix = ReadPixel (Fg, uv1 );

   return lerp (fgPix, kTransparentBlack, direction);
}
