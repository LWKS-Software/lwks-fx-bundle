// @Maintainer jwrl
// @Released 2025-03-26
// @Author jwrl
// @Created 2025-03-18

/**
 This effect is similar to Lightworks "Old Time Movie" effect, but has some
 additions. As well as the scratch and grain settings, there is sepia tone
 adjustment and jitter, which simulates worn sprocket holes. Jitter not only
 moves the frame horizontally and vertically, but adds rotation as well.
 The vignette amount is also adjustable.

 The sepia toning has been visually matched to that colour by comparison
 with old photographic prints.  It mimics the chemical changes in film
 stocks very closely.  At it's strongest the lighter areas will appear
 almost white. while the contrast increases as the image becomes more
 sepia, which is what actually happens with film ageing.

 So now to the settings:

   [*] Grain.
      [*] Amount:  Controls the visibility of the grain.
      [*] Size:  Adjusts the grain size from very fine to blobby.
      [*] Softness:  Adjusts the grain softness.
   [*] Ageing.
      [*] Exposure:  This parameter controls exposure before applying the sepia tone.
      [*] Sepia tone:  Adjusts the sepia tone amount.
   [*] Damage.
      [*] Neg scratches:  Controls the number of white scratches.
      [*] Pos scratches:  Controls the number of black scratches.
      [*] Jitter:  Simulates worn sprocket holes by jittering the frame.
      [*] Jitter rate:  Adjusts the jitter rate.
   [*] Projection.
      [*] Lamp falloff:  Darkens the frame edges to simulate projector lamp falloff.
      [*] Falloff size:  Sets the diameter of the falloff vignette.
      [*] Falloff edge:  Sets the softness of the falloff vignette.
      [*] Flicker:  Applies flicker to the image.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SilentMovie.fx
//
// Version history:
//
// Updated 2025-03-26 by jwrl.
// Added rotation to the jitter.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Silent movie", "Stylize", "Film Effects", "This produces adjustable film ageing", "CanSize");

///-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (GrainAmount, "Amount",   "Grain", kNoFlags, 0.5,   0.0, 1.0);
DeclareFloatParam (GrainSize,   "Size",     "Grain", kNoFlags, 0.125, 0.0, 1.0);
DeclareFloatParam (GrainBlur,   "Softness", "Grain", kNoFlags, 0.5,   0.0, 1.0);

DeclareFloatParam (Exposure,  "Exposure",   "Ageing", "DisplayAsLiteral", 0.0, -1.0, 1.0);
DeclareFloatParam (SepiaTone, "Sepia tone", "Ageing", kNoFlags,           0.5,  0.0, 1.0);

DeclareFloatParam (NegScratches,  "Neg scratches", "Damage", kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (PosScratches,  "Pos scratches", "Damage", kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (JitterAmount,  "Jitter",        "Damage", kNoFlags, 0.3, 0.0, 1.0);
DeclareFloatParam (JitterRate,    "Jitter rate",   "Damage", kNoFlags, 0.5, 0.0, 2.0);

DeclareFloatParam (LampFalloff, "Lamp falloff", "Projection", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (FalloffSize, "Falloff size", "Projection", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (FalloffEdge, "Falloff edge", "Projection", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Flicker,     "Flicker",      "Projection", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_Progress);
DeclareFloatParam (_Length);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define B_SCALE 0.000545

#define LUMA  float3(0.26, 0.43, 0.31)
#define SEPIA float3(0.9, 0.8, 0.6)

#define SIXTH 0.1666667.xxx
#define THIRD 0.3333333.xxx
#define HALF  0.5.xxx
#define UNITY 1.0.xxx

float4 _TransparentBlack = 0.0.xxxx;

// Pascal's triangle magic numbers for blur

float _pascal [] = { 0.3125, 0.2344, 0.09375, 0.01563 };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 mirrorXY (float2 uv)
{
   float2 xy = 1.0.xx - abs (uv);

   return abs (1.0.xx - abs (xy));
}

float3 rand_3 (float3 uvw)
{
   float j = 4096.0 * sin (dot (uvw, float3 (17.0, 59.4, 15.0)));

   return frac (float3 (512.0, 64.0, 8.0) * j);
}

float weave (float3 posn)
{    
   float3 a = floor (posn + dot (posn, THIRD).xxx);

   float3 x0 = posn + dot (a, SIXTH).xxx - a;

   float3 i  = step (0.0.xxx, x0 - x0.yzx);

   float3 i0 = UNITY - i;
   float3 i1 = i * i0.zxy;
   float3 i2 = UNITY - (i.zxy * i0);

   float3 x1 = x0 - i1 + SIXTH;
   float3 x2 = x0 - i2 + THIRD;
   float3 x3 = x0 - HALF;

   float4 ret = float4 (dot (x0, x0), dot (x1, x1), dot (x2, x2), dot (x3, x3));

   ret  = pow (max (0.6.xxxx - ret, 0.0.xxxx), 4.0);
   ret *= float4 (dot (rand_3 (a) - HALF, x0), dot (rand_3 (a + i1) - HALF, x1),
                  dot (rand_3 (a + i2) - HALF, x2), dot (rand_3 (a + UNITY) - HALF, x3));

   return dot (ret, 52.0.xxxx);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Noise)
{
   float2 xy = saturate (uv0 - float2 (0.5, 0.5));

   float seed   = frac ((dot (uv0.xy, float2 (uv0.x + 123.0, uv0.y + 13.0))) * 0.5 + _Progress);
   float rndval = frac (sin (dot (xy, float2 (12.9898, 78.233)) + xy.x + xy.y + seed) * (43758.5453));

   rndval = sin (xy.x) + cos (xy.y) + (rndval * 1000.0);

   return saturate (frac (fmod (rndval, 17.0) * fmod (rndval, 94.0)) * 3.0).xxxx;
}

DeclarePass (Xblur)
{
   float2 xy0 = float2 (GrainBlur, 0.0) * B_SCALE;
   float2 xy1 = uv1 + xy0;
   float2 xy2 = uv1 - xy0;

   float4 retval = tex2D (Noise, uv1) * _pascal [0];

   retval += tex2D (Noise, xy1) * _pascal [1];
   retval += tex2D (Noise, xy2) * _pascal [1];
   xy1 += xy0; xy2 -= xy0;
   retval += tex2D (Noise, xy1) * _pascal [2];
   retval += tex2D (Noise, xy2) * _pascal [2];
   xy1 += xy0; xy2 -= xy0;
   retval += tex2D (Noise, xy1) * _pascal [3];
   retval += tex2D (Noise, xy2) * _pascal [3];

   return retval;
}

DeclarePass (Grain)
{
   float2 xy0 = float2 (0.0, GrainBlur) * B_SCALE * _OutputAspectRatio;
   float2 xy1 = uv1 + xy0;
   float2 xy2 = uv1 - xy0;

   float4 retval = tex2D (Xblur, uv1) * _pascal [0];

   retval += tex2D (Xblur, xy1) * _pascal [1];
   retval += tex2D (Xblur, xy2) * _pascal [1];
   xy1 += xy0; xy2 -= xy0;
   retval += tex2D (Xblur, xy1) * _pascal [2];
   retval += tex2D (Xblur, xy2) * _pascal [2];
   xy1 += xy0; xy2 -= xy0;
   retval += tex2D (Xblur, xy1) * _pascal [3];
   retval += tex2D (Xblur, xy2) * _pascal [3];

   return retval;
}

DeclarePass (Blemishes)
{
   float4 retval = ReadPixel (Input, uv1);
   float4 grain  = ReadPixel (Grain, ((uv1 - 0.5.xx) / ((GrainSize * 9.0) + 1.0)) + 0.5.xx);

   grain  += retval * 3.0;
   grain  /= 4.0;
   grain.a = retval.a;

   retval = lerp (retval, grain, GrainAmount);

   retval.rgb *= 0.75;
   retval.rgb  = pow (retval.rgb, 2.0);

   float z = lerp (0.1,  0.9,  _Progress);

   float2 xy = float2 (frac (uv1.x + z), 0.001 * z);

   float scratches = 0.0375;
   float scratch   = 1.0 - ReadPixel (Noise, xy).x;

   scratch = 2.0 * scratch / scratches;
   scratch = 1.0 - abs (1.0 - scratch);

   if (scratch > lerp (1.0 , 0.75, PosScratches)) retval = ((1.0 - scratch) * 0.5).xxxx;

   z  = lerp (0.85, 0.05, _Progress);
   xy = float2 (frac (uv1.x + z), 0.001 * z);

   scratches = 0.0015;
   scratch   = 1.0 - ReadPixel (Noise, xy).x;

   scratch = 2.0 * scratch / scratches;
   scratch = 1.0 - abs (1.0 - scratch);

   if (scratch > lerp (1.0 , 0.75, NegScratches)) retval = (scratch * 0.75).xxxx;

   return retval;
}

DeclareEntryPoint (SilentMovie)
{
   float2 xy = uv1;

   if ((JitterRate > 0.0) && (JitterAmount > 0.0)) {
      float3 xyz = float3 (0.0.xx, frac (_Length * _Progress / 13.0) * JitterRate * 104.0) + 200.0.xxx;

      float c, s, angle = radians (weave (xyz - 10.0.xxx)) * JitterAmount * 3.0;

      xy -= 0.5.xx;
      xy += float2 (weave (xyz), weave (xyz + 10.0.xxx)) * JitterAmount / 30.0;

      sincos (angle, s, c);

      xy = mul (float2x2 (c, s, -s, c), xy) + 0.5.xx;
   }

   float4 retval = IsOutOfBounds (uv1) ? _TransparentBlack : ReadPixel (Blemishes, mirrorXY (xy));

   float alpha   = retval.a;

   float2 fl = lerp (0.1, 0.9, _Progress).xx;

   float flicker = Flicker * (ReadPixel (Noise, fl).x - 0.5);
   float gamma   = pow ((Exposure / 2.0) + flicker + 1.85, 1.5);

   retval.rgb  = lerp (1.0.xxx, SEPIA, SepiaTone * 1.5) * dot (retval.rgb, LUMA).xxx * gamma;
   retval.rgb *= 1.0 - (flicker * 0.35);
   retval.rgb += (flicker * 0.1).xxx;

   float vibrance = 1.5 * (((retval.r + retval.g + retval.b) / 3.0) - retval.g);

   retval.rgb = saturate (lerp (retval.rgb, retval.ggg, vibrance));

   float4 edges = float4 (lerp (retval, pow (retval, 4.0) * 0.75, sqrt (LampFalloff)).rgb, retval.a);

   float radius  = 0.5;
   float midSoft = FalloffEdge / 2.0;

   float2 vignette = (uv1 - 0.5.xx) / FalloffSize;

   vignette.y /= _OutputAspectRatio;
   vignette   += 0.5.xx;

   float dist = distance (vignette, 0.5.xx);

   if (dist > (radius + midSoft)) { retval = edges; }
   else if (dist >= (radius - midSoft)) {
      retval = lerp (retval, edges, (dist - (radius - midSoft)) / FalloffEdge);
   }

   return retval;
}
