// @Maintenance jwrl
// @Released 2026-09-27
// @Author hugly
// @Created 2026-09-12

/**
 This effect has two modes, each of which can operate in either of two directions,
 reflecting the video in the black "floor" as it transitions.  The 2D mode in the split
 apart direction splits the outgoing video apart in the same way as a barndoor effect
 does.  This reveals the incoming video as it zooms to full frame.  In the join split
 direction the outgoing video zooms out and is covered as the incoming split video joins
 together.

 The 3D mode in "3D Swing open" direction splits and rotates to the right and left of
 frame, revealing the zooming incoming video.  "3D Swing shut" direction swings the
 incoming video shut from the right and left of frame, as the outgoing video zooms out.
 All video, whether incoming or outgoing, has adjustable reflections.

   [*]Amount:  The progress of the transition.
   [*]Transition type:  Selects from "3D Swing open", "3D Swing shut", "2D Split
      apart" and "2D Join split".
   [*]Perspective:  Adjusts the 3D rotation (perspective distortion) of the video
      sources during the transition.
   [*]Distance:  Adjusts the distance that the sources move during the transition.
   [*]Reflection:  Controls the intensity of the reflection.
   [*]Float:  Adjusts the distance that the video is from the reflecting surface.
   [*]Feather:  Smooths the horizontal edges of the cube to minimise jaggies.

 The feather setting is provided for antialiassing, and smooths just the horizontal edges
 of the video.  This is usually necessary with 3D effects because of the "jaggies" that
 can be produced as the video rotates through 3D space.
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
// Modified 2026-09-27 jwrl.
// Edited the header text for better readability.
//
// Modified 2026-09-26 jwrl.
// Changed "3D Rigid Swing" to "3D Swing open" and added "3D Swing shut" mode.
// Changed "2D Split" to "2D Split apart" and added "2D Join split" mode.
//
// Modified 2026-09-25 hugly
// Changed default mode to "3D Rigid Swing"
// Changed "Distance" to display  percent
//
// Code cleanup 2026-09-22 jwrl.
// Converted integer parameter typeSelect to SetTecnique to reduce conditional execution.
// Split shader to allow for separate execution of "2D Split" and "3D Rigid Swing".
// Duplicated dw_bgColor() to dw_bgColor2D() and dw_bgColor3D() to support split execution.
// Changed order of settings to match hugly's preferred order.'
//
// AI conversion by hugly 2026-09-12
//-----------------------------------------------------------------------------------------//
 
DeclareLightworksEffect ("3D Doorway", "Mix", "3D transitions", "AI Reconstructed Multi-Mode Transition Layer (2D splits and 3D swings)", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (amount, "Amount",   kNoGroup, kNoFlags, 0.5,  0.0, 1.0);

DeclareIntParam   (SetTechnique,   "Transition type", kNoGroup, 0, "3D Swing open|3D Swing shut|2D Split apart|2D Join split");

DeclareFloatParam (perspective, "Perspective", kNoGroup, kNoFlags, 0.6,  0.0, 1.0);
DeclareFloatParam (depth,       "Distance",    kNoGroup, "DisplayAsPercentage", 0.3,  0.1, 0.7);
DeclareFloatParam (reflection,  "Reflection",  kNoGroup, kNoFlags, 0.4,  0.0, 1.0);
DeclareFloatParam (floating,    "Float",       kNoGroup, "DisplayAsPercentage", 0.3,  0.1, 1.0);
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
   return p * float2 (1.0, -1.2) + float2 (0.0, -floating / 10.0);
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

float4 ReadInverse (sampler vid, float2 xy)
{
   return ReadPixel (vid, float2 (xy.x, 1.0 - xy.y));
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// 3D Swing open

DeclarePass (Fg0)
{ return ReadInverse (Fg, uv1); }

DeclarePass (Bg0)
{ return ReadInverse (Bg, uv2); }

DeclareEntryPoint (Doorway3DswingOpen)
{
   float invAmt = 1.0 - amount;
   float bgSize = lerp (1.0, depth * 10.0, invAmt);

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

   float4 outputColor = ReadPixel (Bg0, toP);

   if (!inBounds(toP)) outputColor = dw_bgColor3D (Fg0, Bg0, xy, fromP, toP, isLeftDoor, normX);

   if (inBounds (fromP)) outputColor = lerp (outputColor, ReadPixel (Fg0, fromP), visibilityFrom);

   return outputColor;
}

//-----------------------------------------------------------------------------------------//

// 3D Swing shut

DeclarePass (Fg1)
{ return ReadInverse (Fg, uv1); }

DeclarePass (Bg1)
{ return ReadInverse (Bg, uv2); }

DeclareEntryPoint (Doorway3DswingShut)
{
   float bgSize = lerp (1.0, depth * 10.0, amount);

   float2 xy  = flip (uv3);
   float2 toP = (xy - 0.5.xx) * bgSize + 0.5.xx;
   float2 fromP;

   bool isLeftDoor = (xy.x <= 0.5);

   float pFactor = perspective * (1.0 - amount);
   float normX, skewY;

   if (isLeftDoor) {
      normX = xy.x / (0.5 * amount);
      skewY = (xy.y - 0.5 * pFactor * normX) / (1.0 - pFactor * normX);
      fromP = float2 (normX * 0.5, skewY);
   }
   else {
      normX = (1.0 - xy.x) / (0.5 * amount);
      skewY = (xy.y - 0.5 * pFactor * normX) / (1.0 - pFactor * normX);
      fromP = float2 (1.0 - (normX * 0.5), skewY);
   }

   float2 testBoundsUV = float2 (normX, skewY);

   float internalWidth  = smoothness * 0.02;
   float visibilityFrom = aaFactorSelective (testBoundsUV, internalWidth);

   float4 outputColor = ReadPixel (Fg1, toP);

   if (!inBounds(toP)) outputColor = dw_bgColor3D (Bg1, Fg1, xy, fromP, toP, isLeftDoor, normX);

   if (inBounds (fromP)) outputColor = lerp (outputColor, ReadPixel (Bg1, fromP), visibilityFrom);

   return outputColor;
}

//-----------------------------------------------------------------------------------------//

// 2D Split apart

DeclarePass (Fg2)
{ return ReadInverse (Fg, uv1); }

DeclarePass (Bg2)
{ return ReadInverse (Bg, uv2); }

DeclareEntryPoint (Doorway2DsplitApart)
{
   float bgSize = lerp (1.0, depth * 10.0, 1.0 - amount);

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

   float4 outputColor = ReadPixel (Bg2, toP);

   if (!inBounds(toP)) outputColor = dw_bgColor2D (Fg2, Bg2, xy, fromP, toP, normXFactor);

   if (inBounds (fromP)) outputColor = lerp (outputColor, ReadPixel (Fg2, fromP), visibilityFrom);

   return outputColor;
}

//-----------------------------------------------------------------------------------------//

// 2D Join split

DeclarePass (Fg3)
{ return ReadInverse (Fg, uv1); }

DeclarePass (Bg3)
{ return ReadInverse (Bg, uv2); }

DeclareEntryPoint (Doorway2DjoinSplit)
{
   float invAmt = 1.0 - amount;
   float bgSize = lerp (1.0, depth * 10.0, amount);

   float2 xy    = flip (uv3);
   float2 toP   = (xy - 0.5.xx) * bgSize + 0.5.xx;
   float2 fromP = -1.0.xx;
   float2 testBoundsUV;

   float middleSlit = 2.0 * abs (xy.x - 0.5) - invAmt;
   float normXFactor;

   if (middleSlit > 0.0) {
      float d = 1.0 / (1.0 + perspective * invAmt * (1.0 - middleSlit));

      fromP   = xy + (xy.x > 0.5 ? -1.0 : 1.0) * float2 (0.5 * invAmt, 0.0);
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

   float4 outputColor = ReadPixel (Fg3, toP);

   if (!inBounds(toP)) outputColor = dw_bgColor2D (Bg3, Fg3, xy, fromP, toP, normXFactor);

   if (inBounds (fromP)) outputColor = lerp (outputColor, ReadPixel (Bg3, fromP), visibilityFrom);

   return outputColor;
}
