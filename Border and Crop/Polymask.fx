// @Maintainer jwrl
// @Released 2025-01-10
// @Author jwrl
// @Created 2023-02-14

/**
 This is a Lightworks 2023 replacement for all of khaver's original Polymask effects,
 which have now been withdrawn.  As with the original effect(s), inside the mask bounds
 is the Fg video, the outside is either the selected colour or Bg video (transparent
 black if no Bg is connected).  It also replaces several other mask effects.

 Added to this version and not included in khaver's original is a hard transparency
 setting.  This overrides both the background input and colour generation.  The
 settings are:

   * Mask background:  Chooses between the video background, a background colour, and
        a fully transparent background.
   * Bg colour:  Sets the background colour.
   * Fade background:  Fades the background into the foreground.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Polymask.fx
//
// Version history:
//
// Updated 2025-01-10 jwrl.
// Added "Hard transparency" to mask background menu.
//
// Updated 2023-05-15 jwrl.
// Header reformatted.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Polymask", "DVE", "Border and Crop", "Multi-sided adjustable mask", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Mode, "Mask background", kNoGroup, 1, "Bg input|Colour|Hard transparency");

DeclareColourParam (BgColour, "Bg colour", kNoGroup, kNoFlags, 0.0, 0.5, 0.0, 1.0);

DeclareFloatParam (FadeBg, "Fade background", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (PolyMask)
{
   float4 Fgnd = ReadPixel (Fg, uv1);
   float4 Bgnd = Mode == 0 ? ReadPixel (Bg, uv2) : BgColour;

   Bgnd = Mode == 2 ? kTransparentBlack : lerp (Fgnd, Bgnd, FadeBg);

   // We derive the mask from sequence coordinates, not from foreground nor background.

   return lerp (Bgnd, Fgnd, tex2D (Mask, uv3).x);
}
