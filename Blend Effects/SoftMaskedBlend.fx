// @Maintainer jwrl
// @Released 2024-07-17
// @Author jwrl
// @Created 2024-07-17

/**
 "Soft masked blend" is similar to the Lightworks mask effect, and is intended to be used
 where a border similar to that provided with Lightworks' wipe effects is wanted.  The
 mask must be connected to the Msk input and is expected to be white on black by default,
 but can be switched to make use of the mask's alpha channel if one is available.  Unlike
 the Lightworks masked blend the only blending mode provided is the one that Lightworks
 calls "In Front".

 The foreground alpha channel is honoured so that where the Fg input is transparent Bg
 will show through even though it's inside the mask area.  Where that blend happens both
 Fg and Bg alpha channels are combined to give the correct output transparency.

 Softness and border width are both adjustable, as is the border colour.  Border width
 interacts with softness, and provides a means of adjusting the border colour blending
 softness.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SoftMaskedBlend.fx
//
// Version history:
//
// Created 2024-07-17 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Soft masked blend", "Mix", "Blend Effects", "External mask with edge softness and border", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);
DeclareInput  (Msk, Linear, Mirror);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Fg Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareBoolParam  (AlphaMask,  "Use alpha from external mask", kNoGroup, false);
DeclareBoolParam  (InvertMask, "Invert external mask",         kNoGroup, false);

DeclareFloatParam  (Softness,    "Softness",     "External mask edge", kNoFlags, 0.1,  0.0, 1.0);
DeclareFloatParam  (BorderWidth, "Border width", "External mask edge", kNoFlags, 0.0,  0.0, 1.0);
DeclareColourParam (Colour_1,    "Colour 1",     "External mask edge", kNoFlags, 1.0, 1.0, 0.0);
DeclareColourParam (Colour_2,    "Colour 2",     "External mask edge", kNoFlags, 1.0, 0.0, 0.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI_HALF  1.5708    // 90 degrees in radians
#define PI_SIXTH 0.5236    // 30 degrees in radians

#define OFFSET_1 0.0873    // 5 degrees in radians
#define OFFSET_2 0.1745    // 10
#define OFFSET_3 0.2618    // 15
#define OFFSET_4 0.3491    // 20
#define OFFSET_5 0.4363    // 25

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_BlurMask (sampler2D S, float2 uv, float offset)
{
   float blur = Softness * 0.05;

   uv -= 0.5.xx;
   uv *= 1.0 - (blur * 0.1);
   uv += 0.5.xx;

   float2 radius = float2 (1.0, _OutputAspectRatio) * blur;
   float2 angle  = float2 (offset + PI_HALF, offset);
   float2 coord, sample;

   float4 retval = tex2D (S, uv);

   for (int tap = 0; tap < 12; tap++) {
      sample = sin (angle);
      coord  = (1.0.xx - abs (1.0.xx - abs (uv))) + (sample * radius);
      retval  += tex2D (S, coord);
      angle += PI_SIXTH;
   }

   return ((retval.r + retval.g + retval.b) / 39.0).xxxx;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);
   float4 ret = lerp (ReadPixel (Bg, uv2), Fgd, Fgd.a);

   ret.a = max (Fgd.a, Bgd.a);

   return ret;
}

DeclarePass (M_0)
{
   float4 retval = ReadPixel (Msk, uv3);

   return AlphaMask ? retval.aaaa : retval;
}

DeclarePass (M_1)
{
   return fn_BlurMask (M_0, uv4, 0.0);
}

DeclarePass (M_2)
{
   return fn_BlurMask (M_1, uv4, OFFSET_1);
}

DeclarePass (M_3)
{
   return fn_BlurMask (M_2, uv4, OFFSET_2);
}

DeclarePass (M_4)
{
   return fn_BlurMask (M_3, uv4, OFFSET_3);
}

DeclarePass (M_5)
{
   return fn_BlurMask (M_4, uv4, OFFSET_4);
}

DeclarePass (BlurMask)
{
   return fn_BlurMask (M_5, uv4, OFFSET_5);
}

DeclareEntryPoint (SoftMaskedBlend)
{
   float alpha = tex2D (BlurMask, uv4).x;

   if (InvertMask) alpha = 1.0 - alpha;

   float4 Fgnd = tex2D (Fgd, uv4);
   float4 Bgnd = ReadPixel (Bg, uv2);
   float4 retval = lerp (Bgnd, Fgnd, alpha);

   if (BorderWidth > 0.0) {
      float alpha_0 = smoothstep (saturate (0.5 - BorderWidth), saturate (0.5 + BorderWidth), alpha);
      float alpha_1 = saturate (alpha * 2.0);
      float alpha_2 = saturate ((alpha * 2.0) - 1.0);

      float4 Colour = lerp (Colour_1, Colour_2, alpha_0);

      Colour = lerp (Bgnd, Colour, alpha_1);
      Colour = lerp (Colour, Fgnd, alpha_2);
      retval = lerp (retval, Colour, saturate (BorderWidth * 40.0));
   }

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Opacity);
}

