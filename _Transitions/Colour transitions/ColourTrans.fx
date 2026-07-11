// @Maintainer jwrl
// @Released 2026-07-11
// @Author jwrl
// @Created 2018-09-27

/**
 This is a modified version of "Colour gradient transition" but is very much simpler
 to use.  Apply it as you would a dissolve, adjust the duration of the dissolve that
 you want to be colour and set the colour to whatever you want.  You can also mix the
 colour with a black and white mixture of the outgoing and incoming video.

   [*]Amount:  The transition progress.
   [*]Colour setup
      [*]Duration:  Sets the centre colour duration.
      [*]Colour:  Sets the colour to be used in the mix.
      [*]Colour mix:  Sets the colour transparency.
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

 The effect defaults to a 50% mix of a blue colour with the black and white mixture of
 the video inputs.  That mix in turn defaults to a duration of 10% of the transition.
 Setting the colour mix to a negative value fades the colour out.

 NOTE:  This effect has been revised for Lightworks version 2026 and higher.  Part of
 the revision process has meant the removal of masking.  In all other respects this
 behaves as the earlier versions did, and can be installed on any Lightworks version
 above 2022.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourTrans.fx
//
// Version history:
//
// Updated 2026-07-11 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-08 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-05-05 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Colour transition", "Mix", "Colour transitions", "Dissolves to a user defined colour then from that to the incoming image", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",        kNoGroup,        kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam  (cDuration,     "Duration",      "Colour setup",  kNoFlags, 0.1, 0.0, 1.0);
DeclareColourParam (Colour,        "Colour",        "Colour setup",  kNoFlags, 0.016, 0.306, 0.608, 1.0);
DeclareFloatParam  (cMix,          "Colour mix",    "Colour setup",  kNoFlags, 0.5, -1.0, 1.0);

DeclareBoolParam   (Blended,       "Enable blend transitions",       kNoGroup, false);

DeclareIntParam    (Source,        "Source",        "Blend settings", 0, "Extracted foreground|Image key or title (disconnect input)");
DeclareBoolParam   (SwapDir,       "Transition into blend",           "Blend settings", true);
DeclareFloatParam  (KeyGain,       "Fine tune",     "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam   (ShowKey,       "Show foreground key",             "Blend settings", false);
DeclareBoolParam   (SwapSource,    "Swap sources",  "Blend settings", false);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_colour (float4 Fgnd, float4 Bgnd, float amt)
{
   float4 Csub, retval;

   float mix_bgd = min (1.0, (1.0 - amt) * 2.0);
   float mix_fgd = min (1.0, amt * 2.0);
   float cAmt;

   if (cDuration < 1.0) {
      float duration = 1.0 - cDuration;

      mix_bgd = min (1.0, mix_bgd / duration);
      mix_fgd = min (1.0, mix_fgd / duration);
   }
   else {
      mix_bgd = 1.0;
      mix_fgd = 1.0;
   }

   if (cMix < 0.0) {
      cAmt = saturate (-cMix);
      retval = lerp (Bgnd, Fgnd, 0.5);
   }
   else {
      cAmt = saturate (cMix);
      Csub = Fgnd + Bgnd;
      Csub.a = max (Fgnd.a, Bgnd.a);
      retval = float4 (dot (Csub.rgb, float3 (0.299, 0.587, 0.114)).xxx, Csub.a);
   }

   Csub   = saturate (lerp (Colour, retval, cAmt));

   return lerp (Bgnd, lerp (Fgnd, Csub, mix_fgd), mix_bgd);
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

DeclareEntryPoint (ColourTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 retval;

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         float amt = SwapDir ? 1.0 - Amount : Amount;

         retval = lerp (Bgnd, fn_colour (Fgnd, Bgnd, amt), Fgnd.a);
      }
   }
   else retval = fn_colour (Fgnd, Bgnd, Amount);

   return retval;
}
