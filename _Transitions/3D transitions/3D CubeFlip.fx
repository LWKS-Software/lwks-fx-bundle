// @Maintenance jwrl
// @Released 2026-09-20
// @Author gre
// @Author hugly
// @Created 2026-09-12

/**
 This transitions between the outgoing and incoming video sources using the classic
 rotating cube effect.  The amount of perspective distortion is adjustable from zero
 to an extremely wdie angle effect.  The distance to the cube at effect midpoint is
 also adjustable.

   [*]Amount:  The progress of the transition.
   [*]Perspective:  Changes the cube's perspective.
   [*]Zoom amount:  The distance from the cube at halfway through the transition.
   [*]Reflection
      [*]Strength:  Sets the intensity of the reflection.
      [*]Float:  Floats the cube rotation over its reflection.
   [*]Smooth edges:  Smooth the horizontal edges of the cube to minimise jaggies.

 Antialiassing is provided by the "Smooth edges" parameter, which smooths just the
 horizontal edges during rotation.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 3D CubeFlip.fx
//
//-----------------------------------------------------------------------------------------//
// 3D CubeFlip.fx ported from GL-Transitions
// original author: gre
// License: MIT
// Optimized Framework Translation with Scaled Horizontal Edge Anti-Aliasing
//-----------------------------------------------------------------------------------------//
//
// Version history.
//
// Code cleanup 2026-09-20 jwrl.
//
// AI conversion by hugly 2026-09-12
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("3D Cube flip", "Mix", "3D transitions", "AI Optimized Transition - Sharp verticals with scaled anti-aliased horizontal edges", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (amount, "Amount",   kNoGroup,     kNoFlags, 0.5,  0.0, 1.0);
DeclareFloatParam (persp,      "Perspective",  kNoGroup,     kNoFlags, 0.7,  0.0, 1.0);
DeclareFloatParam (unzoom,     "Zoom amount",  kNoGroup,     kNoFlags, 0.3,  0.0, 1.0);

DeclareFloatParam (reflection, "Strength",     "Reflection", kNoFlags, 0.4,  0.0, 1.0);
DeclareFloatParam (floating,   "Float",        "Reflection", "DisplayAsPercentage", 0.3,  0.1, 1.0);

// Mapped smoothness UI value: 0.15 * 0.020 max width = 0.003 internal default sweet-spot

DeclareFloatParam (smoothness, "Smooth edges", kNoGroup,     kNoFlags, 0.15, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Declarations and definitions
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define flip(v) float2(v.x, 1.0 - v.y)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float aaFactorSelective (float2 p, float width) 
{
   // Sharp binary clipping for the vertical sides (Left/Right)

   float edgeX = (p.x >= 0.0 && p.x <= 1.0) ? 1.0 : 0.0;

   // Guard against division-by-zero if user sets slider to exactly 0.0

   if (width <= 0.00001) {
      float edgeY = (p.y >= 0.0 && p.y <= 1.0) ? 1.0 : 0.0;

      return edgeX * edgeY;
   }

   // Smooth stepping zone for the horizontal sides (Top/Bottom and skewed diagonals)

   float edgeMinY = smoothstep (0.0, width, p.y);
   float edgeMaxY = smoothstep (1.0, 1.0 - width, p.y);
   float edgeY = edgeMinY * edgeMaxY;

   return edgeX * edgeY;
}

bool IsInBounds (float2 p) 
{
   float2 delta = saturate (p) - p;

   return bool (abs (delta.x + delta.y) < 0.000000001);
}

float2 project (float2 p) 
{
   return p * float2 (1.0, -1.2) - float2 (0.0, floating / 10.0);
}

float4 dw_bgColor (sampler s_from, sampler s_to, float2 p, float2 pfr, float2 pto) 
{
   float4 c = float4 (0.0.xxx, 1.0);

   pfr = project (pfr);

   if (IsInBounds (pfr))
      c += lerp (kTransparentBlack, tex2D (s_from, pfr), reflection * lerp (1.0, 0.0, pfr.y));

   pto = project(pto);

   if (IsInBounds (pto))
      c += lerp (kTransparentBlack, tex2D (s_to, pto), reflection * lerp (1.0, 0.0, pto.y));

   return c;
}

float2 xskew (float2 p, float perspectiveParam, float center) 
{
   float ip = 1.0 - perspectiveParam;
   float x  = lerp (p.x, 1.0 - p.x, center);

   return ((float2 (x, (p.y - 0.5 * ip * x) / (1.0 - ip * x))
      - float2 (0.5 - distance (center, 0.5), 0.0))
      * float2 (0.5 / distance (center, 0.5) * (center < 0.5 ? 1.0 : -1.0), 1.0)
      + float2 (center < 0.5 ? 0.0 : 1.0, 0.0));
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

DeclareEntryPoint (CubeFlip)
{
   float uz = unzoom * 2.0 * (0.5 - distance (0.5, amount));

   float2 uv = flip (uv3);
   float2 p  = -uz * 0.5 + (1.0 + uz) * uv;
   float2 fromP = xskew ((p - float2 (amount, 0.0)) / float2 (1.0 - amount, 1.0), 1.0 - lerp (amount, 0.0, persp), 0.0);
   float2 toP   = xskew (p / float2 (amount, 1.0), lerp (pow (amount, 2.0), 1.0, persp), 1.0);

   // Remap UI Slider value (0.0 to 1.0) linearly down into pixel filter math width scale

   float internalWidth = smoothness * 0.02;

   // Calculate selective Anti-Aliasing visibility weights

   float visibilityFrom = aaFactorSelective (fromP, internalWidth);
   float visibilityTo   = aaFactorSelective (toP, internalWidth);
   
   float4 colorFrom = tex2D (Fgd, saturate (fromP));
   float4 colorTo   = tex2D (Bgd, saturate (toP));
   float4 colorBg   = dw_bgColor (Fgd, Bgd, uv, fromP, toP);

   // Composite the layers safely using the selective alpha bounds mapping

   float4 outputColor = lerp (colorBg, colorTo, visibilityTo);

   return lerp (outputColor, colorFrom, visibilityFrom);
}

