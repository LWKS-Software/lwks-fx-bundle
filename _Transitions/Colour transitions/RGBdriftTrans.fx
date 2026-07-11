// @Maintainer jwrl
// @Released 2026-07-11
// @Author jwrl
// @Created 2018-04-14

/**
 This transitions two images or a blended foreground image in or out using different curves
 for each of red, green and blue.  One colour and alpha is always linear, and the other two
 can be set using the colour profile selection.

   [*]Amount:  The transition progress.
   [*]Profile: Sets the mix profile used in the transition.
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
// Lightworks user effect RGBdriftTrans.fx
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
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("RGB drift transition", "Mix", "Colour transitions", "Mixes sources using varying curves for red, green and blue", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",        kNoGroup,        kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam   (Profile,        "Select colour profile",          kNoGroup, 0, "Red to blue|Blue to red|Red to green|Green to red|Green to blue|Blue to green");
DeclareBoolParam  (Blended,        "Enable blend transitions",       kNoGroup, false);

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

#define CURVE 4.0

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_RGBdrifter (float4 Fgnd, float4 Bgnd, float amt)
{
   float4 retval = lerp (Fgnd, Bgnd, amt);

   float amt_1 = pow (1.0 - amt, CURVE);
   float amt_2 = pow (amt, CURVE);

   int prfl = int (Profile / 2);

   if (Profile - (2 * prfl)) {
      float amt_3 = amt_1;
      amt_1 = 1.0 - amt_2;
      amt_2 = 1.0 - amt_3;
   }

   if (prfl == 0) {
      retval.r = lerp (Bgnd.r, Fgnd.r, amt_1);
      retval.b = lerp (Fgnd.b, Bgnd.b, amt_2);
   }
   else if (prfl == 1) {
      retval.r = lerp (Bgnd.r, Fgnd.r, amt_1);
      retval.g = lerp (Fgnd.g, Bgnd.g, amt_2);
   }
   else {
      retval.g = lerp (Bgnd.g, Fgnd.g, amt_1);
      retval.b = lerp (Fgnd.b, Bgnd.b, amt_2);
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

   if (Fgnd.a == 0.0) Fgnd = kTransparentBlack;

   return Fgnd;
}

DeclarePass (Bgd)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

DeclareEntryPoint (RGBdriftTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 retval;

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         float amt = SwapDir ? 1.0 - Amount : Amount;

         retval = lerp (Bgnd, fn_RGBdrifter (Fgnd, Bgnd, amt), Fgnd.a);
      }
   }
   else retval = fn_RGBdrifter (Fgnd, Bgnd, Amount);

   return retval;
}
