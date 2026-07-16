// @Maintainer jwrl
// @Released 2026-07-16
// @Author jwrl
// @Created 2017-08-24

/**
 This is really the classic barn door effect, but since a wipe with that name already exists
 in Lightworks another name had to be found.  The Lightworks wipe is just that, a wipe.  It
 doesn't move the separated image parts apart.

   [*]Amount:  The normal keyframed transition progress.
   [*]Transition:  Sets the transition to horizontally or vertically open or close. Open
      and close are overriden in blend mode.
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
// Lightworks user effect BarnDoorTrans.fx
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

DeclareLightworksEffect ("Barn door transition", "Mix", "Wipe transitions", "Splits the image in half and separates the halves horizontally or vertically", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",       kNoGroup,         kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam   (SetTechnique,   "Transition",   kNoGroup, 0,      "Horizontal open|Horizontal close|Vertical open|Vertical close");
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

#define OPEN false
#define SHUT true

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

float4 fn_split_H (sampler V, float2 uv, bool mode)
{
   float posAmt = mode ? Amount : 1.0 - Amount;
   float negAmt = posAmt / 2.0;

   posAmt = 1.0 - negAmt;

   float2 xy1 = float2 (uv.x - posAmt + 0.5, uv.y);
   float2 xy2 = float2 (uv.x - negAmt + 0.5, uv.y);

   return uv.x > posAmt ? ReadPixel (V, xy1) : (uv.x < negAmt)
                        ? ReadPixel (V, xy2) : kTransparentBlack;
}

float4 fn_split_V (sampler V, float2 uv, bool mode)
{
   float posAmt = mode ? Amount : 1.0 - Amount;
   float negAmt = posAmt / 2.0;

   posAmt = 1.0 - negAmt;

   float2 xy1 = float2 (uv.x, uv.y - posAmt + 0.5);
   float2 xy2 = float2 (uv.x, uv.y - negAmt + 0.5);

   return uv.y > posAmt ? ReadPixel (V, xy1) : (uv.y < negAmt)
                        ? ReadPixel (V, xy2) : kTransparentBlack;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// technique Open horizontal

DeclarePass (Fg_OH)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_OH)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (BarnDoor_OH)
{
   float4 Fgnd = tex2D (Fg_OH, uv3);
   float4 Bgnd = tex2D (Bg_OH, uv3);
   float4 Buffer, retval;

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         Buffer = kTransparentBlack;
      }
      else {
         retval = fn_split_H (Fg_OH, uv3, SwapDir);
         Buffer = Bgnd;
      }
   }
   else {
      retval = fn_split_H (Fg_OH, uv3, OPEN);
      Buffer = Bgnd;
   }

   return lerp (Buffer, retval, retval.a);
}

//-----------------------------------------------------------------------------------------//

// technique Shut horizontal

DeclarePass (Fg_SH)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_SH)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (BarnDoor_SH)
{
   float4 Fgnd = tex2D (Fg_SH, uv3);
   float4 Bgnd = tex2D (Bg_SH, uv3);
   float4 Buffer, retval;

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         Buffer = kTransparentBlack;
      }
      else {
         retval = fn_split_H (Fg_SH, uv3, SwapDir);
         Buffer = Bgnd;
      }
   }
   else {
      retval = fn_split_H (Bg_SH, uv3, SHUT);
      Buffer = Fgnd;
   }

   return lerp (Buffer, retval, retval.a);
}

//-----------------------------------------------------------------------------------------//

// technique Open vertical

DeclarePass (Fg_OV)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_OV)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (BarnDoor_OV)
{
   float4 Fgnd = tex2D (Fg_OV, uv3);
   float4 Bgnd = tex2D (Bg_OV, uv3);
   float4 Buffer, retval;

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         Buffer = kTransparentBlack;
      }
      else {
         retval = fn_split_V (Fg_OV, uv3, SwapDir);
         Buffer = Bgnd;
      }
   }
   else {
      retval = fn_split_V (Fg_OV, uv3, OPEN);
      Buffer = Bgnd;
   }

   return lerp (Buffer, retval, retval.a);
}

//-----------------------------------------------------------------------------------------//

// technique Shut vertical

DeclarePass (Fg_SV)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_SV)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (BarnDoor_SV)
{
   float4 Fgnd = tex2D (Fg_SV, uv3);
   float4 Bgnd = tex2D (Bg_SV, uv3);
   float4 Buffer, retval;

   if (Blended) {
      if (ShowKey) {
         retval = Fgnd;
         Buffer = kTransparentBlack;
      }
      else {
         retval = fn_split_V (Fg_SV, uv3, SwapDir);
         Buffer = Bgnd;
      }
   }
   else {
      retval = fn_split_V (Bg_SV, uv3, SHUT);
      Buffer = Fgnd;
   }

   return lerp (Buffer, retval, retval.a);
}
