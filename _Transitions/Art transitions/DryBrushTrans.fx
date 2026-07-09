// @Maintainer jwrl
// @Released 2026-07-09
// @Author jwrl
// @Created 2018-05-06

/**
 This mimics the Photoshop angled brush stroke effect to reveal or remove a clip.
 The stroke length and angle can be independently adjusted.  Keyframing the progress
 while the transition proceeds can also make the effect more dynamic.

   [*]Amount:  The transition progress.
   [*]Stroke
      [*]Length:  Sets the length of the dry brush stroke.
      [*]Angle:   Adjusts the brush stroke angle between -180 and +180 degrees.
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
// Lightworks user effect DryBrushTrans.fx
//
// Version history:
//
// Updated 2026-07-09 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-12 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-03-06 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Dry brush transition", "Mix", "Art transitions", "Mimics the Photoshop angled brush effect to reveal the next video", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",        kNoGroup,         kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Length,         "Length",        "Stroke",         kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Angle,          "Angle",         "Stroke",         kNoFlags, 45.0, -180.0, 180.0);

DeclareBoolParam  (Blended,        "Enable blend transitions",        kNoGroup, false);

DeclareIntParam   (Source,         "Source",        "Blend settings", 0, "Extracted foreground|Image key or title (disconnect input)");
DeclareBoolParam  (SwapDir,        "Transition into blend",           "Blend settings", true);
DeclareFloatParam (KeyGain,        "Fine tune",     "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam  (ShowKey,        "Show foreground key",             "Blend settings", false);
DeclareBoolParam  (SwapSource,     "Swap sources",  "Blend settings", false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_rnd (float2 uv)
{
   return frac (sin (dot (uv - 0.5.xx, float2 (12.9898, 78.233))) * 43758.5453);
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

   if (Fgnd.a == 0.0) Fgnd = kTransparentBlack;

   return Fgnd;
}

DeclarePass (Bgd)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

DeclareEntryPoint (DryBrushTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 maskBg, retval;

   float stroke = (Length * 0.1) + 0.02;
   float amount, angle = radians (Angle + 135.0);

   float2 xy1, xy2, xy3;

   sincos (angle, xy1.x, xy1.y);

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         amount = SwapDir ? Amount : 1.0 - Amount;

         xy2 = fn_rnd (uv3) * stroke * (1.0 - amount);
         xy3.x = uv3.x + (xy2.x * xy1.x) + (xy2.y * xy1.y);
         xy3.y = uv3.y + (xy2.y * xy1.x) - (xy2.x * xy1.y);

         Fgnd = tex2D (Fgd, xy3);
         retval = lerp (Bgnd, Fgnd, amount);
         retval.a = Fgnd.a;
      }
   }
   else {
      amount = Amount;

      xy2 = fn_rnd (uv3 - 0.5.xx) * stroke * amount;
      xy3.x = uv3.x + (xy2.x * xy1.x) + (xy2.y * xy1.y);
      xy3.y = uv3.y + (xy2.y * xy1.x) - (xy2.x * xy1.y);

      float2 xy4;

      xy2 = fn_rnd (uv3 - 0.5.xx) * stroke * (1.0 - amount);
      xy4.x = uv3.x + (xy2.x * xy1.x) + (xy2.y * xy1.y);
      xy4.y = uv3.y + (xy2.y * xy1.x) - (xy2.x * xy1.y);

      Bgnd = tex2D (Bgd, xy4);

      Fgnd = tex2D (Fgd, xy3);
      retval = lerp (Fgnd, Bgnd, Fgnd.a * amount);
   }

   return retval;
}
