// @Maintainer jwrl
// @Released 2026-07-08
// @Author Robert Schütze
// @Author jwrl
// @Created 2016-05-21

/**
 This effect uses a fractal-like pattern to transition between two sources.  It supports
 titles and other blended effects.  If you have used the previous fractal transition you
 will notice that the border settings are much more extreme.  This is to assist in the
 blend transition process.

   [*]Amount:  The transition progress.
   [*]Fractal settings
      [*]Offset:  Sets the state of the fractal pattern at the start of the
         transition
      [*]Rate:  Sets the rate at which the pattern changes.
      [*]Edge size:  Sets the thickness of the coloured border in the pattern.
      [*]Feather:  Softens the edge of the pattern and the border thickness.
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
// Lightworks user effect FractalTrans.fx
//
// The fractal component is a conversion of GLSL sandbox effect #308888 created by Robert
// Schütze (trirop) 07.12.2015.
//
// Version history:
//
// Updated 2026-07-08 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-13 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-03-06 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Fractal transition", "Mix", "Abstract transitions", "Uses a fractal-like pattern to transition between two sources", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",       kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (fractalOffset,  "Offset",       "Fractal settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Rate,           "Rate",         "Fractal settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Border,         "Edge size",    "Fractal settings", kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (Feather,        "Feather",      "Fractal settings", kNoFlags, 0.1, 0.0, 1.0);

DeclareBoolParam  (Blended,        "Enable blend transitions",         kNoGroup, false);

DeclareIntParam   (Source,         "Source",       "Blend settings",   0, "Extracted foreground|Image key/Title pre 2023.2, no input|Image or title without connected input");
DeclareBoolParam  (SwapDir,        "Transition into blend",            "Blend settings", true);
DeclareFloatParam (KeyGain,        "Fine tune",    "Blend settings",   kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam  (ShowKey,        "Show foreground key",              "Blend settings", false);
DeclareBoolParam  (SwapSource,     "Swap sources", "Blend settings",   false);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_technique (float4 Fgnd, float4 Bgnd, float4 retval, float amount)
{
   float amt_in   = min (1.0, amount * 5.0);
   float amt_body = (amount * 0.5) + 0.5;
   float amt_out  = max (0.0, (amount * 5.0) - 4.0);

   float fractal = max (retval.g, max (retval.r, retval.b));
   float bdWidth = Border * 0.5;
   float FthrRng = amt_body + Feather;
   float fracAmt = (fractal - amt_body) / Feather;

   if (fractal <= FthrRng) {
      if (fractal > (amt_body - bdWidth)) { retval = lerp (Bgnd, retval, fracAmt); }
      else retval = Bgnd;

      if (fractal > (amt_body + bdWidth)) { retval = lerp (retval, Fgnd, fracAmt); }
   }
   else retval = Fgnd;

   return lerp (lerp (Fgnd, retval, amt_in), Bgnd, amt_out);
}

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
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

   if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;

   return Fgnd;
}

DeclarePass (Bgd)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

DeclarePass (Fractal)
{
   float3 offset  = float3 (1.0.xx, Amount * Rate * 0.5);
   float3 fractal = float3 (uv0.x / _OutputAspectRatio, uv0.y, fractalOffset);

   for (int i = 0; i < 75; i++) {
      fractal.xzy = float3 (1.3, 0.999, 0.7) * (abs ((abs (fractal) / dot (fractal, fractal) - offset)));
   }

   return float4 (saturate (fractal), 1.0);
}

DeclareEntryPoint (FractalTrans)
{
   float4 Fgnd   = tex2D (Fgd, uv3);
   float4 Bgnd   = tex2D (Bgd, uv3);
   float4 retval = tex2D (Fractal, uv3);

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         float amount = SwapDir ? 1.0 - Amount : Amount;

         retval = fn_technique (Fgnd, Bgnd, retval, amount);
      }
   }
   else retval = fn_technique (Fgnd, Bgnd, retval, Amount);

   return retval;
}
