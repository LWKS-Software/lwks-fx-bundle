// @Maintainer jwrl
// @Released 2026-07-15
// @Author jwrl
// @Created 2022-07-30

/**
 Bounces an image, key, title or blended image up to a preset size at the mid point then
 lets it fall back.  The transition can be linear or follow a preset smooth curve.  It
 operates on standard video and on both alpha and delta keys.

   [*]Amount:  The normal keyframed transition progress.
   [*]Transition type:  Sets the mode for standard transitions to bounce in or
      bounce out. Overriden in blend mode.
   [*]Midpoint:  Sets the midpoint timing of the bounce in percentage of transition
      duration.
   [*]Transition curve:  Sets the bounce profile to linear or one of two curves.
   [*]Midpoint settings
      [*]Mode:  Turns the transition off to allow setting of the midpoint size
         and position.
      [*]Size:  Sets the midpoint size.
      [*]Centre X:  Sets the horizontal midpoint position.
      [*]Centre Y:  Sets the vertical midpoint position.
   [*]Zero settings
      [*]Mode:  Turns the transition off to allow setting of the start size and
         position.
      [*]Size:  Sets the start size.
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

 When dealing with blended alpha and delta keys there is a slight difference in behaviour.
 In that mode the transition type setting has no effect.  A transition in will always be
 a bounce in, and a transition out will always be a bounce out.  They are governed by the
 blend settings.  Secondly, there is a split function which governs where the blended
 effect will separate.

 NOTE:  This effect has been revised for Lightworks version 2026 and higher.  Part of
 the revision process has meant the removal of masking.  In all other respects this
 behaves as the earlier versions did, and can be installed on any Lightworks version
 above 2022.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BounceTrans.fx
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

DeclareLightworksEffect ("Bounce transition", "Mix", "Transform transitions", "Bounces the incoming video to a preset size then falls back", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",           kNoGroup,             kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam   (Ttype,          "Transition type",  kNoGroup, 0,          "Bounce in|Bounce out");
DeclareFloatParam (Mid,            "Midpoint",         kNoGroup,             "DisplayAsPercentage", 0.5, 0.1, 0.9);
DeclareIntParam   (Curve,          "Transition curve", kNoGroup, 0,          "Linear|Curve 1|Curve 2");

DeclareIntParam   (MidMode,        "Mode",             "Midpoint settings",  0, "Operate|Set up size");
DeclareFloatParam (MidScale,       "Size",             "Midpoint settings", "DisplayAsPercentage", 1.5, 0.0, 4.0);
DeclareFloatParam (CentreX,        "Centre",           "Midpoint settings", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY,        "Centre",           "Midpoint settings", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareIntParam   (ZeroMode,       "Mode",             "Zero settings",      0, "Operate|Set up size");
DeclareFloatParam (ZeroScale,      "Size",             "Zero settings",      "DisplayAsPercentage", 0.0, 0.0, 4.0);

DeclareBoolParam  (Blended,        "Enable blend transitions",               kNoGroup, false);

DeclareIntParam   (Source,         "Source",           "Blend settings", 0,  "Extracted foreground|Image key or title (disconnect input)");
DeclareBoolParam  (SwapDir,        "Transition into blend",                  "Blend settings", true);
DeclareFloatParam (KeyGain,        "Fine tune",        "Blend settings",     kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam  (ShowKey,        "Show foreground key",                    "Blend settings", false);
DeclareBoolParam  (SwapSource,     "Swap sources",     "Blend settings",     false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI      3.141592654
#define HALF_PI 1.570796327

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

DeclareEntryPoint (Bounce)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 retval;

   float amt_1, amt_2, s_1, s_2, scale;

   float2 cL = float2 (1.0 - CentreX, CentreY);
   float2 xy = uv3 - cL;

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         if (ZeroMode) { scale = ZeroScale; }
         else if (MidMode) { scale = MidScale; }
         else {
            amt_2 = SwapDir ? Amount : 1.0 - Amount;
            amt_1 = smoothstep (0.0, Mid, amt_2) + smoothstep (Mid, 1.0, amt_2);

            // The above ranges the progress of the transition from 0.0 to 2.0, with 1.0
            // at the preset midpoint.  We now apply some simple trig curves if needed.

            if (Curve == 1) {
               amt_2 = (cos (amt_1 * PI) + 3.0) * 0.5;      // Swings between 2.0 > 1.0 > 2.0
               amt_1 = amt_1 > 1.0 ? amt_2 : 2.0 - amt_2;   // Swings between 0.0 > 1.0 > 2.0
            }
            else if (Curve == 2) {
               amt_2 = sin (amt_1 * HALF_PI);               // Swings between 0.0 > 1.0 > 0.0
               amt_1 = amt_1 < 1.0 ? amt_2 : 2.0 - amt_2;   // Swings between 0.0 > 1.0 > 2.0
            }

            // We now set up amt_1 to ramp from zero to 100% at the preset midpoint of the
            // transition and amt_2 to ramp from zero to 100% after that.

            amt_2 = max (amt_1 - 1.0, 0.0);
            amt_1 = min (amt_1, 1.0);

            // The next block of code sets s_1 to ZeroScale if we're transitioning in or 100%
            // if transitioning out.  The variable s_2 is set to 100% if we're transitioning
            // in or ZeroScale if transitioning out.

            if (Ttype == 2) {
               s_1 = 1.0;
               s_2 = ZeroScale;
            }
            else {
               s_1 = ZeroScale;
               s_2 = 1.0;
            }

            // Finally the transition ramps the scale from the start to the midpoint scale
            // value then ramps it from the midpoint value to the end scale.

            scale = lerp (lerp (s_1, MidScale, amt_1), s_2, amt_2);
         }

         // We now perform a simple scaling of the preset offset screen coordinates, recover
         // our foreground and background components, combine them and quit.

         xy /= scale;
         xy += cL;
         retval = tex2D (Fgd, xy);
      }
   }
   else {
      if (MidMode) { scale = MidScale; }
      else {
         amt_1 = smoothstep (0.0, Mid, Amount) + smoothstep (Mid, 1.0, Amount);
         amt_2;

         // The above ranges the progress of the transition from 0.0 to 2.0, with 1.0
         // at the preset midpoint.  We now apply some simple trig curves if needed.

         if (Curve == 1) {
            amt_2 = (cos (amt_1 * PI) + 3.0) * 0.5;      // Swings between 2.0 > 1.0 > 2.0
            amt_1 = amt_1 > 1.0 ? amt_2 : 2.0 - amt_2;   // Swings between 0.0 > 1.0 > 2.0
         }
         else if (Curve == 2) {
            amt_2 = sin (amt_1 * HALF_PI);               // Swings between 0.0 > 1.0 > 0.0
            amt_1 = amt_1 < 1.0 ? amt_2 : 2.0 - amt_2;   // Swings between 0.0 > 1.0 > 2.0
         }

         // We now set up amt_1 to ramp from zero to 100% at the preset midpoint of the
         // transition and amt_2 to ramp from zero to 100% after that.

         amt_2 = max (amt_1 - 1.0, 0.0);
         amt_1 = min (amt_1, 1.0);

         // The next block of code sets s_1 to zero if we're transitioning in or 100% if
         // transitioning out.  The variable s_2 is set to the reverse of s_1.

         s_1 = (float)Ttype;
         s_2 = 1.0 - s_1;

         // Finally the transition ramps the scale from the start to the midpoint scale
         // value then ramps it from the midpoint value to the end scale.

         scale = lerp (lerp (s_1, MidScale, amt_1), s_2, amt_2);
      }

      // We now perform a simple scaling of the preset offset screen coordinates, recover
      // our foreground and background components, combine them and quit.

      xy /= scale;
      xy += cL;

      if (!Ttype) {
         Bgnd = Fgnd;
         Fgnd = ReadPixel (Bgd, xy);
      }
      else Fgnd = ReadPixel (Fgd, xy);

      retval = lerp (Bgnd, Fgnd, Fgnd.a);
   }

   return retval;
}
