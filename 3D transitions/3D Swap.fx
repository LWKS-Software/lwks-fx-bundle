// @Maintenance jwrl
// @Released 2026-09-20
// @Author hugly
// @Created 2026-09-12

/**
 This effect rotates the outgoing video away to the left of frame, revealing
 the incoming video.  That video rotates into frame from the right.  The depth
 of the perspective and the distance that the video travels are both fully
 adjustable.

   [*]Amount:  The progress of the transition.
   [*]Reflection:  Controls the intensity of the reflection.
   [*]Perspective:  Adjusts the 3D rotation (perspective distortion) of the video
      sources during the transition.
   [*]Depth:  Adjusts the distance that the video sources move during the transition.
   [*]Smooth edges:  Smooth the horizontal edges of the cube to minimise jaggies.

 Antialiassing is provided using the "Smooth edges" parameter, which smooths just the
 horizontal edges during rotation.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 3D Swap.fx
//
// 3D Doorway Transition Engine with Anti-Aliased Surface Smoothing
// Cross-compiled from GLSL to Lightworks Multi-Pass Wipe Framework
//
// Version history.
//
// Code cleanup 2026-09-20 jwrl.
//
// AI conversion by hugly 2026-09-12
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("3D Swap", "Mix", "3D transitions", "3D Doorway page-style transition with selective edge anti-aliasing.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (amount, "Amount", kNoGroup, kNoFlags, 0.5,  0.0, 1.0);

DeclareFloatParam (reflection,  "Reflection",   kNoGroup, kNoFlags, 0.4,  0.0, 1.0);
DeclareFloatParam (perspective, "Perspective",  kNoGroup, kNoFlags, 0.2,  0.0, 1.0);
DeclareFloatParam (depth,       "Depth",        kNoGroup, kNoFlags, 3.0,  1.0, 10.0);
DeclareFloatParam (smoothness,  "Smooth edges", kNoGroup, kNoFlags, 0.15, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Declarations and definitions
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define flip(v) float2(v.x, 1.0 - v.y)

float4 black = float4 (0.0.xxx, 1.0);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float aaFactorSelective (float2 p, float width) 
{
   float edgeX = (p.x >= 0.0 && p.x <= 1.0) ? 1.0 : 0.0;

   if (width <= 0.00001) {
      float edgeY = (p.y >= 0.0 && p.y <= 1.0) ? 1.0 : 0.0;

      return edgeX * edgeY;
   }

   float edgeMinY = smoothstep (0.0, width, p.y);
   float edgeMaxY = smoothstep (1.0, 1.0 - width, p.y);
   float edgeY    = edgeMinY * edgeMaxY;

   return edgeX * edgeY;
}

bool IsInBounds (float2 p) 
{
   float2 delta = saturate (p) - p;

   return bool (abs (delta.x + delta.y) < 0.000000001);
}

float2 project (float2 p) 
{
   return p * float2 (1.0, -1.2) + float2 (0.0, -0.02);
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

DeclareEntryPoint (Warp3D)
{
   // Correct coordinate orientation matching template layout logic

   float2 p = flip (uv3);

   float invAmt = 1.0 - amount;
   float size   = lerp (1.0, depth, amount);
   float persp  = perspective * amount;

   float2 pfr = (p - float2 (0.0, 0.5)) * float2 (size / (1.0 - perspective * amount), size / (1.0 - size * persp * p.x)) + float2 (0.0, 0.5);

   size  = lerp (1.0, depth, invAmt);
   persp = perspective * invAmt;

   float2 pto = (p - float2 (1.0, 0.5)) * float2 (size / (1.0 - perspective * invAmt), size / (1.0 - size * persp * (0.5 - p.x))) + float2 (1.0, 0.5);

   // Establish the dynamic anti-aliasing scaling factor

   float internalWidth  = smoothness * 0.02;
   float visibilityFrom = aaFactorSelective (pfr, internalWidth);
   float visibilityTo   = aaFactorSelective (pto, internalWidth);

   if (amount < 0.5) {
     if (IsInBounds (pfr)) return lerp (black, tex2D (Fgd, pfr), visibilityFrom);

     if (IsInBounds (pto)) return lerp (black, tex2D (Bgd, pto), visibilityTo);
   }

   if (IsInBounds (pto)) return lerp (black, tex2D (Bgd, pto), visibilityTo);

   if (IsInBounds (pfr)) return lerp (black, tex2D (Fgd, pfr), visibilityFrom);

   float4 c = black;

   float2 projectedPfr = project (pfr);
   float2 projectedPto = project (pto);

   if (IsInBounds (projectedPfr)) {
     float visibilityPfr = aaFactorSelective (projectedPfr, internalWidth);

     c = lerp (c, c + lerp (black, tex2D (Fgd, projectedPfr), reflection * lerp (1.0, 0.0, projectedPfr.y)), visibilityPfr);
   }

   if (IsInBounds (projectedPto)) {
     float visibilityPto = aaFactorSelective (projectedPto, internalWidth);

     c = lerp (c, c + lerp (black, tex2D (Bgd, projectedPto), reflection * lerp (1.0, 0.0, projectedPto.y)), visibilityPto);
   }
   
   return c;
}

