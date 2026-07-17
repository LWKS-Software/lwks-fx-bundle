// @Maintainer jwrl
// @Released 2026-07-17
// @Author jwrl
// @Created 2017-11-08

/**
 This is a dissolve/wipe that uses sine & cos distortions to perform a rippling twist to
 transition between two images or to establish or remove the blended foreground.  The
 range of effect variations possible with different combinations of settings is almost
 inifinite.

   [*]Amount:  The normal keyframed transition progress.
   [*]Transition profile:  Selects one of four different profiles that are supported
      by this effect.
   [*]Ripples
      [*]Softness:
      [*]Amount:
      [*]Width:
   [*]Twists
      [*]Amount:
      [*]Show twist axis:
      [*]Twist axis:
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
// Lightworks user effect SoftTwistTrans.fx
//
// Version history:
//
// Updated 2026-07-17 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with 0.0.xxxx to fix Linux lerp()/mix() bug.
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-10 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-09 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Soft twist transition", "Mix", "Special Fx transitions", "Performs a rippling twist to transition between two video images", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",                kNoGroup,         kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam   (TransProfile,   "Transition profile",    kNoGroup,  1, "Left > right profile A|Left > right profile B|Right > left profile A|Right > left profile B");

DeclareFloatParam (Width,          "Softness",              "Ripples",        kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Ripples,        "Amount",                "Ripples",        kNoFlags, 0.6, 0.0, 1.0);
DeclareFloatParam (Spread,         "Width",                 "Ripples",        kNoFlags, 0.15, 0.0, 1.0);

DeclareFloatParam (Twists,         "Amount",                "Twists",         kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (Show_Axis,       "Show twist axis",       "Twists",         false);
DeclareFloatParam (Twist_Axis,     "Twist axis",            "Twists",         kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam  (Blended,        "Enable blend transitions", kNoGroup, false);

DeclareIntParam   (Source,         "Source",                "Blend settings", 0, "Extracted foreground|Image key or title (disconnect input)");
DeclareBoolParam  (SwapDir,        "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain,        "Fine tune",             "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam  (ShowKey,        "Show foreground key",   "Blend settings", false);
DeclareBoolParam  (SwapSource,     "Swap sources",          "Blend settings", false);

DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define RIPPLES  125.0
#define SOFTNESS 0.45
#define OFFSET   0.05
#define SCALE    0.02

//-----------------------------------------------------------------------------------------//
// Code
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

DeclareEntryPoint (TwisterTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);

   if (Blended && ShowKey) return Fgnd;

   float4 Bgnd = tex2D (Bgd, uv3);
   float4 retval;

   float2 xy;

   float range = max (0.0, Width * SOFTNESS) + OFFSET;         // Calculate softness range of the effect
   float amount, maxVis, minVis, modulate, offset;
   float ripples, spread, T_Axis, twistAxis, twists;

   int Mode = (int) fmod ((float)TransProfile, 2.0);

   if (Blended && !SwapDir) {
      maxVis = (Mode == TransProfile) ? 1.0 - uv3.x : uv3.x;
      maxVis = (1.0 - Amount) * (1.0 + range) - maxVis;
      twistAxis = 1.0 - Twist_Axis;
      ripples = max (0.0, RIPPLES * (range - maxVis));
   }
   else {
      maxVis = Mode == TransProfile ? uv3.x : 1.0 - uv3.x;
      minVis = range + maxVis - (Amount * (1.0 + range));         // The sense of the Amount parameter has to change

      if (Blended) {
         maxVis = Amount * (1.0 + range) - maxVis;
         twistAxis = 1.0 - Twist_Axis;
         ripples = max (0.0, RIPPLES * (range - maxVis));
      }
      else {
         maxVis = range - minVis;                                 // Set up the maximum visibility
         twistAxis = 1.0 - Twist_Axis;                            // Invert the twist axis setting
         ripples = max (0.0, RIPPLES * minVis);                   // Correct the ripples of the final effect
      }
   }

   amount = saturate (maxVis / range);                            // Calculate the visibility
   T_Axis = uv3.y - twistAxis;                                    // Calculate the normalised twist axis

   spread   = ripples * Spread * SCALE;                           // Correct the spread
   modulate = pow (max (0.0, Ripples), 5.0) * ripples;            // Calculate the modulation factor
   offset   = sin (modulate) * spread;                            // Calculate the vertical offset from the modulation and spread
   twists   = cos (modulate * Twists * 4.0);                      // Calculate the twists using cos () instead of sin ()

   xy = float2 (uv3.x, twistAxis + (T_Axis / twists) - offset);   // Foreground X is uv3.x, foreground Y is modulated uv3.y

   if (Blended) {
      xy.y  += offset * float (Mode * 2);
      Fgnd   = ReadPixel (Fgd, xy);
      retval = lerp (Bgnd, Fgnd, Fgnd.a * amount);
   }
   else {
      Bgnd = ReadPixel (Bgd, xy);                                 // This version of the background has the modulation applied

      ripples  = max (0.0, RIPPLES * maxVis);
      spread   = ripples * Spread * SCALE;
      modulate = pow (max (0.0, Ripples), 5.0) * ripples;
      offset   = sin (modulate) * spread;
      twists   = cos (modulate * Twists * 4.0);

      xy = float2 (uv3.x, twistAxis + (T_Axis / twists) - offset);

      Fgnd = ReadPixel (Fgd, xy);                                 // Get the second partial composite
      retval = lerp (Fgnd, Bgnd, amount);                         // Dissolve between the halves
   }

   if (Show_Axis) {

      // To help with line-up this section produces a two-pixel wide line from the twist axis.  It's added to the output, and the
      // result is folded if it exceeds peak white.  This ensures that the line will remain visible regardless of the video content.

      retval.rgb -= max (0.0, (1.0 - (abs (T_Axis) * _OutputHeight * 0.25)) * 3.0 - 2.0).xxx;
      retval.rgb  = max (0.0.xxx, retval.rgb) - min (0.0.xxx, retval.rgb);
   }

   return retval;
}
