// @Maintainer jwrl
// @Released 2026-07-15
// @Author jwrl
// @Created 2018-06-13

/**
 This mimics the Lightworks squeeze effect but transitions alpha and delta keys in or out.

   [*]Amount:  The normal keyframed transition progress.
   [*]Type:  Selects whether to squeeze right, left, downwards or upwards.
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
// Lightworks user effect SqueezeTrans.fx
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

DeclareLightworksEffect ("Squeeze transition", "Mix", "Transform transitions", "Mimics the Lightworks squeeze effect with the blended foreground", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",       kNoGroup,         kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam   (SetTechnique,   "Type",         kNoGroup,         0, "Squeeze right|Squeeze down|Squeeze left|Squeeze up");

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
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_initFg (sampler F, float2 xy1, sampler B, float2 xy2)
{
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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// SqueezeRight

DeclarePass (Fg_R)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_R)
{ return SwapSource ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (SqueezeRight)
{
   float4 Fgnd, Bgnd;

   if (ShowKey) {
      Fgnd = tex2D (Fg_R, uv3);
      Bgnd = kTransparentBlack;
   }
   else {
      float2 xy;

      if (!SwapDir) {
         xy = (Amount == 1.0) ? float2 (2.0, uv3.y)
                              : float2 ((uv3.x - 1.0) / (1.0 - Amount) + 1.0, uv3.y);
      }
      else xy = (Amount == 0.0) ? float2 (2.0, uv3.y) : float2 (uv3.x / Amount, uv3.y);

      Bgnd = tex2D (Bg_R, uv3);
      Fgnd = ReadPixel (Fg_R, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// SqueezeDown

DeclarePass (Fg_D)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_D)
{ return SwapSource ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (SqueezeDown)
{
   float4 Fgnd, Bgnd;

   if (ShowKey) {
      Fgnd = tex2D (Fg_D, uv3);
      Bgnd = kTransparentBlack;
   }
   else {
      float2 xy;

      if (!SwapDir) {
         xy = (Amount == 1.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, (uv3.y - 1.0) / (1.0 - Amount) + 1.0);
      }
      else xy = (Amount == 0.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, uv3.y / Amount);

      Bgnd = tex2D (Bg_D, uv3);
      Fgnd = ReadPixel (Fg_D, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// SqueezeLeft

DeclarePass (Fg_L)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_L)
{ return SwapSource ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (SqueezeLeft)
{
   float4 Fgnd, Bgnd;

   if (ShowKey) {
      Fgnd = tex2D (Fg_L, uv3);
      Bgnd = kTransparentBlack;
   }
   else {
      float2 xy;

      if (!SwapDir) {
         xy = (Amount == 1.0) ? float2 (2.0, uv3.y) : float2 (uv3.x  / (1.0 - Amount), uv3.y);
      }
      else xy = (Amount == 0.0) ? float2 (2.0, uv3.y) : float2 ((uv3.x - 1.0) / Amount + 1.0, uv3.y);

      Bgnd = tex2D (Bg_L, uv3);
      Fgnd = ReadPixel (Fg_L, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// SqueezeUp

DeclarePass (Fg_U)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_U)
{ return SwapSource ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (SqueezeUp)
{
   float4 Fgnd, Bgnd;

   if (ShowKey) {
      Fgnd = tex2D (Fg_U, uv3);
      Bgnd = kTransparentBlack;
   }
   else {
      float2 xy;

      if (!SwapDir) {
         xy = (Amount == 1.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, uv3.y  / (1.0 - Amount));
      }
      else xy = (Amount == 0.0) ? float2 (uv3.x, 2.0) : float2 (uv3.x, (uv3.y - 1.0) / Amount + 1.0);

      Bgnd = tex2D (Bg_U, uv3);
      Fgnd = ReadPixel (Fg_U, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}
