// @Maintainer jwrl
// @Released 2026-07-15
// @Author jwrl
// @Created 2017-08-26

/**
 This is similar to the alpha corner squeeze effect, except that it expands the blended
 foreground from the corners or compresses it to the corners of the screen.

   [*]Amount:  The normal keyframed transition progress.
   [*]Transition:  Sets the squeeze / expansion mode. Overriden in blend mode.
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
// User effect CornerSqueezeTrans.fx
//
// Version history:
//
// Updated 2026-07-15 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with 0.0.xxxx to fix Linux lerp()/mix() bug.
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

DeclareLightworksEffect ("Corner squeeze transition", "Mix", "Transform transitions", "Squeezes or expands the foreground to or from the corners of the screen", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",       kNoGroup,         kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam   (Ttype,          "Transition",   kNoGroup,         0, "Squeeze to corners|Expand from corners");
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

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }

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

DeclarePass (Horiz)
{
   float4 retval;

   float negAmt, posAmt;

   float2 xy1, xy2;

   if ((Blended && SwapDir) || (!Blended && Ttype)) {
      negAmt = Amount * 0.5;
      posAmt = 1.0 - negAmt;

      xy1 = float2 ((uv3.x + Amount - 1.0) / Amount, uv3.y);
      xy2 = float2 (uv3.x / Amount, uv3.y);
   }
   else {
      negAmt = 1.0 - Amount;
      posAmt = (1.0 + Amount) * 0.5;

       xy1 = float2 ((uv3.x - Amount) / negAmt, uv3.y);
       xy2 = float2 (uv3.x / negAmt, uv3.y);

       negAmt *= 0.5;
   }

   if (!Blended && Ttype) {
      retval = (uv3.x > posAmt) ? tex2D (Bgd, xy1)
             : (uv3.x < negAmt) ? tex2D (Bgd, xy2) : kTransparentBlack;
   }
   else retval = (uv3.x > posAmt) ? tex2D (Fgd, xy1) :
                 (uv3.x < negAmt) ? tex2D (Fgd, xy2) : kTransparentBlack;

   return retval;
}

DeclareEntryPoint (CornerSqueezeTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);

   if (Blended && ShowKey) { return Fgnd; }

   float4 Bgnd = tex2D (Bgd, uv3);
   float4 retval = !Blended && Ttype ? Fgnd : Bgnd;

   float negAmt, posAmt;

   float2 xy1, xy2;

   if ((Blended && SwapDir) || (!Blended && Ttype)) {
      negAmt = Amount * 0.5;
      posAmt = 1.0 - negAmt;

      xy1 = float2 (uv3.x, (uv3.y + Amount - 1.0) / Amount);
      xy2 = float2 (uv3.x, uv3.y / Amount);
   }
   else {
      negAmt = 1.0 - Amount;
      posAmt = (1.0 + Amount) * 0.5;

      xy1 = float2 (uv3.x, (uv3.y - Amount) / negAmt);
      xy2 = float2 (uv3.x, uv3.y / negAmt);

      negAmt *= 0.5;
   }

   Fgnd = (uv3.y > posAmt) ? tex2D (Horiz, xy1) :
          (uv3.y < negAmt) ? tex2D (Horiz, xy2) : kTransparentBlack;

   return lerp (retval, Fgnd, Fgnd.a);
}
