// @Maintainer jwrl
// @Released 2025-10-23
// @Author jwrl
// @Created 2020-05-18

/**
 This is a simple effect to allow removal or addition of the sorts of colour registration
 errors that you can get with the poor debayering of cheap single chip cameras.  It can
 also be used if you want to emulate some of the colour registration problems that older
 analogue cameras and TVs produced.

   [*] Opacity:  Controls the visibility of the registration errors.
   [*] R-B displacement X:  Adjusts the horizontal red-blue error.
   [*] R-B displacement Y:  Adjusts the vertical red-blue error.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect RGBregistration.fx
//
// Version history:
//
// Updated 2025-10-23 jwrl.
// Changed the subcategory from "Simple tools" to "Video artefacts".
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-25 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("RGB registration", "Stylize", "Video artefacts", "Adjusts the X-Y registration of the RGB channels of a video stream", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Xdisplace, "R-B displacement", kNoGroup, "SpecifiesPointX|DisplayAsPercentage", 0.0, -0.05, 0.05);
DeclareFloatParam (Ydisplace, "R-B displacement", kNoGroup, "SpecifiesPointY|DisplayAsPercentage", 0.0, -0.05, 0.05);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (RGBregistration)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float2 xy  = float2 (Xdisplace, Ydisplace);
   float2 xy1 = uv1 - xy;
   float2 xy2 = uv1 + xy;

   float4 video  = ReadPixel (Inp, uv1);
   float4 retval = video;

   retval.rb = float2 (tex2D (Inp, xy1).r, tex2D (Inp, xy2).b);

   retval = lerp (video, retval, Opacity);

   return lerp (video, retval, tex2D (Mask, uv1).x);
}

