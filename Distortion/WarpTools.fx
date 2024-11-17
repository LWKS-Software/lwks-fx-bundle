// @Maintainer jwrl
// @Released 2024-11-17
// @Author jwrl
// @Created 2024-11-17

/**
 This effect is very simple in concept.  It uses a sine deformation to warp the foreground
 video.  That warped video can then be skewed, scaled and positioned.  The final result
 is then superimposed over a background layer, and its opacity can be adjusted.  Finally
 Lightworks effect masking can be applied.

   * Opacity:  Fades the foreground into the background.
   * Warp factor
     * Warp compensation:  Forces warped video to stay inside frame boundaries.
     * Upper edge:  Warps the top edge of the frame.
     * Lower edge:  Warps the bottom edge of the frame.
     * Left edge:  Warps the left edge of the frame.
     * Right edge:  Warps the right edge of the frame.
   * Skew factor
     * Horizontal:  Skews the image horizontally.
     * Vertical:  Skews the image vertically.
   * Geometry
     * Scale XY:  Master scaling.
     * Scale X:  Scales the image horizontally.
     * Scale Y:  Scales the image vertically.
     * Position X:  Adjusts the horizontal position of the image.
     * Position Y:  Adjusts the vertical position of the image.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect WarpTools.fx
//
// Version history:
//
// Built 2024-11-17 by jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Warp tools", "DVE", "Distortion", "Warps, skews and scales video", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg, Linear);
DeclareInput (Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareBoolParam  (Warp_Comp, "Warp compensation", "Warp factor", true);
DeclareFloatParam (UpperWarp, "Upper edge", "Warp factor", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (LowerWarp, "Lower edge", "Warp factor", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Left_Warp, "Left edge",  "Warp factor", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (RightWarp, "Right edge", "Warp factor", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (Horizontal, "Horizontal", "Skew factor", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (Vertical,   "Vertical",   "Skew factor", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (ScaleXY, "Scale XY", "Geometry", kNoFlags,          1.0, 0.01, 10.0);
DeclareFloatParam (ScaleX,  "Scale X",  "Geometry", kNoFlags,          1.0, 0.01, 10.0);
DeclareFloatParam (ScaleY,  "Scale Y",  "Geometry", kNoFlags,          1.0, 0.01, 10.0);
DeclareFloatParam (Pos_X,   "Position", "Geometry", "SpecifiesPointX", 0.5, 0.0,  1.0);
DeclareFloatParam (Pos_Y,   "Position", "Geometry", "SpecifiesPointY", 0.5, 0.0,  1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI 3.1415927

#define _TransparentBlack 0.0.xxxx

#define Scale    (float2 (ScaleX, ScaleY) * ScaleXY)
#define ScaleMin min(1.0.xx, Scale)
#define ScaleMax max(1.0.xx, Scale)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

void skewXY (out float2 xy1, out float2 xy2, out float2 xy3, out float2 xy4)
{
   xy1 = float2 (Horizontal, 1.0 + Vertical);
   xy2 = float2 (Horizontal, -Vertical) + 1.0.xx;
   xy3 = float2 (-Horizontal, Vertical);
   xy4 = float2 (1.0 - Horizontal, -Vertical);

   return;
}

float2 warpXY (float2 uv)
{
   float x0 = sin (uv.y * PI);
   float y0 = sin (uv.x * PI);
   float x1 = x0 * Left_Warp * (uv.x - 1.0);
   float x2 = x0 * -RightWarp * uv.x;
   float y1 = y0 * UpperWarp * (1.0 - uv.y);
   float y2 = y0 * LowerWarp * uv.y;

   float2 xy;

   if (Warp_Comp) {
      xy.x  = Left_Warp < 0.0 ? x1 + (Left_Warp * (1.0 - uv.x)) : x1;
      xy.x += RightWarp > 0.0 ? x2 + (RightWarp * uv.x) : x2;
      xy.y  = UpperWarp > 0.0 ? y1 - (UpperWarp * (1.0 - uv.y)) : y1;
      xy.y += LowerWarp < 0.0 ? y2 - (LowerWarp * uv.y) : y2;
   }
   else xy = float2 (x1, y1) + float2 (x2, y2);

   xy /= 2.0;
   xy += uv - 0.5.xx;
   xy /= ScaleMin;
   xy += 0.5.xx;

   return xy;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, warpXY (uv1)); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (WarpTools)
{
   float2 TL, TR, BL, BR;

   skewXY (TL, TR, BL, BR);

   float2 xy1 = float2 (TR.x - BL.x, BL.y - TR.y);
   float2 xy2 = float2 (BR.x - BL.x, BL.y - BR.y);
   float2 xy3 = float2 (TL.x - TR.x, TR.y - TL.y);
   float2 xy  = xy3 - xy2;

   float den = (xy1.x * xy2.y) - (xy2.x * xy1.y);
   float top = ((xy.x * xy2.y) - (xy2.x * xy.y)) / den;
   float bot = ((xy1.x * xy.y) - (xy.x * xy1.y)) / den;
   float bt1 = bot + 1.0;

   float a = (top * TR.x) - xy3.x;
   float b = (top * (1.0 - TR.y)) - xy3.y;
   float c = top;
   float d = (BR.x * bt1) - TL.x;
   float e = TL.y + bot - (BR.y * bt1);
   float f = bot;
   float g = TL.x;
   float h = 1.0 - TL.y;
   float i = 1.0;

   float x = e - (f * h);
   float y = (f * g) - d;
   float z = (d * h) - (e * g);

   float3x3 v = float3x3 (x, (c * h) - b, (b * f) - (c * e),
                          y, a - (c * g), (c * d) - (a * f),
                          z, (b * g) - (a * h), (a * e) - (b * d)) / ((a * x) + (b * y) + (c * z));
   float3x3 w = float3x3 (v [0].x - v [0].y, -v [0].y, v [0].z - (v [0].y * 2.0),
                          v [1].x - v [1].y, -v [1].y, v [1].z - (v [1].y * 2.0),
                          v [2].x - v [2].y, -v [2].y, v [2].z - (v [2].y * 2.0));

   float3 xyz = mul (float3 (uv3, 1.0), w);

   xy = (((xyz.xy / xyz.z) - 0.5.xx) / ScaleMax) + float2 (1.0 - Pos_X, Pos_Y);

   float4 Fgnd   = any (xy - frac (xy)) ? _TransparentBlack : tex2D (Fgd, xy);
   float4 Bgnd   = tex2D (Bgd, uv3);
   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a);

   return lerp (Bgnd, retval, Opacity * tex2D (Mask, uv3).x);
}
