// @Maintainer jwrl
// @Released 2025-08-01
// @Author khaver
// @Created 2012-12-18

/**
 This simple effect fades the video source out to black or in from black.  It was
 originally created by khaver in December 2012.  This conversion compiles in all
 modern versions of Lightworks.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Fade.fx
//
// Version history:
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

DeclareIntParam (Direction, "Fade Direction", kNoGroup, 0, "In|Out");

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

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

