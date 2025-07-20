// @Maintainer jwrl
// @Released 2025-07-20
// @Author jwrl
// @Created 2025-07-20

/**
 This effect performs a vertical or horizontal push transition between two sources.
 The overlap between the two sources can be adjusted over a wide range. A directional
 blur can be applied to the composite push to (sort of) emulate a whip pan if needed.
 The blur reaches its maximum at the centre of the push and follows a curved path in
 and out.  It's simple to set up, having just five parameters.

   * Push direction:  Selects a push from left to right, right to left, top to bottom
     and bottom to top.
   * Progress:  Sets and shows the progress of the push.
   * Overlap
      * Amount:  Adjusts the amount of overlap between the two sources.
      * Edge mix:  Adjusts the width of the overlap mix.  It's limited to the available overlap.
   * Blur:  Controls the amount of the blur in the direction of the push.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AdjustablePush.fx
//
// Version history:
//
// Built 2025-07-20 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Adjustable push", "Mix", "Wipe transitions", "Push with variable overlap and directional blur", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Push direction", kNoGroup, 0, "Left to right|Right to left|Top to bottom|Bottom to top");

DeclareFloatParamAnimated (Progress, "Progress", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Amount,  "Amount",   "Overlap", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (EdgeMix, "Edge mix", "Overlap", kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Blur, "Blur", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI        3.1415926536

#define SAMPLES   30
#define SAMPSCALE 61.0

#define STRENGTH  0.0025

#define HORIZ     true
#define VERT      false

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float generateOverlap (out float pushIn)
{
   float overlap = Amount * 0.25;
   float pushOut;

   pushIn  = saturate (Progress * (1.0 + overlap)) - 1.0;
   pushOut = saturate (Progress * (1.0 + overlap) - overlap);

   return pushOut;
}

float4 directionalBlur (sampler video, float2 uv, bool mode)
{
   float4 retval = tex2D (video, uv);

   float amount = pow (sin (Progress * PI), 2.0);

   if ((amount <= 0.0) || (Blur <= 0.0)) return retval;

   float2 xy0 = mode ? float2 (amount, 0.0) : float2 (0.0, amount * _OutputAspectRatio);
   float2 xy1 = uv;
   float2 xy2 = uv;

   xy0 *= Blur * STRENGTH;

   for (int i = 0; i < SAMPLES; i++) {
      xy1 -= xy0;
      xy2 += xy0;
      retval += tex2D (video, xy1) + tex2D (video, xy2);
   }

   return retval / SAMPSCALE;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

//  Push left to right

DeclarePass (Fg0)
{ return directionalBlur (Fg, uv1, HORIZ); }

DeclarePass (Bg0)
{
   float4 retval = directionalBlur (Bg, uv2, HORIZ);

   float overlap = Amount * EdgeMix * 0.25;
   float start   = 1.0 - overlap;
   float coord   = uv2.x - smoothstep (start, 1.0, Progress) * overlap;

   if (coord >= start) retval.a *= 1.0 - smoothstep (start, 1.0, coord);

   return retval;
}

DeclareEntryPoint (AdjustablePushLR)
{
   float incoming;
   float outgoing = generateOverlap (incoming);

   float4 outwards = ReadPixel (Fg0, float2 (uv3.x - outgoing, uv3.y));
   float4 inwards  = ReadPixel (Bg0, float2 (uv3.x - incoming, uv3.y));

   return lerp (outwards, inwards, inwards.a);
}

//-----------------------------------------------------------------------------------------//

//  Push right to left

DeclarePass (Fg1)
{ return directionalBlur (Fg, uv1, HORIZ); }

DeclarePass (Bg1)
{
   float4 retval = directionalBlur (Bg, uv2, HORIZ);

   float overlap = Amount * EdgeMix * 0.25; // lerp (0.0, Amount * 0.25, EdgeMix);
   float start = 1.0 - overlap;
   float coord  = 1.0 - uv2.x - smoothstep (start, 1.0, Progress) * overlap;

   if (coord >= start) retval.a *= 1.0 - smoothstep (start, 1.0, coord);

   return retval;
}

DeclareEntryPoint (AdjustablePushRL)
{
   float incoming;
   float outgoing = generateOverlap (incoming);

   float4 outwards = ReadPixel (Fg1, float2 (uv3.x + outgoing, uv3.y));
   float4 inwards  = ReadPixel (Bg1, float2 (uv3.x + incoming, uv3.y));

   return lerp (outwards, inwards, inwards.a);
}

//-----------------------------------------------------------------------------------------//

//  Push top to bottom

DeclarePass (Fg2)
{ return directionalBlur (Fg, uv1, VERT); }

DeclarePass (Bg2)
{
   float4 retval = directionalBlur (Bg, uv2, VERT);

   float overlap = Amount * EdgeMix * 0.25; // lerp (0.0, Amount * 0.25, EdgeMix);
   float start   = 1.0 - overlap;
   float coord   = uv2.y - smoothstep (start, 1.0, Progress) * overlap;

   if (coord >= start) retval.a *= 1.0 - smoothstep (start, 1.0, coord);

   return retval;
}

DeclareEntryPoint (AdjustablePushDown)
{
   float incoming;
   float outgoing = generateOverlap (incoming);

   float4 outwards = ReadPixel (Fg2, float2 (uv3.x, uv3.y - outgoing));
   float4 inwards  = ReadPixel (Bg2, float2 (uv3.x, uv3.y - incoming));

   return lerp (outwards, inwards, inwards.a);
}

//-----------------------------------------------------------------------------------------//

//  Push bottom to top

DeclarePass (Fg3)
{ return directionalBlur (Fg, uv1, VERT); }

DeclarePass (Bg3)
{
   float4 retval = directionalBlur (Bg, uv2, VERT);

   float overlap = Amount * EdgeMix * 0.25; // lerp (0.0, Amount * 0.25, EdgeMix);
   float start   = 1.0 - overlap;
   float coord   = 1.0 - uv2.y - smoothstep (start, 1.0, Progress) * overlap;

   if (coord >= start) retval.a *= 1.0 - smoothstep (start, 1.0, coord);

   return retval;
}

DeclareEntryPoint (AdjustablePushUp)
{
   float incoming;
   float outgoing = generateOverlap (incoming);

   float4 outwards = ReadPixel (Fg3, float2 (uv3.x, uv3.y + outgoing));
   float4 inwards  = ReadPixel (Bg3, float2 (uv3.x, uv3.y + incoming));

   return lerp (outwards, inwards, inwards.a);
}

