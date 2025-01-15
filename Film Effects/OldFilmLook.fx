// @Maintainer jwrl
// @Released 2025-01-15
// @Author khaver
// @Author saabi
// @Created 2018-03-31

/**
 This effect simulates a black and white film with scratches, sprocket holes, weave and
 flicker.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect OldFilmLook.fx
//
//-----------------------------------------------------------------------------------------//
// Original Shadertoy author:
// saabi (2018-03-31) https://www.shadertoy.com/view/4dVcRy
//
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//-----------------------------------------------------------------------------------------//
// OldFilmLookFx.fx for Lightworks was adapted by user khaver 20 June 2018 from original
// code by the above author taken from the Shadertoy website:
// https://www.shadertoy.com/view/4dVcRy
//
// This adaptation retains the same Creative Commons license shown above.  It cannot be
// used for commercial purposes.
//
// NOTE:  Code comments are from the original author(s) except where identified as
// otherwise.
//
// NOTE 2: The creation date (above) is the shadertoy release date, with khaver's
// conversion to the Windows-only LW version shown in the history (below).  Since
// that version was the absolute original Lightworks effect, khaver is credited
// along with saabi as the effect's creators, while my input is purely maintenance.
// It's just a conversion to the format used by LW 2023.1 and higher - jwrl.
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Adapted jwrl 2025-01-15.
// Converted khaver's original Windows version to the shader code format required by
// current Lightworks effects.
//
// Converted from the shadertoy code by khaver 2018-06-20.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Old film look", "Stylize", "Film Effects", "Simulates a black and white film with scratches, sprocket holes, weave and flicker.", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (scale, "Frame Zoom", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (sprockets, "Size",            "Sprockets", kNoFlags, 6.72, 0.0, 20.0);
DeclareFloatParam (sprocket2, "Alignment",       "Sprockets", kNoFlags, 3.19, 0.0, 10.0);
DeclareBoolParam  (sprocket3, "Double Quantity", "Sprockets", false);

DeclareFloatParam (gstrength,     "Grain Strength", "Flaws", kNoFlags, 1.0, 0.0, 2.0);
DeclareFloatParam (ScratchAmount, "Scratch Amount", "Flaws", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (NoiseAmount,   "Dirt Amount",    "Flaws", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (smallJitterProbability, "Minor",      "Jitter", kNoFlags, 0.5,  0.0, 1.0);
DeclareFloatParam (largeJitterProbability, "Major",      "Jitter", kNoFlags, 0.05, 0.0, 1.0);
DeclareFloatParam (angleProbability,       "Rotational", "Jitter", kNoFlags, 0.15, 0.0, 1.0);

DeclareFloatParam (flicker, "Flicker Strength", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Progress);
DeclareFloatParam (_Length);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float hash (float n)
{ return frac (cos (n * 89.42) * 343.42); }

float2 hash2 (float2 n)
{ return float2 (hash (n.x * 23.62 - 300.0 + n.y * 34.35), hash (n.x * 45.13 + 256.0 + n.y * 38.89)); }

float worley (float2 c, float time)
{
   float dis = 1.0;

   for (int x = -1; x <= 1; x++)
      for (int y = -1; y <= 1; y++) {
         float2 p = floor (c) + float2 (x, y);
         float2 a = hash2 (p) * time;
         float2 rnd = (sin (a) * 0.5) + 0.5;

         float d = length (rnd + float2 (x, y) - frac (c));

         dis = min (dis, d);
      }

   return dis;
}

float worley2 (float2 c, float time)
// This was originally implemented as a 2 pass loop.  It has been changed to be
// two lines of code, making it much simpler and improving execution time - jwrl.
{
   float w = worley (c, time) * 0.5;

   return w + (worley (c + c, time + time) * 0.25);
}

float worley5 (float2 c, float time)
{
   float w = 0.0;
   float a = 0.5;

   for (int i = 0; i < 5; i++) {
      w += worley (c, time) * a;
      c += c;
      time += time;
      a *= 0.5;
   }

   return w;
}

float rand (float2 co)
{ return frac (sin (dot (co.xy, float2 (12.9898, 78.233))) * 43758.5453); }

// This function was only ever passed a seed value of 0.01,  That has now been removed
// and hard-wired into the code - jwrl;

float2 jitter (float2 uv, float2 s)
// Some slight code cleanup was done here to improve readability - jwrl.
{
   float t = _Length * _Progress * 0.0101;

   // Although rand() is passed a float2 it only returns a float.  For that reason
   // two calls of rand() are required to obtain the float2 result - jwrl.

   float2 r = float2 (rand (float2 (t, 0.01)), rand (float2 (t, 0.12)));

   return (r - 0.5.xx) * s;
}

float2 rot (float2 coord, float a)
// sin_factor and cos_factor were originally separately calculated.  They are now obtained
// using sincos().  The aspect scaling is also precalculated instead of being multiplied
// each time that it's required - jwrl.
{
   float aspect = _OutputAspectRatio * 2.0;
   float sin_factor, cos_factor;

   sincos (a, sin_factor, cos_factor);

   coord.x *= aspect;
   coord    = mul (coord, float2x2 (cos_factor, -sin_factor, sin_factor, cos_factor));
   coord.x /= aspect;

   return coord;
}

float4 vignette (float2 uv, float strength)
{ return float4 ((1.0 - (pow (length (uv), 2.25) * strength)).xxx, 0.0); }

float4 frame (sampler Inp, float2 uv, float fn)
// Substantially restructured to improve efficency - jwrl.
{
   if (abs (uv.x) > 0.5 || abs (uv.y) > 0.5) return float4 (0.006, 0.0054, 0.0, 1.0);

   float time     = _Length * _Progress;
   float strength = gstrength * 64.0;
   float x        = (uv.x + 4.0) * (uv.y + 4.0) * (time + 10.0);
   float grain    = (fmod ((fmod(x, 13.0) + 1.0) * (fmod (x, 123.0) + 1.0), 0.01) - 0.005) * strength;
   float fnn      = fmod ((floor ((fn + 0.5) / 1.2) + time) / 20.0, 1.0);
   float fj       = rand (float2 (fnn, 5.34)) * 2.0;

   float4 i  = tex2D (Inp, uv + 0.5.xx);
   float4 ic = float4 (i.rgb * lerp (1.0, fj, flicker), 1.0) * vignette (uv * 2.5, 0.25);

   uv *= float2 ((time * 0.10) + 100.0, 100.0);

   float bw           = dot (ic.rgb, float3 (0.15, 0.8, 0.05));
   float dis          = worley5 (uv / 64.0, time * 50.0);
   float noiseTrigger = rand (float2 (time * 8.543, 2.658));
   float spots        = noiseTrigger < NoiseAmount ? saturate (lerp (-1.0, 10.0, dis)) : 1.0;

   return float4 ((float3 (1.345, 1.2, 0.934) * bw * spots * (1.0 - grain)), 1.0);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Film)
{
   // Normalized pixel coordinates (from 0 to 1)

   float2 uv = uv1 - 0.5.xx;

   uv *= float2 (1.0, _OutputAspectRatio);
   uv /= (scale * 1.05) + 0.75;
   uv += float2 (0.5, 1.195);

   // Output to screen.  Originally this exited through the function final() here.  What
   // follows is a restructured version of the function, implemented as inline code - jwrl.

   float time  = _Length * _Progress;
   float time1 = time * 0.0101;

   float smallJitterTrigger = rand (float2 (time1, 0.125));
   float largeJitterTrigger = rand (float2 (time1, 0.122));

   float2 juv = float2 (uv.x - 0.5, uv.y);

   if (smallJitterTrigger <= smallJitterProbability) juv += jitter (uv, float2 (0.003, 0.003));
   if (largeJitterTrigger <= largeJitterProbability) juv += jitter (uv, float2 (0.03,  0.03));

   if (angleProbability > rand (float2 (time1, 0.123)))
      juv = rot (juv, (rand (float2 (time1, 0.14)) - 0.5) * 0.0349);

   float2 fuv = float2 (juv.x * _OutputAspectRatio, (fmod (juv.y + 1.705, 1.2) - 0.5));

   float4 flm, frm = frame (Input, fuv, juv.y);

   // Here final() exited through the function film().  This is now the inline code below - jwrl.

   float2 suv = float2 (fuv.x, juv.y + 100.0);

   float ax   = abs (fuv.x);
   float ay   = juv.y + 100.0;
   float sprc = sprocket3 ? 2.0 : 4.0;

   if (ax > 0.7 || (ax > 0.56 && ax < 0.64 && fmod (floor ((ay + sprocket2) * sprockets), sprc) == 1.0)) {
      flm = 1.0.xxxx;
   }
   else {
      float disw = worley2 (float2 (fuv.x * 12.1957, ay * 0.0305), floor (time * 10.389) * 50.124);
      float cw   = lerp (1.0, -30.6, disw);
      float scratchTrigger = rand (float2 (time * 2.543, 0.823));

      cw = scratchTrigger < ScratchAmount ? saturate (1.0 - (cw * cw)) * 2.0 : 0.0;

      flm = float4 (cw.xxx, cw < 1.0 ? 0.0 : 1.0);
   }

   return flm.a == 1.0 ? frm + flm : float4 (frm.rgb - (flm.rgb * 2.0), 1.0);
}

DeclareEntryPoint (OldFilmLook)
{
   float4 c = ReadPixel (Film, uv2);

   float i;

   for (i = 0.25; i < 2.0; i += 0.25) {
      c += tex2D (Film, uv2 + float2 (0.0, i / _OutputHeight));
      c += tex2D (Film, uv2 - float2 (0.0, i / _OutputHeight));
      c += tex2D (Film, uv2 + float2 (i / _OutputWidth, 0.0));
      c += tex2D (Film, uv2 - float2 (i / _OutputWidth, 0.0));
   }

   float4 fragColor = (c / 29.0) * vignette (uv2 - 0.5, 2.0);

   return IsOutOfBounds (uv2) ? 0.0.xxxx : float4 (fragColor.rgb, 1.0);
}
