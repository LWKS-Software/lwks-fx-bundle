// @Maintainer jwrl
// @Released 2025-02-12
// @Author jwrl
// @Created 2025-02-12

/**
 I don't know how this effect started life, because it just turned up and I have no
 recollection of having created it.  If anyone here posted it I would really like to
 credit you.

 It's a moving starfield over a deep blue gradient background.  Here are the settings.

   [*] Offset:  Offsets the star field start pattern.
   [*] Speed:  Adjusts the travel speed through the star field.
   [*] Intensity:  Increases the star intensity by brightening centre.
   [*] Origin X:  Adjusts the horizontal centre point of the star field origin.
   [*] Origin Y:  Adjusts the vertical centre point of the star field origin.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Starfield.fx
//
// Created 2025-02-12 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Starfield", "Mattes", "Backgrounds", "Cascading stars", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Offset,    "Offset",    kNoGroup, kNoFlags, 0.0,   0.0, 1.0);
DeclareFloatParam (Speed,     "Speed",     kNoGroup, kNoFlags, 0.125, 0.0, 1.0);
DeclareFloatParam (Intensity, "Intensity", kNoGroup, kNoFlags, 0.5,   0.0, 1.0);

DeclareFloatParam (CentreX, "Origin", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Origin", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (_Progress);
DeclareFloatParam (_Length);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define COL_1 float4(0.0, 0.05, 0.125, 1.0)
#define COL_2 float4(0.0, 0.0, 0.1, 1.0)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float stars (float2 uv, float flares)
{
   float l  = length (uv);
   float ss = 0.05 / l;
   float s, c;

   // Generate the rays

   ss += max (0.0, 1.0 - abs (uv.x * uv.y * 987.6)) * flares;

   // Now rotate the uv coordinates

   sincos (0.7853981634, s, c);
   uv = mul (float2x2 (c, -s, s, c), uv);

   ss += max (0.0, 1.0 - abs (uv.x * uv.y * 876.5)) * 0.4 * flares;

   return ss * smoothstep (1.0, 0.2, l);
}

float3 star_field (float2 uv, float t)
{
   float2 xy1 = frac (uv) - 0.5.xx;
   float2 xy2 = floor (uv);

   float3 retval = 0.0.xxx;

   for (int y = -1; y <= 1; y++) {

      for (int x = -1; x <= 1; x++) {
         float2 xy3 = float2 (x, y);
         float2 xy4 = xy2 + xy3;

         xy4  = frac (xy4 * float2 (109.28, 357.24));
         xy4 += dot (xy4, xy4 + 68.13.xx).xx;

         float a = frac (xy4.x * xy4.y);
         float b = frac (a * 12.3);
         float z = frac (a * 456.78);

         xy4 = float2 (a, b);

         float s = stars (xy1 - xy3 - xy4 + 0.5.xx, smoothstep (0.9, 1.0, z) * 0.6);

         b = frac (a * 412.124);

         float3 colour = (sin (float3 (0.2, 0.3, 0.9) * b * 123.2) * 0.5) + 0.5;

         colour *= float3 (0.8, 0.025, 1.0 + z);

         s *= (sin ((t * 3.0) + (a * 6.283)) * 0.5) + 1.0;

         retval += s * z * colour * 0.75;
      }
   }

   float bright = pow (max (retval.r, max (retval.g, retval.b)), 2.0);

   bright = saturate (bright * Intensity);

   return lerp (retval, 1.0.xxx, bright);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Starfield)
{
   // Normalized pixel coordinates (default from -0.5 to 0.5)

   float2 uv = float2 ((uv1.x * _OutputAspectRatio) - CentreX, 1.0 - uv1.y - CentreY);

   // Parameters for adjusting quality of simulation with performance on GPU.

   float time = (_Progress + (Offset * 10.0)) * _Length * Speed * 8.0;
   float t_1  = time * 0.05;

   float3 col = 0.0.xxx;

   for (float i = 0.0; i < 1.0; i += 0.5) {
      float depth = frac (i + t_1);
      float scale = lerp (20.0, 0.5, depth);
      float fade = depth * smoothstep (1.0, 0.9, depth);

      col += star_field (uv * scale + i * 453.2, time) * fade;
   }

   float gradient = abs (uv1.y - 0.5) * 2.0;

   float4 Input = ReadPixel (Inp, uv1);
   float4 Fgnd  = float4 (col, 1.0);
   float4 Bgnd  = lerp (COL_1, COL_2, gradient);

   Fgnd.rgb = min (Fgnd.rgb + Bgnd.rgb, 1.0.xxx);     // Add

   return lerp (Input, Fgnd, tex2D (Mask, uv1).x);
}

