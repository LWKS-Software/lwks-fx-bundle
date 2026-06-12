// @Maintainer jwrl
// @Released 2026-06-12
// @Author baopao
// @Author jwrl
// @Created 2016-05-12

/**
 This is an enhanced version of Sinusoidal lights, a semi-abstract pattern generator
 created by Lightworks user baopao.  This modified version adds colour to the lights
 and also provides a background colour gradient.  In the conversion the range and
 type of some parameters have been altered from baopao's originals, and now provide
 the ability to interactively adjust parameters by dragging in the sequence viewer.

   [*]Pattern
      [*]Star number:  Sets the number of stars in the pattern. Has a dramatic effect
         on the look of the effect.
      [*]Speed:  Sets the speed at which the pattern changes.
      [*]Scale:  Scales the over all pattern size.
      [*]Glow:  Adjusts the glow amount around the stars.
      [*]Position X:   Adjusts the horizontal position of the star pattern.
      [*]Position Y:   Adjusts the vertical position of the star pattern.
      [*]Size X:  Adjusts the width of the star pattern.
      [*]Size Y:  Adjusts the height of the star pattern.
      [*]Frequency X:  Sets the horizontal frequency.
      [*]Frequency Y:  Sets the vertical frequency.
      [*]Colour:  Sets the colour of the stars.
   [*]Background
      [*]Video mix:  Mixes the external video into the background.
      [*]Top left:  Sets the top left colour of the background.
      [*]Top right:  Sets the top right colour of the background.
      [*]Bottom left:  Sets the bottom left colour of the background.
      [*]Bottom right:  Sets the bottom right colour of the background.

This effect is based on the Lissajou code at http://glslsandbox.com/e#9996.0.  The
 conversion was originally done by baopao with subsequent work by jwrl.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SinusoidalLights.fx
//
// Version history:
//
// Updated 2026-06-12 jwrl.
// Added settings to header.
// Changed "Glow Intensity" to "Glow".
// Changed "External Video" to "Video mix".
// Masking now uses RGBA instead of R.
//
// Updated 2023-05-14 jwrl.
// Header reformatted.
//
// Conversion 2023-01-23 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Sinusoidal lights", "Mattes", "Backgrounds", "A pattern generator that creates coloured stars in Lissajou curves over a coloured background", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (StarNumber, "Star number", "Pattern", kNoFlags, 200.0, 0.0, 400.0);
DeclareFloatParam (Speed, "Speed", "Pattern", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Scale, "Scale", "Pattern", kNoFlags, 0.33, 0.0, 1.0);
DeclareFloatParam (Level, "Glow", "Pattern", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (CentreX, "Position", "Pattern", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Position", "Pattern", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (ResX, "Size", "Pattern", "SpecifiesPointX", 0.4, 0.01, 2.0);
DeclareFloatParam (ResY, "Size", "Pattern", "SpecifiesPointY", 0.4, 0.01, 2.0);

DeclareFloatParam (SineX, "Frequency", "Pattern", "SpecifiesPointX", 4.0, 0.0, 12.0);
DeclareFloatParam (SineY, "Frequency", "Pattern", "SpecifiesPointY", 8.0, 0.0, 12.0);

DeclareColourParam (fgdColour, "Colour", "Pattern", kNoFlags, 0.85, 0.75, 0.0);

DeclareFloatParam (extBgd, "Video mix", "Background", kNoFlags, 0.0, 0.0, 1.0);

DeclareColourParam (topLeft, "Top left", "Background", kNoFlags, 0.375, 0.5, 0.75);
DeclareColourParam (topRight, "Top right", "Background", kNoFlags, 0.375, 0.375, 0.75);
DeclareColourParam (botLeft, "Bottom left", "Background", kNoFlags, 0.375, 0.625, 0.75);
DeclareColourParam (botRight, "Bottom right", "Background", kNoFlags, 0.375, 0.5625, 0.75);

DeclareFloatParam (_Progress);
DeclareFloatParam (_Length);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (SinusoidalLights)
{
   float4 fgdPat = float4 (fgdColour.rgb, 1.0);

   float scale_X    = Scale * 3.0;
   float scale_Y    = scale_X * ResY / _OutputAspectRatio;
   float sum        = 0.0;
   float time       = _Progress * (1.0 - Speed) * _Length;
   float Curve      = SineX * 12.5;
   float keyClip    = scale_X / ((19.0 - (Level * 14.0)) * 100.0);
   float curve_step = 0.0;
   float time_step;

   scale_X *= ResX;

   float2 position;

   for (int i = 0; i < StarNumber; ++i) {
      time_step = (float (i) + time) / 5.0;

      position.x = sin (SineY * time_step + curve_step) * scale_X;
      position.y = sin (time_step) * scale_Y;

      sum += keyClip / length (uv0 - position - 0.5.xx);
      curve_step += Curve;
      }

   fgdPat.rgb *= sum;
   sum = saturate ((sum * 1.5) - 0.25);

   float4 retval = lerp (topLeft, topRight, uv0.x);
   float4 Bgnd   = ReadPixel (Inp, uv1);

   retval = lerp (retval, lerp (botLeft, botRight, uv0.x), uv0.y);
   retval = lerp (retval, Bgnd, extBgd);
   retval = lerp (retval, fgdPat, sum);
   retval.a = 1.0;

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}
