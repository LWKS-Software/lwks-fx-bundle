// @Maintainer jwrl
// @Released 2026-07-16
// @Author jwrl
// @Created 2018-06-12

/**
 This mimics the Lightworks push effect but is designed to support titles, image keys
 and other blended effects.

   [*]Amount:  The normal keyframed transition progress.
   [*]Type:  Sets the push direction.
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
// Lightworks user effect PushTrans.fx
//
// Version history:
//
// Updated 2026-07-16 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-14 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Push transition", "Mix", "Wipe transitions", "Pushes the foreground on or off screen horizontally or vertically", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",       kNoGroup,         kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam   (SetTechnique,   "Type",         kNoGroup,         0, "Push Right|Push Down|Push Left|Push Up");

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

#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_initFg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd, Fgnd = ReadPixel (F, xy1);

   if (SwapSource) {
      Bgnd = Fgnd;
      Fgnd = ReadPixel (B, xy2);
   }
   else Bgnd = ReadPixel (B, xy2);

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }

   // If alpha is zero we need any video to be blanked.  We do NOT need it to be
   // multiplied, so this is the simplest way to fix things.

   return Fgnd.a == 0.0 ? kTransparentBlack : Fgnd;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// technique Push_right

DeclarePass (Fg_R)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_R)
{ return SwapSource ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (Push_right)
{
   float4 Fgnd, Bgnd;

   if (ShowKey) {
      Bgnd = kTransparentBlack;
      Fgnd = ReadPixel (Fg_R, uv3);
   }
   else {
      float2 xy = SwapDir ? float2 (uv3.x - sin (HALF_PI * Amount) + 1.0, uv3.y)
                          : float2 (uv3.x + cos (HALF_PI * Amount) - 1.0, uv3.y);

      Bgnd = tex2D (Bg_R, uv3);
      Fgnd = ReadPixel (Fg_R, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Push_down

DeclarePass (Fg_D)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_D)
{ return SwapSource ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (Push_down)
{
   float4 Fgnd, Bgnd;

   if (ShowKey) {
      Bgnd = kTransparentBlack;
      Fgnd = ReadPixel (Fg_D, uv3);
   }
   else {
      float2 xy = SwapDir ? float2 (uv3.x, uv3.y + cos (HALF_PI * Amount))
                          : float2 (uv3.x, uv3.y - sin (HALF_PI * Amount));

      Bgnd = tex2D (Bg_D, uv3);
      Fgnd = ReadPixel (Fg_D, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Push_left

DeclarePass (Fg_L)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_L)
{ return SwapSource ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (Push_left)
{
   float4 Fgnd, Bgnd;

   if (ShowKey) {
      Bgnd = kTransparentBlack;
      Fgnd = ReadPixel (Fg_L, uv3);
   }
   else {
      float2 xy = SwapDir ? float2 (uv3.x + sin (HALF_PI * Amount) - 1.0, uv3.y)
                          : float2 (uv3.x - cos (HALF_PI * Amount) + 1.0, uv3.y);

      Bgnd = tex2D (Bg_L, uv3);
      Fgnd = ReadPixel (Fg_L, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//

// technique Push_up

DeclarePass (Fg_U)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_U)
{ return SwapSource ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (Push_up)
{
   float4 Fgnd, Bgnd;

   if (ShowKey) {
      Bgnd = kTransparentBlack;
      Fgnd = ReadPixel (Fg_U, uv3);
   }
   else {
      float2 xy = SwapDir ? float2 (uv3.x, uv3.y - cos (HALF_PI * Amount))
                          : float2 (uv3.x, uv3.y + sin (HALF_PI * Amount));

      Bgnd = tex2D (Bg_U, uv3);
      Fgnd = ReadPixel (Fg_U, xy);
   }

   return lerp (Bgnd, Fgnd, Fgnd.a);
}
