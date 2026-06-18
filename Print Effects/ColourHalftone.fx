// @Maintainer jwrl
// @Released 2026-06-18
// @Author windsturm
// @Created 2012-06-16

/**
 This effect emulates the dot pattern of a colour half-tone print image.  The colours
 used for background and dots are user adjustable.

   [*]Center:  Sets the centre point position for dot matrix sampling.
   [*]Size:  Sets the maximum size of the dots produced.
   [*]Cyan
      [*]Angle:  Sets the angle of the cyan dot patterns.
      [*]Colour:  Sets the colour of the cyan dot patterns.
   [*]Magenta:  As for the Cyan group.
   [*]Yellow:  As for the Cyan group.
   [*]blacK:  As for the Cyan group.
   [*]Background:  Sets the background colour.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourHalftone.fx
//
// Version history:
//
// Updated 2026-06-18 jwrl.
// Reordered the settings and groups so that they're more logical.
// All channels of Mask are now used.
// Added settings to the header text.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Colour halftone", "Stylize", "Print Effects", "Emulates the dot pattern of a colour half-tone print image", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam  (centerX, "Center",      NoGroup,   "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam  (centerY, "Center",      NoGroup,   "SpecifiesPointY", 0.5, 0.0, 1.0);
DeclareFloatParam  (dotSize, "Size",        NoGroup,   kNoFlags, 0.01, 0.0, 1.0);

DeclareFloatParam  (angleC,  "Angle",       "Cyan",    kNoFlags, 15.0, 0.0, 90.0);
DeclareColourParam (colourC, "Colour",      "Cyan",    kNoFlags, 0.0, 1.0, 1.0, 1.0);

DeclareFloatParam  (angleM,  "Angle",       "Magenta", kNoFlags, 75.0, 0.0, 90.0);
DeclareColourParam (colourM, "Colour",      "Magenta", kNoFlags, 1.0, 0.0, 1.0, 1.0);

DeclareFloatParam  (angleY,  "Angle",       "Yellow",  kNoFlags, 0.0, 0.0, 90.0);
DeclareColourParam (colourY, "Colour",      "Yellow",  kNoFlags, 1.0, 1.0, 0.0, 1.0);

DeclareFloatParam  (angleK,  "Angle",       "blacK",   kNoFlags, 40.0, 0.0, 90.0);
DeclareColourParam (colourK, "Colour",      "blacK",   kNoFlags, 0.0, 0.0, 0.0, 1.0);

DeclareColourParam (colourBG, "Background", NoGroup,   kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define SQRT_2 1.414214

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2x2 RotationMatrix (float rotation)  
{
   float c, s;

   sincos (rotation, s, c);

   return float2x2 (c, -s, s, c);
}

float4 half_tone (float2 uv, float i, float s, float angle, float a)
{
   float2 xy = uv;
   float2 asp = float2 (1.0, _OutputAspectRatio);
   float2 centerXY = float2 (centerX, 1.0 - centerY);

   float2 pointXY = mul ((xy - centerXY) / asp, RotationMatrix (radians (angle)));

   pointXY = pointXY + (s / 2.0);
   pointXY = round (pointXY / dotSize) * dotSize;
   pointXY = mul (pointXY, RotationMatrix (radians (-angle)));
   pointXY = pointXY * asp + centerXY;

   float3 cmyColor = (1.0.xxx - tex2D (Input, pointXY).rgb);           // simplest conversion

   float k = min (min (min (1.0, cmyColor.x), cmyColor.y), cmyColor.z);

   float4 cmykColor = float4 ((cmyColor - k.xxx) / (1.0 - k), k);

   //xy slide

   float2 slideXY = mul (float2 ((s) / SQRT_2, 0.0), RotationMatrix (radians ((angle + a) * -1.0)));
   slideXY *= asp;

   float cmykluma [4] = { cmykColor.w, cmykColor.x, cmykColor.y, cmykColor.z };
   float4 cmykcol [4] = { colourK, colourC, colourM, colourY };

   xy += slideXY;
   asp *= (dotSize * cmykluma [i]);

   float2 aspectAdjustedpos = ((xy - pointXY) / asp) + pointXY;

   return (distance (aspectAdjustedpos, pointXY) < 0.5) ? cmykcol [i] : (-1.0).xxxx;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (s0)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (ColourHalftone)
{
   float4 ret, source = tex2D (s0, uv2);

   if (dotSize <= 0.0) { ret = source; }
   else {
      ret = colourBG;

      float cmykang [4] = {angleK, angleC, angleM, angleY};

      float4 ret1 = half_tone (uv2, 0, 0.0, cmykang [0], 0.0);
      float4 ret2 = half_tone (uv2, 0, dotSize, cmykang [0], 45.0);

      if (ret1.a > -1.0 || ret2.a > -1.0) { ret *=  max (ret1, ret2); }

      ret1 = half_tone (uv2, 1, 0.0, cmykang [1], 0.0);
      ret2 = half_tone (uv2, 1, dotSize, cmykang [1], 45.0);

      if (ret1.a > -1.0 || ret2.a > -1.0) { ret *=  max (ret1, ret2); }

      ret1 = half_tone (uv2, 2, 0.0, cmykang [2], 0.0);
      ret2 = half_tone (uv2, 2, dotSize, cmykang [2], 45.0);

      if (ret1.a > -1.0 || ret2.a > -1.0) { ret *=  max (ret1, ret2); }

      ret1 = half_tone (uv2, 3, 0.0, cmykang [3], 0.0);
      ret2 = half_tone (uv2, 3, dotSize, cmykang [3], 45.0);

      if (ret1.a > -1.0 || ret2.a > -1.0) { ret *=  max (ret1, ret2); }

      if (IsOutOfBounds (uv2)) ret = kTransparentBlack;
   }

   return lerp (source, ret, tex2D (Mask, uv2));
}
