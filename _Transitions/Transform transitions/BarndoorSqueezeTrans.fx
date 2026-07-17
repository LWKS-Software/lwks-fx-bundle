// @Maintainer jwrl
// @Released 2026-07-17
// @Author jwrl
// @Created 2017-08-25

/**
 This is similar to the earlier split squeeze effect, customised to allow it to be
 used with blended effects as well.  It can operate vertically or horizontally
 depending on the user setting.  In normal video mode it squeezes the split video
 out to the edges or expands it from the edges of frame.

   [*]Amount:  The normal keyframed transition progress.
   [*]Transition direction:  Sets expansion or compression horizontally or
      vertically.  Expansion / compression is overriden by blend mode.
   [*]Enable blend transitions:  Changes the mode from opaque video to transparent
      video such as titles and the like.
   [*]Blend settings
      [*]Split centre:  In blend mode, sets the centre point for the split.
      [*]Source:  Selects between an extracted video source and transparent video.
      [*]Transition into blend:  Selects between transitioning into or out of a
         blended video source.
      [*]Fine tune:  Fine tunes the separation of an extracted video source from
         its background.
      [*]Show foreground key:  Showing the key helps in setting up the clip.
      [*]Swap sources:  This can be necessary when using a folded delta key
         (extracted) transition.

 When dealing with blended video there is a slight difference in behaviour.  In that
 mode it moves the separated foreground image halves apart and squeezes them to the
 edges of the screen only when it's an outgoing transition.  When it's an incoming
 transition it only expands the halves from the edges.  This means that for blended
 effects the expand and squeeze settings behave identically.

 NOTE:  This effect has been revised for Lightworks version 2026 and higher.  Part of
 the revision process has meant the removal of masking.  In all other respects this
 behaves as the earlier versions did, and can be installed on any Lightworks version
 above 2022.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BarndoorSqueezeTrans.fx
//
// Version history:
//
// Updated 2026-07-17 jwrl.
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

DeclareLightworksEffect ("Barn door squeeze transition", "Mix", "Transform transitions", "Splits the video and squeezes the halves apart horizontally or vertically", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",       kNoGroup,         kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam   (SetTechnique,   "Transition direction",           kNoGroup, 0, "Expand horizontal|Expand vertical|Squeeze horizontal|Squeeze vertical");
DeclareBoolParam  (Blended,        "Enable blend transitions",       kNoGroup, false);

DeclareFloatParam (Split,          "Split centre", "Blend settings", kNoFlags, 0.5, 0.0, 1.0);
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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// technique BarndoorExpand_Eh

DeclarePass (Fg_Eh)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_Eh)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (BarndoorExpand_Eh)
{
   float4 Fgnd = tex2D (Fg_Eh, uv3);
   float4 Bgnd = tex2D (Bg_Eh, uv3);
   float4 retval;

   float2 xy1, xy2;

   float negAmt, posAmt;

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         float Amt = SwapDir ? Amount : 1.0 - Amount;
         float amount = Amt - 1.0;

         negAmt = Amt * Split;
         posAmt = 1.0 - (Amt * (1.0 - Split));

         xy1 = float2 ((uv3.x + amount) / Amt, uv3.y);
         xy2 = float2 (uv3.x / Amt, uv3.y);

         retval = (uv3.x > posAmt) ? tex2D (Fg_Eh, xy1)
                : (uv3.x < negAmt) ? tex2D (Fg_Eh, xy2) : kTransparentBlack;
         retval = lerp (Bgnd, retval, retval.a);
      }
   }
   else {
      negAmt = Amount / 2.0;
      posAmt = 1.0 - negAmt;

      xy1 = float2 ((uv3.x + Amount - 1.0) / Amount, uv3.y);
      xy2 = float2 (uv3.x / Amount, uv3.y);

      retval = (uv3.x > posAmt) ? tex2D (Bg_Eh, xy1) :
               (uv3.x < negAmt) ? tex2D (Bg_Eh, xy2) : Fgnd;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique BarndoorExpand_Ev

DeclarePass (Fg_Ev)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_Ev)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (BarndoorExpand_Ev)
{
   float4 Fgnd = tex2D (Fg_Ev, uv3);
   float4 Bgnd = tex2D (Bg_Ev, uv3);
   float4 retval;

   float2 xy1, xy2;

   float negAmt, posAmt;

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         float Amt = SwapDir ? Amount : 1.0 - Amount;
         float amount = Amt - 1.0;

         negAmt = Amt * (1.0 - Split);
         posAmt = 1.0 - (Amt * Split);

         xy1 = float2 (uv3.x, (uv3.y + amount) / Amt);
         xy2 = float2 (uv3.x, uv3.y / Amt);

         retval = (uv3.y > posAmt) ? tex2D (Fg_Ev, xy1)
                : (uv3.y < negAmt) ? tex2D (Fg_Ev, xy2) : kTransparentBlack;
         retval = lerp (Bgnd, retval, retval.a);
      }
   }
   else {
      negAmt = Amount / 2.0;
      posAmt = 1.0 - negAmt;

      xy1 = float2 (uv3.x, (uv3.y + Amount - 1.0) / Amount);
      xy2 = float2 (uv3.x, uv3.y / Amount);

      retval = (uv3.y > posAmt) ? tex2D (Bg_Ev, xy1)
             : (uv3.y < negAmt) ? tex2D (Bg_Ev, xy2) : Fgnd;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique BarndoorSqueeze_Sh

DeclarePass (Fg_Sh)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_Sh)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (BarndoorSqueeze_Sh)
{
   float4 Fgnd = tex2D (Fg_Sh, uv3);
   float4 Bgnd = tex2D (Bg_Sh, uv3);
   float4 retval;

   float2 xy1, xy2;

   float negAmt, posAmt;

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         float Amt = SwapDir ? Amount : 1.0 - Amount;
         float amount = Amt - 1.0;

         negAmt = Amt * Split;
         posAmt = 1.0 - (Amt * (1.0 - Split));

         xy1 = float2 ((uv3.x + amount) / Amt, uv3.y);
         xy2 = float2 (uv3.x / Amt, uv3.y);

         retval = (uv3.x > posAmt) ? tex2D (Fg_Sh, xy1)
                : (uv3.x < negAmt) ? tex2D (Fg_Sh, xy2) : kTransparentBlack;
         retval = lerp (Bgnd, retval, retval.a);
      }
   }
   else {
      negAmt = 1.0 - Amount;
      posAmt = (1.0 + Amount) / 2.0;

      xy1 = float2 ((uv3.x - Amount) / negAmt, uv3.y);
      xy2 = float2 (uv3.x / negAmt, uv3.y);

      negAmt /= 2.0;

      retval = (uv3.x > posAmt) ? tex2D (Fg_Sh, xy1) :
               (uv3.x < negAmt) ? tex2D (Fg_Sh, xy2) : Bgnd;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// technique BarndoorSqueeze_Sv

DeclarePass (Fg_Sv)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_Sv)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (BarndoorSqueeze_Sv)
{
   float4 Fgnd = tex2D (Fg_Sv, uv3);
   float4 Bgnd = tex2D (Bg_Sv, uv3);
   float4 retval;

   float2 xy1, xy2;

   float negAmt, posAmt;

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         float Amt = SwapDir ? Amount : 1.0 - Amount;
         float amount = Amt - 1.0;

         negAmt = Amt * (1.0 - Split);
         posAmt = 1.0 - (Amt * Split);

         xy1 = float2 (uv3.x, (uv3.y + amount) / Amt);
         xy2 = float2 (uv3.x, uv3.y / Amt);

         retval = (uv3.y > posAmt) ? tex2D (Fg_Sv, xy1)
                : (uv3.y < negAmt) ? tex2D (Fg_Sv, xy2) : kTransparentBlack;
         retval = lerp (Bgnd, retval, retval.a);
      }
   }
   else {
      negAmt = 1.0 - Amount;
      posAmt = (1.0 + Amount) / 2.0;

      xy1 = float2 (uv3.x, (uv3.y - Amount) / negAmt);
      xy2 = float2 (uv3.x, uv3.y / negAmt);

      negAmt /= 2.0;

      retval = (uv3.y > posAmt) ? tex2D (Fg_Sv, xy1) :
               (uv3.y < negAmt) ? tex2D (Fg_Sv, xy2) : Bgnd;
   }

   return retval;
}
