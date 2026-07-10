// @Maintainer jwrl
// @Released 2026-07-10
// @Author jwrl
// @Created 2021-06-20

/**
 This effect applies a directional (motion) blur to the components, the angle and
 strength of which can be adjusted.  It then progressively reduces the blur to
 reveal the incoming image.

   [*]Amount:  The normal keyframed transition progress.
   [*]Blur settings
      [*]Blurriness:  Sets the amount of blur to use in the transition.
      [*]Angle:  Sets the blur direction.
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
// Lightworks user effect DirectionalBlurTrans.fx
//
// Version history:
//
// Updated 2026-07-10 jwrl.
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

DeclareLightworksEffect ("Directional blur transition", "Mix", "Blur transitions", "Directionally blurs the foreground as it fades in or out", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",       kNoGroup,         kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Blurriness,     "Blurriness",   "Blur settings",  kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Angle,          "Angle",        "Blur settings",  kNoFlags, 0.0, -180.00, 180.0);

DeclareBoolParam  (Blended,        "Enable blend transitions",       kNoGroup, false);

DeclareIntParam   (Source,         "Source",       "Blend settings", 0, "Extracted foreground|Image key or title (disconnect input)");
DeclareBoolParam  (SwapDir,        "Transition into blend",          "Blend settings", true);
DeclareFloatParam (KeyGain,        "Fine tune",    "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam  (ShowKey,        "Show foreground key",            "Blend settings", false);
DeclareBoolParam  (SwapSource,     "Swap sources", "Blend settings", false);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_transition (sampler vid, float2 uv, float2 blur)
{
   float4 retval = tex2D (vid, uv);

   if (Blurriness > 0.0) {
      float2 xy1 = uv;
      float2 xy2 = uv;

      blur   *= Blurriness * 0.005;
      blur.y *= _OutputAspectRatio;

      for (int i = 0; i < 30; i++) {
         xy1 += blur;
         xy2 -= blur;
         retval += tex2D (vid, xy1);
         retval += tex2D (vid, xy2);
      }

      retval /= 61;
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

DeclarePass (Mixed)
{
   float4 Fgnd = tex2D (Fgd, uv3);

   if (!Blended ) {
      float4 Bgnd = tex2D (Bgd, uv3);

      float amount = pow (1.0 - (abs (Amount - 0.5) * 2.0), 5.0) / 2.0;

      if (Amount > 0.5) amount = 1.0 - amount;
      Fgnd = lerp (Fgnd, Bgnd, amount);
   }

   return Fgnd;
}

DeclareEntryPoint (DirectionalBlurTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 retval;

   float2 blur;

   sincos (radians (-Angle), blur.y, blur.x);

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         float amt = Amount + Amount;

         if (!SwapDir) {
            retval = fn_transition (Mixed, uv3, blur * saturate (Amount));
            amt = 2.0 - amt;
         }
         else retval = fn_transition (Mixed, uv3, blur * (1.0 - saturate (Amount)));

         retval.a *= sin (saturate (amt) * HALF_PI);
      }
   }
   else retval = fn_transition (Mixed, uv3, blur * sin (saturate (Amount) * PI));

   return retval;
}
