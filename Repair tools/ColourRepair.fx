// @Maintainer jwrl
// @Released 2026-06-19
// @Author jwrl
// @Created 2026-03-02

/**
 This is based on skin blemish removal tools but smooths any colour, whether flesh
 tones or not.  It's similar in concept to "Deblemish" and "Skin smooth" but allows
 the user to set the colour instead instead of using the predefined skin tones that
 those two effects provide.  As a result any arbitrary colour value you wish may be
 selected to be smoothed.  Lightworks masking also helps to adjust where and how
 much correction is appplied.  While it isn't intended for that purpose, the effect
 could also be used for skin blemish removal.

   [*] Blurriness: Sets the blurriness to apply to the masked colour.
   [*] Blur mix: Adjusts the amount of masked and blurred colour to mix back over
       the original.
   [*] Colour matching
      [*] Show match: Shows the area that the colour matching covers.
      [*] Reference: Selects the colour to repair.
      [*] Trim match: Adjusts colour selection. Spreads or reduces the matched area.
      [*] Separation: Refines the match detection.
      [*] Linearity: Softens the match boundaries.
      [*] White clip: Flattens the peaks of the match boundaries.
      [*] Black crush: Erodes the match boundaries.

 The blur technique used is a variant of my radial blur, which also differs from the
 skin smooth effect.  The colour mask produced can be quite hard edged, so it will
 blurred along with the video ensuring a smooth blend.  The Lightworks mask is not
 affected at all by this process.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourRepair.fx
//
// Version history:
//
// Rebuilt 2026-06-19 jwrl.
// This is a complete rewrite of the March 2026 version.  While the original worked on
// Windows it was found not to compile at all on Linux or Mac.  There was no indication
// of why it failed, and after several days attempting to debug the original, it was
// found simpler to start over from scratch.  When its stability cross platform was
// proven modifications were then made to relabel the settings to fit with 2026 needs.
//
// As a result these settings have changed:
//   "Blur strength" is now "Blurriness".
//   "Reference colour" is now "Reference".
//   "Match clip" is now "Trim match".
//   "Match separation" is now "Separation".
//   "Match linearity" is now "Linearity".
// Also the effect input, "Inp" was inadvertently changed to "Input" in the rewrite.
//
// Original build 2026-03-02 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Colour repair", "Stylize", "Repair tools", "Reduces minor colour damage using a radial blur", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam  (Size,        "Blurriness",  kNoGroup,          kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam  (Amount,      "Blur mix",    kNoGroup,          kNoFlags, 1.0, 0.0, 1.0);

DeclareBoolParam   (ShowMatch,   "Show match",  "Colour matching", false);
DeclareColourParam (RefColour,   "Reference",   "Colour matching", kNoFlags, 0.15, 0.65, 0.73);
DeclareFloatParam  (MatchClip,   "Trim match",  "Colour matching", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam  (MatchSep,    "Separation",  "Colour matching", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam  (MatchLinear, "Linearity",   "Colour matching", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam  (MaskWhite,   "White clip",  "Colour matching", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam  (MaskBlack,   "Black crush", "Colour matching", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define MIN_GAMMA 0.316227766
#define MAX_GAMMA 1.683772234

#define LEVELS    0.9
#define OFFSET    1.0 - LEVELS

#define LOOP      12
#define DIVIDE    49
#define ANGLE     0.2617993878
#define RADIUS    0.002

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float3 fn_hsv (float3 rgb)
{
   // This is a standard HSV converter, so it isn't commented except where it
   // differs from normal practice

   float val = max (rgb.r, max (rgb.g, rgb.b));
   float rng = val - min (rgb.r, min (rgb.g, rgb.b));
   float hue, sat = rng / val;

   if (sat == 0.0) { hue = 0.0; }
   else {
      if (rgb.r == val) {
         hue = (rgb.g - rgb.b) / rng;

         if (hue < 0.0) hue += 6.0;
      }
      else if (rgb.g == val) { hue = 2.0 + ((rgb.b - rgb.r) / rng); }
      else hue = 4.0 + ((rgb.r - rgb.g) / rng);

      // Normally we would have hue /= 6.0 here, but not doing that gives us
      // a steeper slope when we actually generate the key in the main code.
   }

   return float3 (hue, sat, val);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Inp)
{
   float4 Fgnd = ReadPixel (Input, uv1);        // First get the input to process

   // Before we do anything set up the crop, allowing for Input rotation.

   float3 Fhsv = fn_hsv (Fgnd.rgb);             // Convert it to our modified HSV
   float3 Chsv = fn_hsv (RefColour.rgb);        // Do the same for the ref colour

   // Calculate the chroma difference.  Since what we want is actually the dark
   // sections of the mask, we double and clip it before any further processing.

   float cDiff = min (distance (Fhsv, Chsv) * 2.0, 1.0);

   // Now we generate the mask, adjusting clip and slope first then inverting it

   float mask  = 1.0 - smoothstep (MatchClip, MatchClip + MatchSep, cDiff);

   // Mask linearity is actually a gamma setting and runs from 0.01 to 4.0.  It's
   // also inverted at this stage, so that the power is actually from 100 to 0.25

   float gamma = 1.0 / pow (MIN_GAMMA + (MAX_GAMMA * MatchLinear), 2.0);

   // The black crush factor is limited to the range 0.0 - 0.9

   float black = saturate (MaskBlack) * LEVELS;

   // The mask is adjusted for gamma and black crush.

   mask = (pow (mask, gamma) - black) / (1.0 - black);

  // It is now white clipped and applied to the alpha channel of our image.

   Fgnd.a = saturate (mask / ((MaskWhite * LEVELS) + OFFSET));

   return Fgnd;
}

DeclareEntryPoint (ColourFixer)
{
   float4 retval = tex2D (Inp, uv2);            // Get the masked input

   if (ShowMatch) return retval.aaaa;           // Show it if we need to

   float4 Fgnd   = ReadPixel (Input, uv1);      // Now get the raw input
   float4 refInp = Fgnd;                        // Save it for later reference

   if ((Size > 0.0) && (Amount > 0.0)) {        // Process the image if required

      float angle = 0.0;                        // Set the blur rotation to zero

      // Calculate the blur radius based on size and aspect ratio.

      float2 radius = float2 (1.0, _OutputAspectRatio) * Size * RADIUS;
      float2 xy, xy1, xy2, xy3, xy4;

      // In the blur loop we do two samples at 180 degree offsets, then another
      // two in which the sample offset is doubled, for a total of four samples
      // for each iteration of the loop.  Rather than multiply the angle by i
      // each time we go round we do a simple addition for the same result.

      for (int i = 0; i < LOOP; i++) {
         sincos (angle, xy.x, xy.y);
         xy *= radius;
         xy1 = uv2 + xy; xy2 = uv2 - xy;
         xy3 = xy1 + xy; xy4 = xy2 - xy;
         retval += tex2D (Inp, xy1);
         retval += tex2D (Inp, xy2);
         retval += tex2D (Inp, xy3);
         retval += tex2D (Inp, xy4);
         angle  += ANGLE;
      }

      retval /= DIVIDE;

      // The blurred matched colour is now dropped into the original media
      // using the blurred mask.  The original alpha value is preserved.

      Fgnd.rgb = lerp (Fgnd.rgb, retval.rgb, retval.a * Amount);
   }

   Fgnd = lerp (0.0.xxxx, Fgnd, refInp.a);

   return lerp (refInp, Fgnd, tex2D (Mask, uv1));
}
