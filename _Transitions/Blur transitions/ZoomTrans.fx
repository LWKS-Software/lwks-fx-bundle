// @Maintainer jwrl
// @Released 2026-07-17
// @Author jwrl
// @Created 2016-05-07

/**
 This effect either:
   Zooms into the outgoing image as it dissolves to the new image which zooms in to
   fill the frame.
 OR
   Zooms out of the outgoing image and dissolves to the new one while it's zooming out
   to full frame.
 OR
   Zooms in or out to transition into or out of blended and keyed foreground layers.

   [*]Amount:  The normal keyframed transition progress.
   [*]Zoom settings
      [*]Direction:  Sets the zoom direction to be zoom in or zoom out.
      [*]Strength:  Sets the strength of the zoom.
      [*]Centre X:  Sets the horizontal centre point of the zoom.
      [*]Centre Y:  Sets the vertical centre point of the zoom.
   [*]Enable blend transitions:  Changes the mode from opaque video to transparent
      video such as titles and the like.
   [*]Blend settings
      [*]Source:  Selects between an extracted video source and transparent video.
      [*]Transition into blend:  Selects between transitioning into or out of a
         blended video source.
      [*]Fine tune:  Fine tunes the separation of an extracted video source from
         its background.
      [*]Show foreground key:  Showing the key helps in setting up the clip.
      [*]Swap sources:  This can be necessary when using a folded delta key
         (extracted) transition.

 NOTE:  This effect has been revised for Lightworks version 2026 and higher.  Part of
 the revision process has meant the removal of masking.  In all other respects this
 behaves as the earlier versions did, and can be installed on any Lightworks version
 above 2022.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ZoomTrans.fx
//
// Version history:
//
// Updated 2026-07-17 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Updated 2023-08-05 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-08 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Zoom transition", "Mix", "Blur transitions", "Zooms in or out of the video to establish or remove it", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",       kNoGroup,         kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam   (Direction,      "Direction",    "Zoom settings",  0, "Zoom in|Zoom out");
DeclareFloatParam (zoomAmount,     "Strength",     "Zoom settings",  kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Xcentre,        "Centre",       "Zoom settings",  "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ycentre,        "Centre",       "Zoom settings",  "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareBoolParam  (Blended,        "Enable blend transitions",       kNoGroup, false);

DeclareIntParam   (Source,         "Source",       "Blend settings", 0, "Extracted foreground|Image key or title (disconnect input)");
DeclareBoolParam  (SwapDir,        "Transition into blend",          "Blend settings", true);
DeclareFloatParam (KeyGain,        "Fine tune",    "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam  (ShowKey,        "Show foreground key",            "Blend settings", false);
DeclareBoolParam  (SwapSource,     "Swap sources", "Blend settings", false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HALF_PI   1.5707963268

#define SAMPLE  61
#define DIVISOR 61.0

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_zoom (sampler S, float2 uv)
{
   float4 retval;

   if (zoomAmount == 0.0) { retval = tex2D (S, uv); }
   else {
      float zoomStrength, scale;

      if (SwapDir) {
         zoomStrength = zoomAmount * (1.0 - Amount);
         scale = Direction ? 1.0 - zoomStrength : 1.0;
      }
      else {
         zoomStrength = zoomAmount * Amount;
         scale = Direction ? 1.0 : 1.0 - zoomStrength;
      }

      zoomStrength /= SAMPLE;

      float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
      float2 xy1, xy2 = uv - zoomCentre;

      retval = kTransparentBlack;

      for (int i = 0; i < SAMPLE; i++) {
         xy1 = (xy2 * scale) + zoomCentre;
         retval += tex2D (S, xy1);
         scale += zoomStrength;
      }

      retval /= DIVISOR;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   if (!Blended) return float4 ((ReadPixel (Fg, uv1)).rgb, 1.0);

   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (Bg, uv2);
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      Fgnd = ReadPixel (Fg, uv1);
      Bgnd = ReadPixel (Bg, uv2);
   }

   if (Source == 0) Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));

   // If alpha is zero we need any video to be blanked.  We do NOT need it to be
   // multiplied, so this is the simplest way to fix things.

   return Fgnd.a == 0.0 ? kTransparentBlack : Fgnd;
}

DeclarePass (Bgd)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

DeclarePass (Super)
{ return Blended ? fn_zoom (Fgd, uv3) : tex2D (Fgd, uv3); }

DeclareEntryPoint (ZoomTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 retval;

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         Fgnd = fn_zoom (Super, uv3);

         float amount = SwapDir ? Amount : 1.0 - Amount;

         retval = lerp (Bgnd, Fgnd, Fgnd.a);
         retval = lerp (Bgnd, retval, retval.a * amount);
      }
   }
   else {
      if (zoomAmount > 0.0) {
         float strength_1, strength_2, scale_1 = 1.0, scale_2 = 1.0;

         sincos (Amount * HALF_PI, strength_2, strength_1);

         strength_1 = zoomAmount * (1.0 - strength_1);
         strength_2 = zoomAmount * (1.0 - strength_2);

         if (Direction == 0) scale_1 -= strength_1;
         else scale_2 -= strength_2;

         float2 centreXY = float2 (Xcentre, 1.0 - Ycentre);
         float2 xy0 = uv3 - centreXY;
         float2 xy1, xy2;

         strength_1 /= SAMPLE;
         strength_2 /= SAMPLE;

         for (int i = 0; i <= SAMPLE; i++) {
            xy1 = xy0 * scale_1 + centreXY;
            xy2 = xy0 * scale_2 + centreXY;
            Fgnd += tex2D (Fgd, xy1);
            Bgnd += tex2D (Bgd, xy2);
            scale_1 += strength_1;
            scale_2 += strength_2;
         }

         Fgnd /= DIVISOR;
         Bgnd /= DIVISOR;
      }

      retval = lerp (Fgnd, Bgnd, Amount);
   }

   return retval;
}
