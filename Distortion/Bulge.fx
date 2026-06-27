// @Maintainer jwrl
// @Released 2026-06-27
// @Author schrauber
// @Created 2016-03-16

/**
 Bulge 2018 allows a variable area of the frame to have a concave or convex bulge applied.
 Optionally the background can have a radial distortion applied at the same time, or can
 be made black or transparent black.

   [*]Zoom: Adjusts the size of the bulge contents.
   [*]Bulge
      [*]Size: Adjusts the bulge area.
      [*]Proportions: The bulge aspect ratio.  The range -100% to +100% corresponds to
         an aspect ratio range of 10:1 to 1:10.
      [*]Angle: Angle works in conjunction with rotation mode - see below.
   [*]Rotation mode: Sets whether angle affects the bulge shape, the contents
      or the overall input texture.
   [*]Bulge surrounds: Sets the bulge background to undistorted, distorted,
      transparent black or opaque black.
   [*]Effect centre X: Sets the horizontal position of the bulge.
   [*]Effect centre Y: Sets the vertical position of the bulge.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Bulge.fx
//
// Information for Effect Developer:
// 8 January 2023 by LW user jwrl: My apologies for the code reformatting, schrauber.  I
// have always had trouble reading other people's code.  The problem is mine, not yours.
//
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Updated 2026-06-27 jwrl.
// Changed "Environment of bulge" to "Bulge surrounds".  Selection labels have changed
// from the originals to "Input video|Distorted input|Transparent black|Opaque black".
// Changed "Aspect ratio" to "Proportions".  Its range is now shown as -100% to +100%.
// Masking now uses RGBA, not R or A.
// Added settings description to header text.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Bulge", "DVE", "Distortion", "This effect allows a variable area of the frame to have a concave or convex bulge applied", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Zoom,        "Zoom",            kNoGroup, kNoFlags, 1.0, -3.0, 3.0);

DeclareFloatParam (Bulge_size,  "Size",            "Bulge",  kNoFlags, 0.25, 0.0, 0.5);
DeclareFloatParam (Proportions, "Proportions",     "Bulge",  kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Angle,       "Angle",           "Bulge",  kNoFlags, 0.0, -3600.0, 3600);

DeclareIntParam (Rotation,      "Rotation mode",   kNoGroup, 2, "Shape (Proportions 0, no rotation)|Only the bulge content|Bulge|Input video");
DeclareIntParam (Mode,          "Bulge surrounds", kNoGroup, 0, "Input video|Distorted input|Transparent black|Opaque black");
DeclareFloatParam (Xcentre,     "Effect centre",   kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ycentre,     "Effect centre",   kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (_InputWidthNormalised);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 MirrorEdge (sampler S, float2 uv)
{
   float2 xy = 1.0.xx - abs (2.0 * (frac (uv / 2.0) - 0.5.xx));

   return tex2D (S, xy);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Bulge)
{
   float2 centre = float2 (Xcentre, 1.0 - Ycentre);
   float2 vcenter = uv1 - centre;    // Vector between Center and Texel

   float Tsin, Tcos;     // Sine and cosine of the set angle.
   float AspectRatio = abs (Proportions * 9.0) + 1.0; // AspectRatio is between 1 and 10.

   // If Proportions is positive we need AspectRatio to be from 1 to 0.1.

   if (Proportions > 0.0) { AspectRatio = 1.0 / AspectRatio; }

   // ------ Rotation of bulge dimensions. --------

   float angle = radians (-Angle);

   vcenter = float2 (vcenter.x * _OutputAspectRatio, vcenter.y);

   sincos (angle, Tsin , Tcos);

   // Correction Vector for recalculation of objects Dimensions.

   float2 Spin = float2 ((vcenter.x * Tcos - vcenter.y * Tsin), (vcenter.x * Tsin + vcenter.y * Tcos));

   Spin = float2 (Spin.x / _OutputAspectRatio, Spin.y );

   // SpinPixel is the rotated Texel position.

   float2 SpinPixel = Spin + centre;

   // ------ Bulge --------

   vcenter = centre - uv1;

   if (Rotation == 1) Spin = vcenter;

   // Get corrected object radius.

   float corRadius = length (float2 (Spin.x / AspectRatio, (Spin.y / _OutputAspectRatio) * AspectRatio));
   float bulgeSize = Bulge_size * _InputWidthNormalised;    // Corrects Bulge_size scale - jwrl

   corRadius /= _InputWidthNormalised;    // Corrects corRadius scale - jwrl

   bool bulge = corRadius < bulgeSize;    // Saves on recalculation - jwrl

   if ((Mode == 3) && !bulge) return float4 (0.0.xxx, 1.0);
   if ((Mode == 2) && !bulge) return kTransparentBlack;

   float distortion = ((Mode == 1) || bulge) ? Zoom * sqrt (sin (abs(bulgeSize - corRadius))) : 0.0;

   float2 xy = ((Rotation == 3) || ((Rotation == 2) && bulge) || ((Rotation == 1) && bulge))
             ? SpinPixel : uv1;

   // New code to recover the bulged video and mask it into the original image.

   float4 retval = MirrorEdge (Input, (distortion * (centre - xy)) + xy);
   float4 source = ReadPixel (Input, uv1);

   return lerp (source, retval, tex2D (Mask, uv1));
}
