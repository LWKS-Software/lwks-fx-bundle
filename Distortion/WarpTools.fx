// @Maintainer jwrl
// @Released 2024-11-18
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
// Updated 2024-11-18 jwrl.
// Rolled the original warp and skew functions into the main shader code.
// Mirrored the foreground sampler to correct the warp factor edge jitter.
// Corrected scaling and position tracking.
// Replaced the original unnecessary 3D skew code with simpler 2D skewing.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Warp tools", "DVE", "Distortion", "Warps, skews and scales video", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg, Linear, Mirror);
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

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (WarpTools)
{
   // First scale and position the foreground coordinates.  Then produce a sine curve
   // based on YX position.  X and Y are reversed because the horizontal edges need to
   // be moved vertically, and the vertical edges horizontally.

   float2 uv = ((uv3 - float2 (Pos_X, 1.0 - Pos_Y)) / max (1.0e-6, float2 (ScaleX, ScaleY) * ScaleXY)) + 0.5.xx;
   float2 xy = sin (uv.yx * PI);

   // Now the warp factors are calculated for the left, right, upper and lower edges.

   float x1 = xy.x * Left_Warp * (uv.x - 1.0);
   float x2 = xy.x * RightWarp * -uv.x;
   float y1 = xy.y * UpperWarp * (1.0 - uv.y);
   float y2 = xy.y * LowerWarp * uv.y;

   // Now the distortion is summed and stored in xy.  If warp compensation is turned on
   // the linear warp factor is subtracted from each of the X and Y coordinates when the
   // warp could possibly go out of bounds.

   xy = float2 (x1, y1) + float2 (x2, y2);

   if (Warp_Comp) {
      if (Left_Warp < 0.0) xy.x += Left_Warp * (1.0 - uv.x);
      if (RightWarp > 0.0) xy.x += RightWarp * uv.x;
      if (UpperWarp > 0.0) xy.y -= UpperWarp * (1.0 - uv.y);
      if (LowerWarp < 0.0) xy.y -= LowerWarp * uv.y;
   }

   // Now the summed warp coordinates are divided by two to keep distortion within
   // bounds.  They are then added to the foreground video pixel address.

   xy /= 2.0;
   xy += uv;

   // The skew factor is now calculated and applied.  This is just a simple XY offset.

   x1 = lerp (-Horizontal, 1.0 - Horizontal, xy.x);
   x2 = lerp ( Horizontal, 1.0 + Horizontal, xy.x);
   y1 = lerp ( Vertical,   1.0 + Vertical,   xy.y);
   y2 = lerp (-Vertical,   1.0 - Vertical,   xy.y);

   uv.x = lerp (x1, x2, xy.y);
   uv.y = lerp (y1, y2, xy.x);

   // Foreground and background are blended into Warp and the masked result is returned.

   float4 Fgnd = ReadPixel (Fgd, uv);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 Warp = lerp (Bgnd, Fgnd, Fgnd.a * Opacity);

   return lerp (Bgnd, Warp, tex2D (Mask, uv3).x);
}
