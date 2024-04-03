// @Maintainer jwrl
// @Released 2024-04-03
// @Author jwrl
// @Created 2024-04-03

/**
 This is a transition that's a modification of the earlier commpound push effect.
 Like that effect, the central area of the outgoing image can be pushed left, right,
 up or down to reveal the incoming media.  Unlike that earlier effect, the centre
 area can be adjusted in size and position.  Another difference is that the outer
 area is always pushed in the opposite direction to the central area to reveal the
 incoming media instead of being independently adjustable.

 As with the earlier effect, in normal mode the background can be reduced in level
 as the transition takes place to help separate it from the centre area,  This is
 disabled in blended transition mode.  For consistency with other effects masking
 has been provided even though it seems a little pointless given the nature of this
 effect and the fact that transitions with masking code don't use it.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Contrapush.fx
//
// Version history:
//
// Built 2024-04-03 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Contrapush", "Mix", "Wipe transitions", "Pushes the centre and edge video areas in opposite directions", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Direction of push", kNoGroup, 0, "Box left / outer right|Box right / outer left|Box up / outer down|Box down / outer up");

DeclareFloatParam (BoxWidth,  "Width",  "Box parameters", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (BoxHeight, "Height", "Box parameters", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (BoxPosX, "Position", "Box parameters", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (BoxPosY, "Position", "Box parameters", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (DarkenOuter, "Outer levels", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (Blended, "Enable blend transitions", kNoGroup, false);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Image key/Title pre 2023.2, no input|Image key or title without input");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define TWO_PI 6.283185

#define fixRange(P) clamp(P / 2.0, 0.025, 0.5)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 keygen (sampler F, float2 xy1, sampler B, float2 xy2)
{
   float4 Bgnd, Fgnd = ReadPixel (F, xy1);

   if (SwapSource) {
      Bgnd = Fgnd;
      Fgnd = ReadPixel (B, xy2);
   }
   else Bgnd = ReadPixel (B, xy2);

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

   if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;

   return Fgnd;
}

float4 initFg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   if (Blended) return SwapDir ? kTransparentBlack : keygen (F, xy1, B, xy2);

   return ReadPixel (F, xy1);
}

float4 initBg (sampler F, float2 xy1, sampler B, float2 xy2)
{
   if (Blended) return SwapDir ? keygen (F, xy1, B, xy2) : kTransparentBlack;

   return ReadPixel (B, xy2);
}

float4 OuterFix (sampler S, float2 uv, bool IsFg)
{
   float4 retval = tex2D (S, uv);

   float darken = saturate (DarkenOuter);

   if (Blended) {
      float x = fixRange (BoxWidth);
      float y = fixRange (BoxHeight);

      float2 xy = abs (uv - saturate (float2 (BoxPosX, 1.0 - BoxPosY)));

      if ((xy.x < x) && (xy.y < y)) retval *= darken;
   }
   else {
      bool blank = IsFg ? Amount > 0.5 : Amount < 0.5;

      float gain_adjust = blank ? 0.0 : (1.0 + cos (Amount * TWO_PI)) * 0.5;

      retval.rgb *= lerp (darken, 1.0, gain_adjust);
   }

   return retval;
}

bool Wlimits (float2 xy, out float A, out float B)
{
   float Wfix = fixRange (BoxWidth), Hfix = fixRange (BoxHeight);
   float Xfix = saturate (BoxPosX),  Yfix = 1.0 - saturate (BoxPosY);

   float Wmin = max (Xfix - Wfix, 0.0);
   float Wmax = min (Xfix + Wfix, 1.0);

   A = Wmax - Wmin;

   Wfix = A / 2.0;
   Xfix = (Wmax + Wmin) / 2.0;

   B  = Wfix + Xfix;

   xy = abs (xy - float2 (Xfix, Yfix));

   return (xy.x < Wfix) && (xy.y < Hfix);
}

bool Hlimits (float2 xy, out float A, out float B)
{
   float Wfix = fixRange (BoxWidth), Hfix = fixRange (BoxHeight);
   float Xfix = saturate (BoxPosX),  Yfix = saturate (BoxPosY);

   float Hmin = max (Yfix - Hfix, 0.0);
   float Hmax = min (Yfix + Hfix, 1.0);

   A = Hmax - Hmin;

   Hfix = A / 2.0;
   Yfix = 1.0 - ((Hmax + Hmin) / 2.0);

   B  = Hfix + Yfix;

   xy = abs (xy - float2 (Xfix, Yfix));

   return (xy.x < Wfix) && (xy.y < Hfix);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//
// Box left / outer right

DeclarePass (Fc0)
{ return initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bc0)
{ return initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Fb0)
{ return OuterFix (Fc0, uv3, true); }

DeclarePass (Bb0)
{ return OuterFix (Bc0, uv3, false); }

DeclareEntryPoint (ContraPush_0)
{
   float4 retval, Bgd = ReadPixel (Bg, uv2);

   float w, x, amt = saturate (Amount);

   bool inside = Wlimits (uv3, w, x);

   float2 xy1 = float2 (uv3.x + (amt * w), uv3.y);
   float2 xy2 = float2 (xy1.x - w, uv3.y);
   float2 xy3 = float2 (uv3.x - amt, uv3.y);
   float2 xy4 = float2 (xy3.x + 1.0, uv3.y);

   if (inside) { retval = xy1.x > x ? tex2D (Bc0, xy2) : tex2D (Fc0, xy1); }
   else retval = kTransparentBlack;

   if (Blended) {
      float4 partial = kTransparentBlack;

      if (SwapSource) Bgd = ReadPixel (Fg, uv1);

      if (ShowKey) { retval = SwapDir ? tex2D (Bc0, uv3) : tex2D (Fc0, uv3); }
      else {
         partial = SwapDir ? tex2D (Bb0, xy4) : tex2D (Fb0, xy3);
         partial = lerp (Bgd, partial, partial.a);
      }

      retval = lerp (partial, retval, retval.a);
   }
   else if (!inside) retval = IsOutOfBounds (xy3) ? tex2D (Bb0, xy4) : tex2D (Fb0, xy3);

   return lerp (Bgd, retval, tex2D (Mask, uv3).x);
}

//--  Box right / outer left  -------------------------------------------------------------//

DeclarePass (Fc1)
{ return initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bc1)
{ return initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Fb1)
{ return OuterFix (Fc1, uv3, true); }

DeclarePass (Bb1)
{ return OuterFix (Bc1, uv3, false); }

DeclareEntryPoint (ContraPush_1)
{
   float4 retval, Bgd = ReadPixel (Bg, uv2);

   float w, x, amt = 1.0 - saturate (Amount);

   bool inside = Wlimits (uv3, w, x);

   float2 xy1 = float2 (uv3.x + (amt * w), uv3.y);
   float2 xy2 = float2 (xy1.x - w, uv3.y);
   float2 xy3 = float2 (uv3.x - amt, uv3.y);
   float2 xy4 = float2 (xy3.x + 1.0, uv3.y);

   if (inside) { retval = xy1.x > x ? tex2D (Fc1, xy2) : tex2D (Bc1, xy1); }
   else retval = kTransparentBlack;

   if (Blended) {
      float4 partial = kTransparentBlack;

      if (ShowKey) { retval = SwapDir ? tex2D (Bc1, uv3) : tex2D (Fc1, uv3); }
      else {
         partial = SwapDir ? tex2D (Bb1, xy3) : tex2D (Fb1, xy4);
         partial = lerp (Bgd, partial, partial.a);
      }

      retval = lerp (partial, retval, retval.a);
   }
   else if (!inside) retval = IsOutOfBounds (xy3) ? tex2D (Fb1, xy4) : tex2D (Bb1, xy3);

   return lerp (Bgd, retval, tex2D (Mask, uv3).x);
}

//--  Box up / outer down  ----------------------------------------------------------------//

DeclarePass (Fc2)
{ return initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bc2)
{ return initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Fb2)
{ return OuterFix (Fc2, uv3, true); }

DeclarePass (Bb2)
{ return OuterFix (Bc2, uv3, false); }

DeclareEntryPoint (Contrapush_2)
{
   float4 retval, Bgd = ReadPixel (Bg, uv2);

   float h, y, amt = saturate (Amount);

   bool inside = Hlimits (uv3, h, y);

   float2 xy1 = float2 (uv3.x, uv3.y + (amt * h));
   float2 xy2 = float2 (uv3.x, xy1.y - h);
   float2 xy3 = float2 (uv3.x, uv3.y - amt);
   float2 xy4 = float2 (uv3.x, xy3.y + 1.0);

   if (inside) { retval = xy1.y > y ? tex2D (Bc2, xy2) : tex2D (Fc2, xy1); }
   else retval = kTransparentBlack;

   if (Blended) {
      float4 partial = kTransparentBlack;

      if (SwapSource) Bgd = ReadPixel (Fg, uv1);

      if (ShowKey) { retval = SwapDir ? tex2D (Bc2, uv3) : tex2D (Fc2, uv3); }
      else {
         partial = SwapDir ? tex2D (Bb2, xy4) : tex2D (Fb2, xy3);
         partial = lerp (Bgd, partial, partial.a);
      }

      retval = lerp (partial, retval, retval.a);
   }
   else if (!inside) retval = IsOutOfBounds (xy3) ? tex2D (Bb2, xy4) : tex2D (Fb2, xy3);

   return lerp (Bgd, retval, tex2D (Mask, uv3).x);
}

//--  Box down / outer up  ----------------------------------------------------------------//

DeclarePass (Fc3)
{ return initFg (Fg, uv1, Bg, uv2); }

DeclarePass (Bc3)
{ return initBg (Fg, uv1, Bg, uv2); }

DeclarePass (Fb3)
{ return OuterFix (Fc3, uv3, true); }

DeclarePass (Bb3)
{ return OuterFix (Bc3, uv3, false); }

DeclareEntryPoint (Contrapush_3)
{
   float4 retval, Bgd = ReadPixel (Bg, uv2);

   float h, y, amt = 1.0 - saturate (Amount);

   bool inside = Hlimits (uv3, h, y);

   float2 xy1 = float2 (uv3.x, uv3.y + (amt * h));
   float2 xy2 = float2 (uv3.x, xy1.y - h);
   float2 xy3 = float2 (uv3.x, uv3.y - amt);
   float2 xy4 = float2 (uv3.x, xy3.y + 1.0);

   if (inside) { retval = xy1.y > y ? tex2D (Fc3, xy2) : tex2D (Bc3, xy1); }
   else retval = kTransparentBlack;

   if (Blended) {
      float4 partial = kTransparentBlack;

      if (SwapSource) Bgd = ReadPixel (Fg, uv1);

      if (ShowKey) { retval = SwapDir ? tex2D (Bc2, uv3) : tex2D (Fc2, uv3); }
      else {
         partial = SwapDir ? tex2D (Bb3, xy3) : tex2D (Fb3, xy4);
         partial = lerp (Bgd, partial, partial.a);
      }

      retval = lerp (partial, retval, retval.a);
   }
   else if (!inside) retval = IsOutOfBounds (xy3) ? tex2D (Fb3, xy4) : tex2D (Bb3, xy3);

   return lerp (Bgd, retval, tex2D (Mask, uv3).x);
}

