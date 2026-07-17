// @Maintainer jwrl
// @Released 2026-07-17
// @Author jwrl
// @Created 2017-01-03

/**
 This effect emulates a range of dissolve types and can be used as a standard video
 transition, or applied to keyed and blended video.  The first transition is the classic
 analog vision mixer non-add mix.  It uses an algorithm that mimics reasonably
 closely what the vision mixer electronics used to do.

 The second is an extreme non-additive mix.  The incoming video is faded in to full value
 at the 50% point, at which stage the outgoing video starts to fade out.  The two images
 are mixed by giving the source with the maximum level priority.  The result is always
 visually interesting.

 The final two are essentially the same as a Lightworks' dissolve, with a choice of either
 a trigonometric curve or a quadratic curve applied to the "Amount" parameter.  You can
 vary the linearity of the curve using the strength setting.

   [*]Amount:  The transition progress.
   [*]Dissolve profile:  Sets the profile to non-add, ultra non-add, trigonometric
      or quadratic.
   [*]Strength:  Adjusts the strength of the profile.
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
// Lightworks user effect NonlinearTrans.fx
//
// Version history:
//
// Updated 2026-07-17 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with float4 _TransparentBlack to fix Linux lerp()/mix() bug.
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-11 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-07 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Non-linear transitions", "Mix", "Blend transitions", "Dissolves using a range of non-linear profiles", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",                kNoGroup,         kNoFlags, 0.5, 0.0, 1.0);
DeclareIntParam (SetTechnique,     "Dissolve profile",      kNoGroup, 0,      "Non-additive mix|Ultra non-add|Trig curve|Quad curve");
DeclareFloatParam (Strength,       "Strength",              kNoGroup,         kNoFlags, 0.5, -1.0, 1.0);
DeclareBoolParam  (Blended,        "Enable blend transitions",                kNoGroup, false);

DeclareIntParam   (Source,         "Source",                "Blend settings", 0, "Extracted foreground|Image key or title (disconnect input)");
DeclareBoolParam  (SwapDir,        "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain,        "Fine tune",             "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam  (ShowKey,        "Show foreground key",   "Blend settings", false);
DeclareBoolParam  (SwapSource,     "Swap sources",          "Blend settings", false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI      3.1415926536
#define HALF_PI 1.5707963268

float4 _TransparentBlack = 0.0.xxxx;

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

   if (Source == 0) Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));

   // If alpha is zero we need any video to be blanked.  We do NOT need it to be
   // multiplied, so this is the simplest way to fix things.

   return Fgnd.a == 0.0 ? _TransparentBlack : Fgnd;
}

float4 fn_initBg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (F, xy1) : ReadPixel (B, xy2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

//-----------------------------------------------------------------------------------------//
// Shadows
//-----------------------------------------------------------------------------------------//

// Non-add

DeclarePass (Fg_N)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_N)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (NonAdd)
{
   float4 Fgnd = tex2D (Fg_N, uv3);
   float4 Bgnd = tex2D (Bg_N, uv3);
   float4 retval;

   float amount;

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         float alpha = Fgnd.a;

         amount = SwapDir ? Amount : 1.0 - Amount;

         Fgnd.a *= (1.0 - abs (Amount - 0.5)) * 2.0;
         Fgnd = lerp (_TransparentBlack, Fgnd, amount);

         retval = max (lerp (Bgnd, _TransparentBlack, amount), Fgnd);
         retval = lerp (Bgnd, retval, alpha);
      }
   }
   else {
      amount = (1.0 - abs (Amount - 0.5)) * 2.0;

      Fgnd = lerp (Fgnd, _TransparentBlack, Amount);
      Bgnd = lerp (_TransparentBlack, Bgnd, Amount);
      retval = saturate (max (Bgnd, Fgnd) * amount);
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// Ultra non-add

DeclarePass (Fg_U)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_U)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (NonAddUltra)
{
   float4 Fgnd = tex2D (Fg_U, uv3);
   float4 Bgnd = tex2D (Bg_U, uv3);
   float4 retval;

   float amount;

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         float alpha  = Fgnd.a;

         amount = SwapDir ? Amount : 1.0 - Amount;

         Fgnd.a *= (1.0 - abs (amount - 0.5)) * 2.0;
         retval = max (lerp (Bgnd, _TransparentBlack, amount), lerp (_TransparentBlack, Fgnd, amount));
         retval = lerp (Bgnd, retval, alpha);
      }
   }
   else {
      amount = (1.0 - abs (Amount - 0.5)) * 2.0;

      Fgnd = lerp (Fgnd, _TransparentBlack, Amount);
      Bgnd = lerp (_TransparentBlack, Bgnd, Amount);
      retval = saturate (amount * max (Bgnd, Fgnd));
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//

// Trig curve

DeclarePass (Fg_T)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_T)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Trig)
{
   float4 Fgnd = tex2D (Fg_T, uv3);
   float4 Bgnd = tex2D (Bg_T, uv3);
   float4 retval;

   float curve  = Strength < 0.0 ? Strength * 0.6666666667 : Strength;
   float amount = (1.0 + sin ((cos (Amount * PI)) * HALF_PI)) / 2.0;

   amount = lerp (Amount, 1.0 - amount, curve);

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         if (!SwapDir) amount = 1.0 - amount;

         retval = lerp (Bgnd, Fgnd, Fgnd.a * amount);
      }
   }
   else retval = lerp (Fgnd, Bgnd, amount);

   return retval;
}

//-----------------------------------------------------------------------------------------//

// Quad curve

DeclarePass (Fg_P)
{ return fn_initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bg_P)
{ return fn_initBg (Fg, uv1, Bg, uv2); }

DeclareEntryPoint (Quad)
{
   float4 Fgnd = tex2D (Fg_P, uv3);
   float4 Bgnd = tex2D (Bg_P, uv3);
   float4 retval;

   float amount = Amount * Amount * (3.0 - (Amount * 2.0));

   amount = lerp (Amount, amount, Strength + 1.0);

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         if (!SwapDir) amount = 1.0 - amount;

         retval = lerp (Bgnd, Fgnd, Fgnd.a * amount);
      }
   }
   else retval = lerp (Fgnd, Bgnd, amount);

   return retval;
}
