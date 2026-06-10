// @Maintainer jwrl
// @Released 2026-06-10
// @Author jwrl
// @Created 2016-06-30

/**
 Edge glow (EdgeGlowFx.fx) is an effect that can use image levels or the edges of the
 image to produce a glow effect.  The resulting glow can be applied to the image using
 any of five blend modes.  The glow can use the native image colours, a preset colour,
 or two colours which cycle.  Cycle rate can be adjusted, and the detected edges can be
 mixed back over the effect.

 The settings are:

   [*]Glow
      [*]Mode:  Selects whether to generate the glow from the luminance level of the
         incoming video or to use the edges of the video.
      [*]Sensitivity:  In luminance mode, acts as a clip level adjustment, in edge
         detect mode, varies the edge detection sensitivity.
      [*]Size:  Adjusts the glow width.
      [*]Edge mix:   Adjusts the amount of the glow to be mixed back over the video.
   [*]Glow colour
      [*]Mode:  Allows the glow to be derived from the image colour, a preselected
         colour set by colour 1 or colours cycled between colour 1 and colour 2.
      [*]Blend:  This is a subset of Photoshop-style blend modes to use when blending
         the glow over the video.
      [*]Cycle rate:  When "Cycle colours" is chosen this sets the rate.  It has no
         purpose at any other time.
      [*]Colour 1:  Used as the sole colour in "Colour 1" mode, and as the primary
         colour in "Cycle colours"" mode.
      [*]Colour 2:  This is used as the secondary colour when "Cycle colours" is
         selected.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect EdgeGlow.fx
//
// Version history:
//
// Updated 2026-06-10 jwrl.
// Added command descriptions to header text.
// Changed masking to full RGBA.
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with float4 _TransparentBlack for Linux fix.
//
// Updated 2023-05-14 jwrl.
// Header reformatted.
//
// Conversion 2022-12-28 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Edge glow", "Stylize", "Art Effects", "Adds a level-based or edge-based glow to an image", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (lCycle, "Mode", "Glow", 1, "Luminance|Edge detect");
DeclareFloatParam (lRate, "Sensitivity", "Glow", kNoFlags, 0.75, 0.0, 1.0);
DeclareFloatParam (Size, "Size", "Glow", kNoFlags, 0.15, 0.0, 1.0);
DeclareFloatParam (EdgeMix, "Edge mix", "Glow", kNoFlags, 0.0, 0.0, 1.0);

DeclareIntParam (cCycle, "Mode", "Glow colour", 1, "Image colour|Colour 1|Cycle colours");
DeclareIntParam (SetTechnique, "Blend", "Glow colour", 0, "Add|Screen|Lighten|Soft glow|Vivid light");
DeclareFloatParam (cRate, "Cycle rate", "Glow colour", kNoFlags, 0.2, 0.0, 1.0);
DeclareColourParam (Colour_1, "Colour 1", "Glow colour", kNoFlags, 1.0, 0.75, 0.0, 1.0);
DeclareColourParam (Colour_2, "Colour 2", "Glow colour", kNoFlags, 1.0, 1.0, 0.0, 1.0);

DeclareFloatParam (_Progress);
DeclareFloatParam (_Length);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LOOP     12
#define DIVIDE   49

#define RADIUS_1 4.0
#define RADIUS_2 10.0
#define RADIUS_3 20.0
#define RADIUS_4 35.0

#define ANGLE    0.2617993878

#define R_VALUE  0.3
#define G_VALUE  0.59
#define B_VALUE  0.11

#define L_RATE   0.002
#define G_SIZE   0.0005

#define HALF_PI  1.5707963268

float4 _TransparentBlack = 0.0.xxxx;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_get_luma (sampler s, float2 xy)
{
   float4 Fgd = tex2D (s, xy);

   return (Fgd.r + Fgd.g + Fgd.b) / 3.0;
}

float4 fn_getEdge (sampler Inp, float2 uv)
{
   if (IsOutOfBounds (uv)) return _TransparentBlack;

   float4 Fgd = tex2D (Inp, uv);
   float edges, pattern;

   if (lCycle == 1) {
      float nVal = 0.0;
      float xVal = L_RATE * lRate;
      float yVal = xVal * _OutputAspectRatio;

      float p2 = -1.0 * fn_get_luma (Inp, uv + float2 (xVal, yVal));
      float p1 = p2;

      p1 += fn_get_luma (Inp, uv - float2 (xVal, yVal));
      p1 += fn_get_luma (Inp, uv - float2 (xVal, -yVal));
      p1 -= fn_get_luma (Inp, uv + float2 (xVal, -yVal));
      p1 -= fn_get_luma (Inp, uv + float2 (xVal, nVal)) * 2.0;
      p1 += fn_get_luma (Inp, uv - float2 (xVal, nVal)) * 2.0;

      p2 += fn_get_luma (Inp, uv - float2 (xVal, yVal));
      p2 -= fn_get_luma (Inp, uv - float2 (xVal, -yVal));
      p2 += fn_get_luma (Inp, uv + float2 (xVal, -yVal));
      p2 -= fn_get_luma (Inp, uv + float2 (nVal, yVal)) * 2.0;
      p2 += fn_get_luma (Inp, uv - float2 (nVal, yVal)) * 2.0;

      edges = saturate (p1 * p1 + p2 * p2);
   }
   else {
      edges = dot (Fgd.rgb, float3 (R_VALUE, G_VALUE, B_VALUE));

      if (edges < (1.0 - lRate)) edges = 0.0;
   }

   pattern = _Progress * _Length * (1.0 + (cRate * 20.0));

   if (cCycle == 0) return lerp (_TransparentBlack, Fgd, edges);

   float4 part_1 = edges * Colour_1;
   float4 part_2 = edges * Colour_2;

   pattern = (cCycle == 2) ? (sin (pattern) * 0.5) + 0.5 : 0.0;

   return lerp (part_1, part_2, pattern);
}

float4 fn_glow (sampler gloSampler, float2 uv, float base)
{
   if (IsOutOfBounds (uv)) return _TransparentBlack;

   float4 retval = tex2D (gloSampler, uv);

   if (Size <= 0.0) return retval;

   float2 xy, radius = float2 (1.0, _OutputAspectRatio) * base * Size * G_SIZE;

   for (int i = 0; i < LOOP; i++) {
      sincos ((i * ANGLE), xy.x, xy.y);
      xy *= radius;
      retval += tex2D (gloSampler, uv + xy);
      retval += tex2D (gloSampler, uv - xy);
      xy += xy;
      retval += tex2D (gloSampler, uv + xy);
      retval += tex2D (gloSampler, uv - xy);
   }

   return retval / DIVIDE;
}

float4 fn_fullGlow (sampler gloSampler, sampler s_Edge, float2 uv)
{
   if (IsOutOfBounds (uv)) return _TransparentBlack;

   float4 retval = tex2D (gloSampler, uv);

   float sizeComp = saturate (Size * 4.0);

   sizeComp = sin (sizeComp * HALF_PI);
   retval = lerp (_TransparentBlack, retval, sizeComp);

   if (lCycle != 1) return retval;

   float4 Glow = max (retval, tex2D (s_Edge, uv));

   return lerp (retval, Glow, EdgeMix);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// EdgeGlowAdd

DeclarePass (A_0)
{ return fn_getEdge (Input, uv1); }

DeclarePass (A_1)
{ return fn_glow (A_0, uv1, RADIUS_1); }

DeclarePass (A_2)
{ return fn_glow (A_1, uv1, RADIUS_2); }

DeclarePass (A_3)
{ return fn_glow (A_2, uv1, RADIUS_3); }

DeclarePass (A_4)
{ return fn_glow (A_3, uv1, RADIUS_4); }

DeclarePass (A_Glow)
{ return fn_fullGlow (A_4, Input, uv1); }

DeclareEntryPoint (EdgeGlowAdd)
{
   if (IsOutOfBounds (uv1)) return _TransparentBlack;

   float4 Fgnd = tex2D (Input, uv1);
   float4 Glow = saturate (Fgnd + tex2D (A_Glow, uv1));

   Glow.a = Fgnd.a;

   return lerp (Fgnd, Glow, tex2D (Mask, uv1));
}

//-----------------------------------------------------------------------------------------//

// EdgeGlowScreen

DeclarePass (S_0)
{ return fn_getEdge (Input, uv1); }

DeclarePass (S_1)
{ return fn_glow (S_0, uv1, RADIUS_1); }

DeclarePass (S_2)
{ return fn_glow (S_1, uv1, RADIUS_2); }

DeclarePass (S_3)
{ return fn_glow (S_2, uv1, RADIUS_3); }

DeclarePass (S_4)
{ return fn_glow (S_3, uv1, RADIUS_4); }

DeclarePass (S_Glow)
{ return fn_fullGlow (S_4, Input, uv1); }

DeclareEntryPoint (EdgeGlowScreen)
{
   if (IsOutOfBounds (uv1)) return _TransparentBlack;

   float4 Fgnd   = tex2D (Input, uv1);
   float4 Glow   = tex2D (S_Glow, uv1);
   float4 retval = saturate (Fgnd + Glow - (Fgnd * Glow));

   retval.a = Fgnd.a;

   return lerp (Fgnd, retval, tex2D (Mask, uv1));
}

//-----------------------------------------------------------------------------------------//

// EdgeGlowLighten

DeclarePass (L_0)
{ return fn_getEdge (Input, uv1); }

DeclarePass (L_1)
{ return fn_glow (L_0, uv1, RADIUS_1); }

DeclarePass (L_2)
{ return fn_glow (L_1, uv1, RADIUS_2); }

DeclarePass (L_3)
{ return fn_glow (L_2, uv1, RADIUS_3); }

DeclarePass (L_4)
{ return fn_glow (L_3, uv1, RADIUS_4); }

DeclarePass (L_Glow)
{ return fn_fullGlow (L_4, Input, uv1); }

DeclareEntryPoint (EdgeGlowLighten)
{
   if (IsOutOfBounds (uv1)) return _TransparentBlack;

   float4 Fgnd = tex2D (Input, uv1);
   float4 Glow = max (Fgnd, tex2D (L_Glow, uv1));

   Glow.a = Fgnd.a;

   return lerp (Fgnd, Glow, tex2D (Mask, uv1));
}

//-----------------------------------------------------------------------------------------//

// EdgeGlowSoftGlow

DeclarePass (SG_0)
{ return fn_getEdge (Input, uv1); }

DeclarePass (SG_1)
{ return fn_glow (SG_0, uv1, RADIUS_1); }

DeclarePass (SG_2)
{ return fn_glow (SG_1, uv1, RADIUS_2); }

DeclarePass (SG_3)
{ return fn_glow (SG_2, uv1, RADIUS_3); }

DeclarePass (SG_4)
{ return fn_glow (SG_3, uv1, RADIUS_4); }

DeclarePass (SG_Glow)
{ return fn_fullGlow (SG_4, Input, uv1); }

DeclareEntryPoint (EdgeGlowSoftGlow)
{
   if (IsOutOfBounds (uv1)) return _TransparentBlack;

   float4 Fgnd   = tex2D (Input, uv1);
   float4 Glow   = Fgnd * tex2D (SG_Glow, uv1);
   float4 retval = saturate (Fgnd + Glow - (Fgnd * Glow));

   retval.a = Fgnd.a;

   return lerp (Fgnd, retval, tex2D (Mask, uv1));
}

//-----------------------------------------------------------------------------------------//

// EdgeGlowVividLight

DeclarePass (VL_0)
{ return fn_getEdge (Input, uv1); }

DeclarePass (VL_1)
{ return fn_glow (VL_0, uv1, RADIUS_1); }

DeclarePass (VL_2)
{ return fn_glow (VL_1, uv1, RADIUS_2); }

DeclarePass (VL_3)
{ return fn_glow (VL_2, uv1, RADIUS_3); }

DeclarePass (VL_4)
{ return fn_glow (VL_3, uv1, RADIUS_4); }

DeclarePass (VL_Glow)
{ return fn_fullGlow (VL_4, Input, uv1); }

DeclareEntryPoint (EdgeGlowVividLight)
{
   if (IsOutOfBounds (uv1)) return _TransparentBlack;

   float4 Fgnd = tex2D (Input, uv1);
   float4 Glow = saturate ((tex2D (VL_Glow, uv1) * 2.0) + Fgnd - 1.0.xxxx);

   Glow.a = Fgnd.a;

   return lerp (Fgnd, Glow, tex2D (Mask, uv1));
}
