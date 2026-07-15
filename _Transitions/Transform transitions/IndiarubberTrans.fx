// @Maintainer jwrl
// @Released 2026-07-15
// @Author jwrl
// @Created 2016-05-10

/**
 This effect stretches standard video or blended foreground horizontally or vertically
 to transition in or out.  It used to just be called "Stretch", but I like this name
 much better.

   [*]Amount:  The normal keyframed transition progress.
   [*]Transition direction:  Sets the primary stretch direction to either horizontal
      or vertical.
   [*]Size:  Sets the maximum size of the stretch.
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
// Lightworks user effect IndiarubberTrans.fx
//
// Version history:
//
// Updated 2026-07-15 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-14 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
// Changed subcategory from "DVE transitions" to "Transform transitions".
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Indiarubber transition", "Mix", "Transform transitions", "Stretches the foreground horizontally or vertically to reveal or remove it", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",       kNoGroup,         kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam   (SetTechnique,   "Transition direction",           kNoGroup, 0, "Stretch horizontal|Stretch vertical");
DeclareFloatParam (Stretch,        "Size",         kNoGroup,         kNoFlags, 0.5, 0.0, 1.0);
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

#define CENTRE  0.5.xx

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_initFg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   if (!Blended) return float4 ((ReadPixel (F, xy1)).rgb, 1.0);

   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (B, xy2);
      Bgnd = ReadPixel (F, xy1);
   }
   else {
      Fgnd = ReadPixel (F, xy1);
      Bgnd = ReadPixel (B, xy2);
   }

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }

   // If alpha is zero we need any video to be blanked.  We do NOT need it to be
   // multiplied, so this is the simplest way to fix things.

   return Fgnd.a == 0.0 ? kTransparentBlack : Fgnd;
}

float4 fn_initBg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (F, xy1) : ReadPixel (B, xy2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// technique Stretch_H

DeclarePass (Fg_H)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_H)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Stretch_H)
{
   float4 Fgnd = tex2D (Fg_H, uv3);
   float4 Bgnd = tex2D (Bg_H, uv3);
   float4 retval;

   float2 xy = uv3 - CENTRE;

   float distort = sin (xy.y * PI);
   float dissAmt, stretchAmt;

   distort = sin (distort * HALF_PI);

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         dissAmt = SwapDir ? 1.0 - Amount : Amount;
         stretchAmt = Stretch * dissAmt;
         distort /= 2.0;

         xy.x /= 1.0 + (5.0 * stretchAmt);
         xy.y  = lerp (xy.y, distort, stretchAmt);
         xy += CENTRE;

         Fgnd = tex2D (Fg_H, xy);
         retval = lerp (Bgnd, Fgnd, 1.0 - dissAmt);
         retval.a = Fgnd.a;
      }
   }
   else {
      dissAmt = saturate (lerp (Amount, ((1.5 * Amount) - 0.25), Stretch));
      stretchAmt = lerp (0.0, saturate (sin (Amount * PI)), Stretch);

      xy.x /= 1.0 + (5.0 * stretchAmt);
      xy.y = lerp (xy.y, distort / 2.0, stretchAmt);
      xy += CENTRE;

      Fgnd = ReadPixel (Fg_H, xy);
      Bgnd = ReadPixel (Bg_H, xy);
      retval = lerp (Fgnd, Bgnd, dissAmt);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique Stretch_V

DeclarePass (Fg_V)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_V)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Stretch_V)
{
   float4 Fgnd = tex2D (Fg_V, uv3);
   float4 Bgnd = tex2D (Bg_V, uv3);
   float4 retval;

   float2 xy = uv3 - CENTRE;

   float distort = sin (xy.x * PI);
   float dissAmt, stretchAmt;

   distort = sin (distort * HALF_PI);

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         dissAmt = SwapDir ? 1.0 - Amount : Amount;
         stretchAmt = Stretch * dissAmt;
         distort /= 2.0;

         xy.x = lerp (xy.x, distort, stretchAmt);
         xy.y /= 1.0 + (5.0 * stretchAmt);
         xy += CENTRE;

         Fgnd = tex2D (Fg_V, xy);
         retval = lerp (Bgnd, Fgnd, 1.0 - dissAmt);
         retval.a = Fgnd.a;
      }
   }
   else {
      dissAmt = saturate (lerp (Amount, ((1.5 * Amount) - 0.25), Stretch));
      stretchAmt = lerp (0.0, saturate (sin (Amount * PI)), Stretch);

      xy.x = lerp (xy.x, distort / 2.0, stretchAmt);
      xy.y /= 1.0 + (5.0 * stretchAmt);
      xy += CENTRE;

      Fgnd = ReadPixel (Fg_V, xy);
      Bgnd = ReadPixel (Bg_V, xy);
      retval = lerp (Fgnd, Bgnd, dissAmt);
   }

   return retval;
}
