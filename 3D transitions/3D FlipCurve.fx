// @Maintenance jwrl
// @Released 2026-09-20
// @Author hugly
// @Created 2026-09-12

/**
 This effect rotates the outgoing video around the centre of frame by default, then
 rotates the incoming video in from the same point.  The pivot point around which the
 rotation takes place is adjustable and curvature can be applied as the rotation takes
 place.  The images can reflect on a simulated floor and can be raised or lowered so
 that the reflection is closer to or further away from the floor.

   [*]Amount:  The progress of the transition.
   [*]Reflection:  Controls the intensity of the reflection.
   [*]Perspective:  Adjusts the 3D rotation (perspective distortion) of the video
      sources during the transition.
   [*]Pivot point X:  Adjusts the rotation pivot point horizontally.
   [*]Curve:  Switches the curvature on or off.
   [*]Float:  Adjusts the distance that the video sources move during the transition.
   [*]Smooth edges:  Smooth the horizontal edges of the cube to minimise jaggies.

 Antialiassing is provided using the "Smooth edges" parameter, which smooths just the
 horizontal edges during rotation.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 3DFlipCurve.fx
//
//-----------------------------------------------------------------------------------------//
// 3DFlipCurve.fx
// Standalone 3D Perspective Spinning Double-Sided TV Panel Transition
// Built on Native Multi-Pass Wipe Framework Layer (Windows, macOS, Linux)
//-----------------------------------------------------------------------------------------//
//
// Version history.
//
// Code cleanup 2026-09-20 jwrl.
//
// AI conversion by hugly 2026-09-12
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("3D Flip with curve", "Mix", "3D transitions", "Simulates a single double-sided TV panel spinning and scaling over a reflective floor.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (amount, "Amount",      kNoGroup, kNoFlags, 0.5,  0.0, 1.0);

DeclareFloatParam (reflection,   "Reflection",    kNoGroup, kNoFlags, 0.4,  0.0, 1.0);
DeclareFloatParam (perspective,  "Perspective",   kNoGroup, kNoFlags, 0.5,  0.0, 1.0);
DeclareFloatParam (pivotX,       "Pivot point X", kNoGroup, kNoFlags, 0.5,  0.25, 0.75);
DeclareBoolParam  (curve_switch, "Curve",         kNoGroup, true);
DeclareFloatParam (floating,     "Float",         kNoGroup, kNoFlags, 3.0,  1.0, 10.0);
DeclareFloatParam (smoothness,   "Smooth edges",  kNoGroup, kNoFlags, 0.15, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Declarations and definitions
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define flip(v) float2(v.x, 1.0 - v.y)

#define PI 3.14159265359

float4 black = float4 (0.0.xxx, 1.0);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float aaFactorSelective (float2 p, float width) 
{
   float edgeY, edgeX = (p.x >= 0.0 && p.x <= 1.0) ? 1.0 : 0.0;

   if (width <= 0.00001) { edgeY = (p.y >= 0.0 && p.y <= 1.0) ? 1.0 : 0.0; }
   else {
      edgeY  = smoothstep (0.0, width, p.y);
      edgeY *= smoothstep (1.0, 1.0 - width, p.y);
   }

   return edgeX * edgeY;
}

bool IsInBounds (float2 p) 
{
   float2 delta = saturate (p) - p;

   return bool (abs (delta.x + delta.y) < 0.000000001);
}

// Adapted directly from the original working template
float2 project (float2 p) 
{
   return p * float2 (1.0, -1.2) + float2 (0.0, -floating / 100.0);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// Outgoing source video

DeclarePass (Fgd)
{ return ReadPixel (Fg, flip (uv1)); }

// Incoming source video

DeclarePass (Bgd)
{ return ReadPixel (Bg, flip (uv2)); }

DeclareEntryPoint (FlipCurve3D)
{
   float2 uv       = flip (uv3);   
   float2 fromP    = -1.0.xx;
   float2 reflectP = -1.0.xx;

   float sinA, cosA, angle = amount * PI;

   // Dynamic Midpoint Depth Scaling Function

   float targetScale = (amount <= 0.5) ? lerp (1.0, 0.5, smoothstep (0.0, 0.5, amount)) 
                                       : lerp (0.5, 1.0, smoothstep (0.5, 1.0, amount));
   sincos (angle, sinA, cosA);

   // CORRECTED: Linearly guide the pivot from the custom value to exactly 0.5 at the end

   float currentPivotX = lerp (pivotX, 0.5, amount);

   // 1. Core TV Panel Surface Perspective Mapping with Linear Pivot Tracking

   float2 normUV = uv - float2 (currentPivotX, 0.5);
   normUV /= targetScale;

   // Fix perspective mapping curves by applying division-based reverse mapping coordinate adjustment

   if (curve_switch) {
      float panelDepth = 1.0 + (normUV.x * sinA * perspective);
      fromP.x = (normUV.x / cosA) + currentPivotX;
      fromP.y = (normUV.y * panelDepth) + 0.5;
   }
   else {
      float denom = cosA - (normUV.x * sinA * perspective * 2.0);
      fromP.x = (normUV.x / denom) + currentPivotX;
      fromP.y = (normUV.y / (denom / cosA)) + 0.5;
   }

   if (amount > 0.5) fromP.x = 1.0 - fromP.x;

   // 2. Adaptive Template Reflection Tracking

   reflectP = project (fromP);

   // Edge Anti-Aliasing Setup

   float internalWidth = smoothness * 0.02;
   float visibilityFrom = aaFactorSelective (fromP, internalWidth);

   // Background Environment Setup (Clean dark room void)

   float4 outputColor = float4 (0.0.xxx, 1.0);

   // Fade out smoothly as the reflection stretches out across the floor plane

   float fade = lerp (1.0, 0.0, saturate (reflectP.y));

   // Process and overlay the template-adapted floor reflections

   if (IsInBounds (reflectP)) {
      outputColor += (amount <= 0.5) ? lerp (black, tex2D (Fgd, reflectP), reflection * fade)
                                     : lerp (black, tex2D (Bgd, reflectP), reflection * fade);
   }

   // Overlay the solid spinning 3D TV panel directly on top

   if (IsInBounds (fromP)) {
      outputColor = (amount <= 0.5) ? lerp (outputColor, tex2D (Fgd, fromP), visibilityFrom)
                                    : lerp (outputColor, tex2D (Bgd, fromP), visibilityFrom);
   }
   
   return outputColor;
}

