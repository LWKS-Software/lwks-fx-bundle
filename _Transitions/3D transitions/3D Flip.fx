// @Maintenance jwrl
// @Released 2026-09-27
// @Author hugly
// @Created 2026-09-12

/**
 This effect rotates the outgoing video around the centre of frame by default, then
 rotates the incoming video in from the same point.  The pivot point around which the
 rotation takes place is adjustable and curvature can be applied as the rotation takes
 place.  The images can reflect on a simulated floor and can be raised or lowered so
 that the reflection is closer to or further away from the floor.

   [*]Amount:  The progress of the transition.
   [*]Perspective:  Adjusts the 3D rotation (perspective distortion) of the video
      sources during the transition.
   [*]Pivot point X:  Adjusts the rotation pivot point horizontally.
   [*]Geometry:  Switches the geometry between linear and curved.
   [*]Reflection:  Controls the intensity of the reflection.
   [*]Float: Adjusts the distance of the refelction.
   [*]Feather: Smooth the horizontal edges of the cube to minimise jaggies.

 Antialiassing is provided using the "Smooth edges" parameter, which smooths just the
 horizontal edges during rotation.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 3DFlip.fx
//
//-----------------------------------------------------------------------------------------//
// Standalone 3D Perspective Spinning Double-Sided TV Panel Transition
// Built on Native Multi-Pass Wipe Framework Layer (Windows, macOS, Linux)
//-----------------------------------------------------------------------------------------//
//
// Version history.
//
// Modified 26-09-25 hugly
// Changed effect name to 3DFlip
// Changed Pivot point X to display percent
// Moved "Geometry" up and renamed it to "Transition type" to match the panel layout of 3D Doorway.fx
//
// Modified hugly and jwrl 26-09-25.
// Fixed invisible bug that meant that only SetTechnique == 1 code would execute.
//
// Modified jwrl 26-09-24.
// Split shader to allow for separate execution of linear and curved geometry.
//
// Modified hugly 26-09-21.
// Changed the names to 3D Flip and 3DFlip.fx
// Changed order of the parameters to be similar to others of the family.
// Changed the description of "Float".
// Renamed "Smooth edges" to "Feather".
//
// Code cleanup 2026-09-20 jwrl.
//
// AI conversion by hugly 2026-09-12
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("3D Flip", "Mix", "3D transitions", "Simulates a single double-sided TV panel spinning and scaling over a reflective floor.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (amount, "Amount",          kNoGroup, kNoFlags, 0.5,  0.0, 1.0);
DeclareIntParam   (SetTechnique,   "Transition type", kNoGroup, 0, "Curved|Linear");
DeclareFloatParam (perspective,    "Perspective",     kNoGroup, kNoFlags, 0.5,  0.0, 1.0);
DeclareFloatParam (pivotX,         "Pivot point",     kNoGroup, "DisplayAsPercentage", 0.5,  0.25, 0.75);
DeclareFloatParam (reflection,     "Reflection",      kNoGroup, kNoFlags, 0.4,  0.0, 1.0);
DeclareFloatParam (floating,       "Float",           kNoGroup, "DisplayAsPercentage", 0.3,  0.1, 1.0);
DeclareFloatParam (smoothness,     "Feather",         kNoGroup, kNoFlags, 0.15, 0.0, 1.0);

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
   return p * float2 (1.0, -1.2) + float2 (0.0, -floating / 10.0);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// Transition type curved

DeclarePass (Fg0)
{ return ReadPixel (Fg, flip (uv1)); }

// Incoming source video

DeclarePass (Bg0)
{ return ReadPixel (Bg, flip (uv2)); }

DeclareEntryPoint (FlipCurved)
{
   float2 uv = flip (uv3);
   float2 fromP;

   float sinA, cosA, angle = amount * PI;

   // Dynamic midpoint depth scaling function

   float targetScale = (amount <= 0.5) ? lerp (1.0, 0.5, smoothstep (0.0, 0.5, amount))
                                       : lerp (0.5, 1.0, smoothstep (0.5, 1.0, amount));
   sincos (angle, sinA, cosA);

   // CORRECTED: Linearly guide the pivot from the custom value to exactly 0,5 at the end

   float currentPivotX = lerp (pivotX, 0.5, amount);

   // 1. Core TV panel surface perspective mapping with linear pivot tracking

   float2 normUV = uv - float2 (currentPivotX, 0.5);

   normUV /= targetScale;

   float panelDepth = 1.0 + (normUV.x * sinA * perspective);

   fromP.x = (normUV.x / cosA) + currentPivotX;
   fromP.y = (normUV.y * panelDepth) + 0.5;

   if (amount > 0.5) fromP.x = 1.0 - fromP.x;

   // 2. Adaptive template reflection tracking

   float2 reflectP = project (fromP);

   // Edge anti-aliasing setup

   float internalWidth  = smoothness * 0.02;
   float visibilityFrom = aaFactorSelective (fromP, internalWidth);

   // Background environment setup (clean dark room void)

   float4 outputColor = black;

   // Fade out smoothly as the reflection stretches out across the floor plane

   float fade = lerp (1.0, 0.0, saturate (reflectP.y));

   if (IsInBounds (reflectP)) {
      outputColor += amount <= 0.5 ? lerp (black, tex2D (Fg0, reflectP), reflection * fade)
                                   : lerp (black, tex2D (Bg0, reflectP), reflection * fade);
   }

   // Overlay the solid spinning 3D TV panel directly on top

   if (IsInBounds (fromP)) {
      outputColor = amount <= 0.5 ? lerp (outputColor, tex2D (Fg0, fromP), visibilityFrom)
                                  : lerp (outputColor, tex2D (Bg0, fromP), visibilityFrom);
   }

   return outputColor;
}

//-----------------------------------------------------------------------------------------//

// Transition type linear

DeclarePass (Fg1)
{ return ReadPixel (Fg, flip (uv1)); }

// Incoming source video

DeclarePass (Bg1)
{ return ReadPixel (Bg, flip (uv2)); }

DeclareEntryPoint (FlipLinear)
{
   float2 uv = flip (uv3);
   float2 fromP;

   float sinA, cosA, angle = amount * PI;

   // Dynamic midpoint depth scaling function

   float targetScale = (amount <= 0.5) ? lerp (1.0, 0.5, smoothstep (0.0, 0.5, amount))
                                       : lerp (0.5, 1.0, smoothstep (0.5, 1.0, amount));
   sincos (angle, sinA, cosA);

   // CORRECTED: Linearly guide the pivot from the custom value to exactly 0,5 at the end

   float currentPivotX = lerp (pivotX, 0.5, amount);

   // 1. Core TV panel surface perspective mapping with linear pivot tracking

   float2 normUV = uv - float2 (currentPivotX, 0.5);

   normUV /= targetScale;

   float denom = cosA - (normUV.x * sinA * perspective * 2.0);

   fromP.x = (normUV.x / denom) + currentPivotX;
   fromP.y = (normUV.y / (denom / cosA)) + 0.5;

   if (amount > 0.5) fromP.x = 1.0 - fromP.x;

   // 2. Adaptive template reflection tracking

   float2 reflectP = project (fromP);

   // Edge anti-aliasing setup

   float internalWidth  = smoothness * 0.02;
   float visibilityFrom = aaFactorSelective (fromP, internalWidth);

   // Background environment setup (clean dark room void)

   float4 outputColor = black;

   // Fade out smoothly as the reflection stretches out across the floor plane

   float fade = lerp (1.0, 0.0, saturate (reflectP.y));

   if (IsInBounds (reflectP)) {
      outputColor += amount <= 0.5 ? lerp (black, tex2D (Fg1, reflectP), reflection * fade)
                                   : lerp (black, tex2D (Bg1, reflectP), reflection * fade);
   }

   // Overlay the solid spinning 3D TV panel directly on top

   if (IsInBounds (fromP)) {
      outputColor = amount <= 0.5 ? lerp (outputColor, tex2D (Fg1, fromP), visibilityFrom)
                                  : lerp (outputColor, tex2D (Bg1, fromP), visibilityFrom);
   }

   return outputColor;
}
