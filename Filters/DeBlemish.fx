// @Maintainer jwrl
// @Released 2026-08-08
// @Author jwrl
// @Created 2019-01-30

/**
 This is a skin blemish removal tool similar in concept to "Skin smooth".  It uses a
 different technique than that effect to mask skin tones, which should make it easier
 to set up.  The default skin colour has been tested to work quite well with European
 and Asian flesh tones but may need adjustment with darker skins or poorly lit ones.
 The blur technique used is a radial one, which differs from the skin smooth effect.
 Even if the flesh tone mask obtained is hard edged it will be blurred along with the
 video, ensuring a smooth blend is achieved.

   [*] Blur strength: Sets the blurriness strength to apply to the skin tone.
   [*] Blur mix: Adjusts the amount of blurred skin tone to mix back over the
       original.
   [*] Skin tone masking
      [*] Show mask: Shows the area that the skin mask covers.
      [*] Skin colour: Selects the skin colour to detect.
      [*] Mask clip: Adjusts skin colour detection range. Spreads or reduces
          the mask area.
      [*] Separation: Refines the mask detection.
      [*] Linearity: Softens the mask edges.
      [*] White clip: Flattens the mask peaks.
      [*] Black crush: Erodes the mask boundaries.

 To use it, start with every setting on their defaults and select the flesh tone you
 need using the "Skin colour" eyedropper on your image.  Enable "Show mask" and trim
 "Mask clip" to get the cleanest result that you can.  The "Separation" control will
 also help to get a reasonably clean mask.

 At this point more fine tuning may be unnecessary.  If that's so you can skip to the
 next paragraph.  If you do need further fine tuning start by adjusting "Linearity"
 to improve the flesh tone mask contrast.  Next fine tune the mask strength with
 "White clip" to make the flesh tone mask as bright as you can, then adjust "Black
 crush".  These three controls interact, so you may need to adjust them several times
 several times to get best results.  You can also crop rhe flesh tone mask with the
 Lightworks masks built in to this effect.

 Once the flesh tone mask is as you want it turn off "Show mask" and confirm that
 "Blur mix" is set to 100%.  That way you will be able to clearly see the blurred
 flesh tones as you apply the final settings.  Adjust "Blur strength" for the best
 smoothing.  Once you're happy with it ease the "Blur mix" back to mix in some of the
 original image.  This will improve the apparent sharpness of the end result.

 Those last two adjustments don't really interact, but they can certainly appear to
 in some cases.  Be prepared to trim one then the other a few times for best results.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect DeBlemish.fx
//
// Version history:
//
// Updated 2026-08-08 jwrl.
// Changed masking to use RGB, not A.
//
// Updated 2026-06-22 jwrl.
// Changed "Mask separation" to "Separation".
// Changed "Mask linearity" to "Linearity".
// Expanded the header text.
// Changed masking to use RGBA.
//
// Updated 2025-11-15 jwrl.
// Changed "Mask settings" to "Skin tone masking".
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with 0.0.xxxx for Linux fix.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("De-blemish", "Stylize", "Filters", "Smooths skin tones to reduce visible skin blemishes using a radial blur", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam  (Size,       "Blur strength", kNoGroup,            kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam  (Amount,     "Blur mix",      kNoGroup,            kNoFlags, 1.0, 0.0, 1.0);

DeclareBoolParam   (ShowMask,   "Show mask",     "Skin tone masking", false);
DeclareColourParam (MaskColour, "Skin colour",   "Skin tone masking", kNoFlags, 0.945, 0.7765, 0.663);
DeclareFloatParam  (MaskClip,   "Mask clip",     "Skin tone masking", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam  (MaskSep,    "Separation",    "Skin tone masking", kNoFlags, 0.5,  0.0, 1.0);
DeclareFloatParam  (MaskGamma,  "Linearity",     "Skin tone masking", kNoFlags, 0.5,  0.0, 1.0);
DeclareFloatParam  (MaskWhite,  "White clip",    "Skin tone masking", kNoFlags, 1.0,  0.0, 1.0);
DeclareFloatParam  (MaskBlack,  "Black crush",   "Skin tone masking", kNoFlags, 0.0,  0.0, 1.0);

DeclareFloatParam  (_OutputAspectRatio);

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

DeclarePass (Input)
{
   float4 Fgnd = ReadPixel (Inp, uv1);       // First get the input to process

   // Before we do anything set up the crop, allowing for Inp rotation.

   float3 Fhsv = fn_hsv (Fgnd.rgb);          // Convert it to our modified HSV
   float3 Chsv = fn_hsv (MaskColour.rgb);    // Do the same for the ref colour

   // Calculate the chroma difference.  Since what we want is actually the dark
   // sections of the mask, we double and clip it before any further processing.

   float cDiff = min (distance (Fhsv, Chsv) * 2.0, 1.0);

   // Now we generate the mask, adjusting clip and slope first then inverting it

   float mask  = 1.0 - smoothstep (MaskClip, MaskClip + MaskSep, cDiff);

   // Mask linearity is actually a gamma setting and runs from 0.01 to 4.0.  It's
   // also inverted at this stage, so that the power is actually from 100 to 0.25

   float gamma = 1.0 / pow (MIN_GAMMA + (MAX_GAMMA * MaskGamma), 2.0);

   // The black crush factor is limited to the range 0.0 - 0.9

   float black = saturate (MaskBlack) * LEVELS;

   // The mask is adjusted for gamma and black crush.

   mask = (pow (mask, gamma) - black) / (1.0 - black);

  // It is now white clipped and applied to the alpha channel of our image.

   Fgnd.a = saturate (mask / ((MaskWhite * LEVELS) + OFFSET));

   return Fgnd;
}

DeclareEntryPoint (DeBlemish)
{
   float4 source = ReadPixel (Inp, uv1);        // First get the input to process
   float4 MaskTex = ReadPixel (Mask, uv1);      // Also get the mask data
   float4 retval  = tex2D (Input, uv2);         // Get the colour masked input

   if (ShowMask) return retval.aaaa;            // Show it if we need to

   float4 Fgnd = ReadPixel (Inp, uv1);          // Now get the raw input

   if ((Size > 0.0) && (Amount > 0.0)) {        // Process the image if required

      float angle = 0.0;                        // Set the blur rotation to zero

      // Calculate the blur radius based on size and aspect ratio.

      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * Size * RADIUS;

      // In the blur loop we do two samples at 180 degree offsets, then another
      // two in which the sample offset is doubled, for a total of four samples
      // for each iteration of the loop.  Rather than multiply the angle by i
      // each time we go round we do a simple addition for the same result.

      for (int i = 0; i < LOOP; i++) {
         sincos (angle, xy.x, xy.y);
         xy *= radius;
         retval += tex2D (Input, uv2 + xy);
         retval += tex2D (Input, uv2 - xy);
         xy += xy;
         retval += tex2D (Input, uv2 + xy);
         retval += tex2D (Input, uv2 - xy);
         angle  += ANGLE;
      }

      retval /= DIVIDE;

      // The blurred flesh tones are now keyed into the original footage
      // using the blurred mask.  The original alpha value is preserved.

      Fgnd.rgb = lerp (Fgnd.rgb, retval.rgb, retval.a * Amount);
   }

   Fgnd = lerp (0.0.xxxx, Fgnd, source.a);      // If alpha is zero make Fgnd black

   // In 2026 it was found that using the alpha channel of the Lightworks mask was
   // unreliable.  Discarding that and using the best of RGB gave better results.
   // THIS AN EMPIRICAL FIX ONLY!!!!

   float MaskAlpha = max (MaskTex.r, max (MaskTex.g, MaskTex.b));

   return lerp (source, Fgnd, MaskAlpha);
}
