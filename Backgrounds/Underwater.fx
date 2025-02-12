// @Maintainer jwrl
// @Released 2025-02-12
// @Author jwrl
// @Created 2025-02-12

/**
 This mimics an underwater "god rays" lighting efect, with depth simulation, plus
 sun intensity and position adjustment.  Surface ripples control the god rays, and
 their speed can be adjusted from turgidly slow to waterfall-style brisk.

 The settings are:

   [*] Sun position:  Adjusts the horizontal simulated sun position.
   [*] Sun intensity:  Adjusts the intensity of the simulated sunlight.
   [*] Ripple speed:  Changes the speed at which the god rays move.
   [*] Depth:  Changing depth adjusts the angle of the god rays.  It
       interacts with the sun intensity, the deeper it's set the less
       light there is.
   [*] Water colour:  Self explanatory.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Underwater.fx
//
// Version history:
//
// Created 2025-02-12 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Underwater", "Mattes", "Backgrounds", "Generates underwater-style god rays", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (SunPos, "Sun position", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (SunGain, "Sun intensity", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Ripples, "Ripple speed", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Depth, "Depth", kNoGroup, kNoFlags, 0.75, 0.0, 1.0);

DeclareColourParam (Colour, "Water colour", kNoGroup, kNoFlags, 0.078, 0.424, 0.6, 1.0);

DeclareFloatParam (_Progress);
DeclareFloatParam (_Length);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Underwater)
{
   float s = (uv1.x - 0.5) * 0.375;                             // Sun position
   float d = (1.0 - uv1.y) * 0.4;                               // Depth scale factor
   float f = (0.5 - uv1.y) / (4.5 - (Depth * 3.5));             // Falloff scale
   float r = _Progress * _Length * pow ((Ripples + 0.75), 4.0); // Ripple speed

   s = (s * (1.5 - (Depth * 0.5))) - ((SunPos - 0.5) * d) * 0.5;
   d = (d * Depth * 2.0) + f;

   // Generate the ray pattern, p.

   float2 xy1 = float2 (s, d);

   s *= (1.0 + (d * 0.6)) * (1.0 + (sin (r / 2.0) / 10.0));

   float p = (sin (s * 40.0 + r) + sin (-s * 130.0 + r) +
             pow (sin (s * 30.0 + r), 2.0) + pow (sin (s * 50.0 + r), 2.0) +
             pow (sin (s * 80.0 + r), 2.0) + pow (sin (s * 90.0 + r), 2.0) +
             pow (sin (s * 12.0 + r), 2.0) + pow (sin (s * 6.0 + r), 2.0) +
             pow (sin (-s * 13.0 + r), 5.0)) / 2.0;

   p *= saturate (7.0 - length (s * 20.0)) * (d + 0.5) / 4.0;
   p++;
   p *= length (xy1 + float2 (-0.5, 0.5)) * length (xy1 + 0.5.xx);
   p *= SunGain + 0.25;

   float4 retval = float4 (Colour.rgb * p, Colour.a);
   float4 Bgnd   = ReadPixel (Inp, uv1);

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}

