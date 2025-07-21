// @Maintainer jwrl
// @Released 2025-07-21
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
// Modified 2025-07-21 jwrl.
// Commented code and did some code optimisation.
// Rewrote wherever smoothstep() had been used.  It was found to be non-linear.
//
// Built 2025-07-20 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Adjustable push", "Mix", "Wipe transitions", "Variable push overlap with directional blur", CanSize);

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

#define TWO_PI    6.2831853072
#define PI        3.1415926536

#define SAMPLES   30
#define SAMPSCALE 61.0

#define STRENGTH  0.0025

#define SCALE     0.25

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// This function generates both the outgoing and incoming push values.

// The incoming ramp starts at Progress = 0.0 and ends at Progress = 1.0 - overlap,
// which corresponds to a range of -1.0 to 0.0.

// The outgoing ramp starts at Progress = overlap and ends at Progress = 1.0, giving
// a range of 0.0 to 1.0.

float generatePush (out float pushIn)
{
   float overlap  = Amount * SCALE;
   float progress = Progress * (1.0 + overlap);

   pushIn  = saturate (progress) - 1.0;

   return saturate (progress - overlap);
}

// This is one half of a box blur, used only for the horizontal directional/motion blur.
// Since box blurs are so widely understood, very little commenting has been provided.

float4 directionalBlurX (sampler video, float2 uv)
{
   float4 retval = tex2D (video, uv);

   // The blur increases to a maximum at Progress = 50% then returns to zero.  A
   // trigonometric curve has been created by applying cos() to Progress.

   float amount = (1.0 - cos (Progress * TWO_PI)) / 2.0;

   if ((amount <= 0.0) || (Blur <= 0.0)) return retval;

   float2 xy0 = float2 (amount, 0.0);
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

// This is the second half of the box blur, only used for the vertical directional blur.

float4 directionalBlurY (sampler video, float2 uv)
{
   float4 retval = tex2D (video, uv);

   float amount = (1.0 - cos (Progress * TWO_PI)) / 2.0;

   if ((amount <= 0.0) || (Blur <= 0.0)) return retval;

   float2 xy0 = float2 (0.0, amount * _OutputAspectRatio);
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

//-----  Push left to right  --------------------------------------------------------------//

// This first pass produces a horizontal blur for the outgoing video on Fg.

DeclarePass (Fg0)
{ return directionalBlurX (Fg, uv1); }

// This produces the blur for the incoming video on Bg.  It then produces the blend
// overlap and applies it to the alpha channel for later use in the final pass.

DeclarePass (Bg0)
{
   float4 retval = directionalBlurX (Bg, uv2);

   float overlap = Amount * EdgeMix * SCALE;
   float start   = 1.0 - overlap;
   float coord   = uv2.x - saturate ((Progress - start) / overlap) * overlap;

   if (coord >= start) retval.a *= 1.0 - saturate ((coord - start) / overlap);

   return retval;
}

// The incoming and outgoing video is recovered with the appropriate pushes.  They
// are then combined using the alpha channel of the incoming video.

DeclareEntryPoint (AdjustablePushLR)
{
   float incoming;
   float outgoing = generatePush (incoming);

   float4 outwards = ReadPixel (Fg0, float2 (uv3.x - outgoing, uv3.y));
   float4 inwards  = ReadPixel (Bg0, float2 (uv3.x - incoming, uv3.y));

   return lerp (outwards, inwards, inwards.a);
}

//-----  Push right to left  --------------------------------------------------------------//

// The comments for the left to right passes apply here, with the direction changed.

DeclarePass (Fg1)
{ return directionalBlurX (Fg, uv1); }

DeclarePass (Bg1)
{
   float4 retval = directionalBlurX (Bg, uv2);

   float overlap = Amount * EdgeMix * SCALE;
   float start   = 1.0 - overlap;
   float coord   = 1.0 - uv2.x - saturate ((Progress - start) / overlap) * overlap;

   if (coord >= start) retval.a *= 1.0 - saturate ((coord - start) / overlap);

   return retval;
}

DeclareEntryPoint (AdjustablePushRL)
{
   float incoming;
   float outgoing = generatePush (incoming);

   float4 outwards = ReadPixel (Fg1, float2 (uv3.x + outgoing, uv3.y));
   float4 inwards  = ReadPixel (Bg1, float2 (uv3.x + incoming, uv3.y));

   return lerp (outwards, inwards, inwards.a);
}

//-----  Push top to bottom  --------------------------------------------------------------//

// The comments for the left to right passes apply here, with the direction changed.

DeclarePass (Fg2)
{ return directionalBlurY (Fg, uv1); }

DeclarePass (Bg2)
{
   float4 retval = directionalBlurY (Bg, uv2);

   float overlap = Amount * EdgeMix * SCALE;
   float start   = 1.0 - overlap;
   float coord   = uv2.y - saturate ((Progress - start) / overlap) * overlap;

   if (coord >= start) retval.a *= 1.0 - saturate ((coord - start) / overlap);

   return retval;
}

DeclareEntryPoint (AdjustablePushDown)
{
   float incoming;
   float outgoing = generatePush (incoming);

   float4 outwards = ReadPixel (Fg2, float2 (uv3.x, uv3.y - outgoing));
   float4 inwards  = ReadPixel (Bg2, float2 (uv3.x, uv3.y - incoming));

   return lerp (outwards, inwards, inwards.a);
}

//-----  Push bottom to top  --------------------------------------------------------------//

// The comments for the left to right passes apply here, with the direction changed.

DeclarePass (Fg3)
{ return directionalBlurY (Fg, uv1); }

DeclarePass (Bg3)
{
   float4 retval = directionalBlurY (Bg, uv2);

   float overlap = Amount * EdgeMix * SCALE;
   float start   = 1.0 - overlap;
   float coord   = 1.0 - uv2.y - saturate ((Progress - start) / overlap) * overlap;

   if (coord >= start) retval.a *= 1.0 - saturate ((coord - start) / overlap);

   return retval;
}

DeclareEntryPoint (AdjustablePushUp)
{
   float incoming;
   float outgoing = generatePush (incoming);

   float4 outwards = ReadPixel (Fg3, float2 (uv3.x, uv3.y + outgoing));
   float4 inwards  = ReadPixel (Bg3, float2 (uv3.x, uv3.y + incoming));

   return lerp (outwards, inwards, inwards.a);
}
