// @Maintenance jwrl
// @Released 2026-09-22
// @Author hugly
// @Created 2026-09-12

/**
 This effect has two modes.  The 2D mode splits the outgoing video apart as if it's
 a barndoor effect.  The incoming video is revealed by the split, and zooms up to full
 frame, reflecting in the black "floor" as it zooms.  The 3D mode splits and rotates
 to the right and left of frame, revealing the zooming incoming video.  All video,
 whether incoming or outgoing, has adjustable reflections.

   [*]Amount:  The progress of the transition.
   [*]Transition type:  Selects between 2D split mode and 3D rigid swing.
   [*]Reflection:  Controls the intensity of the reflection.
   [*]Perspective:  Adjusts the 3D rotation (perspective distortion) of the video
      sources during the transition.
   [*]Depth scale:  Adjusts the distance that the video sources move during the
      transition.
   [*]Float:  Adjusts the distance that the video sources move during the transition.
   [*]Feather:  Smooth the horizontal edges of the cube to minimise jaggies.

 Antialiassing is provided using the "Feather" parameter, which smooths the horizontal
 edges during the transition progress.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect 3D Doorway.fx
//
//-----------------------------------------------------------------------------------------//
// Combined 2D Split and 3D Perspective Rigid Swing Transition Layer
// Optimized Framework Translation with Horizontal Anti-Aliasing & Type Selector
//-----------------------------------------------------------------------------------------//
//
// Version history.
//
// Code cleanup 2026-09-22 jwrl.
//
// AI conversion by hugly 2026-09-12
//-----------------------------------------------------------------------------------------//
 
DeclareLightworksEffect ("3D Doorway", "Mix", "3D transitions", "AI Reconstructed Multi-Mode Transition Layer (2D Split / 3D Rigid Swing)", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (amount, "Amount",   kNoGroup, kNoFlags, 0.5,  0.0, 1.0);

DeclareIntParam   (SetTechnique,  "Transition type", kNoGroup, 0, "2D Split|3D Rigid Swing");

DeclareFloatParam (reflection,  "Reflection",  kNoGroup, kNoFlags, 0.4,  0.0, 1.0);
DeclareFloatParam (perspective, "Perspective", kNoGroup, kNoFlags, 0.6,  0.0, 1.0);
DeclareFloatParam (depth,       "Depth scale", kNoGroup, kNoFlags, 3.0,  1.0, 7.0);
DeclareFloatParam (floating,    "Float",       kNoGroup, kNoFlags, 3.0,  1.0, 10.0);
DeclareFloatParam (smoothness,  "Feather",     kNoGroup, kNoFlags, 0.15, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define flip(v) float2(v.x, 1.0 - v.y)

#define black   float4(0.0.xxx, 1.0)

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

bool isValid (float p)
{
   return saturate (p) == p;
}

bool inBounds (float2 p)
{
   float2 delta = saturate (p) - p;

   return bool (abs (delta.x + delta.y) < 0.000000001);
}

float2 project (float2 p)
{
   return p * float2 (1.0, -1.2) + float2 (0.0, -floating / 100.0);
}

float4 dw_bgColor2D (sampler sFg, sampler sBg, float2 p, float2 pfr, float2 pto, float xW)
{
   float4 c = black;

   if (isValid (xW)) {
      float2 projectedPfr = project (pfr);

      if (inBounds (projectedPfr)) {
         float f = lerp (1.0, 0.0, projectedPfr.y);

         c += lerp (black, tex2D (sFg, projectedPfr), reflection * f);
      }
   }

   pto = project (pto);

   if (inBounds (pto)) c += lerp (black, tex2D (sBg, pto), reflection * lerp (1.0, 0.0, pto.y));

   return c;
}

float4 dw_bgColor3D (sampler sFg, sampler sBg, float2 p, float2 pfr, float2 pto, bool isLeft, float xW)
{
   float4 c = black;

   if (isValid (xW)) {
      float2 projectedPfr = project (pfr);

      if (inBounds (projectedPfr)) {
         if (isLeft) projectedPfr.x = clamp (projectedPfr.x, 0.0, 0.4999);
         else projectedPfr.x = clamp (projectedPfr.x, 0.5001, 1.0);

         float f = lerp (1.0, 0.0, projectedPfr.y);

         c += lerp (black, tex2D (sFg, projectedPfr), reflection * f);
      }
   }

   pto = project (pto);

   if (inBounds (pto)) c += lerp (black, tex2D (sBg, pto), reflection * lerp (1.0, 0.0, pto.y));

    return c;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Fg0)
{ return ReadPixel (Fg, flip (uv1)); }

DeclarePass (Bg0)
{ return ReadPixel (Bg, flip (uv2)); }

DeclareEntryPoint (Doorway2D)
{
   float bgSize = lerp (1.0, depth, 1.0 - amount);

   float2 xy    = flip (uv3);
   float2 toP   = (xy - 0.5.xx) * bgSize + 0.5.xx;
   float2 fromP = -1.0.xx;
   float2 testBoundsUV;

   float middleSlit = 2.0 * abs (xy.x - 0.5) - amount;
   float normXFactor;

   if (middleSlit > 0.0) {
      float d = 1.0 / (1.0 + perspective * amount * (1.0 - middleSlit));

      fromP   = xy + (xy.x > 0.5 ? -1.0 : 1.0) * float2 (0.5 * amount, 0.0);
      fromP.y = (fromP.y - 0.5) * d + 0.5;
      testBoundsUV = fromP;
      normXFactor  = fromP.x;
   }
   else {
      testBoundsUV = 0.0.xx;
      normXFactor  = -1.0;
   }

   float internalWidth = smoothness * 0.020;
   float visibilityFrom = aaFactorSelective (testBoundsUV, internalWidth);

   float4 outputColor = tex2D (Bg0, toP);

   if (!inBounds(toP)) outputColor = dw_bgColor2D (Fg0, Bg0, xy, fromP, toP, normXFactor);

   if (inBounds (fromP)) outputColor = lerp (outputColor, ReadPixel (Fg0, fromP), visibilityFrom);

   return outputColor;
}

//-----------------------------------------------------------------------------------------//

DeclarePass (Fg1)
{ return ReadPixel (Fg, flip (uv1)); }

DeclarePass (Bg1)
{ return ReadPixel (Bg, flip (uv2)); }

DeclareEntryPoint (Doorway3D)
{
   float invAmt = 1.0 - amount;
   float bgSize = lerp (1.0, depth, invAmt);

   float2 xy  = flip (uv3);
   float2 toP = (xy - 0.5.xx) * bgSize + 0.5.xx;
   float2 fromP;

   bool isLeftDoor = (xy.x <= 0.5);

   float pFactor = perspective * amount;
   float normX, skewY;

   if (isLeftDoor) {
      normX = xy.x / (0.5 * invAmt);
      skewY = (xy.y - 0.5 * pFactor * normX) / (1.0 - pFactor * normX);
      fromP = float2 (normX * 0.5, skewY);
   }
   else {
      normX = (1.0 - xy.x) / (0.5 * invAmt);
      skewY = (xy.y - 0.5 * pFactor * normX) / (1.0 - pFactor * normX);
      fromP = float2 (1.0 - (normX * 0.5), skewY);
   }

   float2 testBoundsUV = float2 (normX, skewY);

   float internalWidth  = smoothness * 0.02;
   float visibilityFrom = aaFactorSelective (testBoundsUV, internalWidth);

   float4 outputColor = ReadPixel (Bg1, toP);

   if (!inBounds(toP)) outputColor = dw_bgColor3D (Fg1, Bg1, xy, fromP, toP, isLeftDoor, normX);

   if (inBounds (fromP)) outputColor = lerp (outputColor, ReadPixel (Fg1, fromP), visibilityFrom);

   return outputColor;
}

