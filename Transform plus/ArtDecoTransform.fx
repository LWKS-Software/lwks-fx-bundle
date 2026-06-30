// @Maintainer jwrl
// @Released 2026-06-30
// @Author jwrl
// @Created 2017-04-27

/**
 This is an Art Deco take on a classic transform.  It produces two independently
 adjustable borders around the foreground image.  It also produces corner flash lines
 inside the crop which are independently adjustable.

   [*]Position:  Self explanatory.
   [*]Scale
      [*]Scale XY:  Adjusts master size using a quadratic law so that area changes linearly.
      [*]Scale X:  Adjusts width using a quadratic law.
      [*]Scale Y:  Adjusts height using a quadratic law.
   [*]Crop
      [*]Left:  Crops the left of frame.
      [*]Top:  Crops the top of frame.
      [*]Right:  Crops the right of frame.
      [*]Bottom:  Crops the bottom of frame.
   [*]Border settings
      [*]Border width:  Self explanatory.
      [*]Outer gap:  Adjusts the space between the border and the outer line.
      [*]Outer gap fill:  Selects between background, foreground or black.
      [*]Outer width:  Sets the thickness of the outer line.
   [*]Flash line settings
      [*]Gap:  Sets the space between the border and the inner flash lines.
      [*]Line width:  Sets the width of the flash lines.
      [*]Line position:  Selects between top left / bottom right and top right / bottom left for the flash lines.
      [*]Upper A:  Sets the vertical length of the upper flash line.
      [*]Upper B:  Sets the horizontal length of the upper flash line.
      [*]Lower A:  Sets the vertical length of the lower flash line.
      [*]Lower B:  Sets the horizontal length of the lower flash line.
   [*]Border colour:  Self explanatory.
   [*]Opacity:  Self explanatory.
   [*]Background:  Self explanatory.

 This version is a complete rebuild of DecoDVE to support the effects resolution
 independence available with Lightworks v2021 and higher.  A consequence of that is
 that it is in no way directly interchangeable with that effect.  This version crops,
 scales and positions in the same way as a standard transform, rather than using the
 unusual double scale and position technique of the earlier version.  Scaling also
 is the same as the standard transform effect.

 Dropped from this version is the ability to display multiple images, which wasn't
 really consistent with the look that we were trying to achieve.  Replacing it is a
 command to mask the image using the LW masking tool.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ArtDecoTransform.fx
//
// Version history:
//
// Updated 2026-06-30 jwrl.
// Changed "Master" to "Scale XY".
// Changed "X" to "Scale X".
// Changed "Y" to "Scale Y".
// Changed "Outer bdr width" to "Outer width".
// Changed "Upper flash A" to "Upper A".
// Changed "Upper flash B" to "Upper B".
// Changed "Lower flash A" to "Lower A".
// Changed "Lower flash B" to "Lower B".
// Now uses Mask.rgba for masking rather than Mask.r.
// Added settings description to header block.
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with float4 _TransparentBlack for Linux fix.
//
// Updated 2023-06-24 jwrl.
// Changed foreground autocrop to masking.
//
// Updated 2023-06-19 jwrl.
// Changed DVE references to transform.
// Changed title from "Art Deco DVE" to "Art Deco transform"
// Changed subcategory from "DVE Extras" to "Transform plus".
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-02-17 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Art Deco transform", "DVE", "Transform plus", "Art Deco flash lines are included in the transform borders", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (PosX,        "Position",       kNoGroup,              "SpecifiesPointX", 0.5, -1.0, 2.0);
DeclareFloatParam (PosY,        "Position",       kNoGroup,              "SpecifiesPointY", 0.5, -1.0, 2.0);

DeclareFloatParam (MasterScale, "Scale XY",       "Scale",               kNoFlags, 1.0, 0.0, 3.16227766);
DeclareFloatParam (XScale,      "Scale X",        "Scale",               kNoFlags, 1.0, 0.0, 3.16227766);
DeclareFloatParam (YScale,      "Scale Y",        "Scale",               kNoFlags, 1.0, 0.0, 3.16227766);

DeclareFloatParam (Left,        "Left",           "Crop",                kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Top,         "Top",            "Crop",                kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Right,       "Right",          "Crop",                kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Bottom,      "Bottom",         "Crop",                kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (Border_1,    "Border width",   "Border settings",     kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (BorderGap,   "Outer gap",      "Border settings",     kNoFlags, 0.2, 0.0, 1.0);
DeclareIntParam (GapFill,       "Outer gap fill", "Border settings", 0,  "Background|Foreground|Black");
DeclareFloatParam (Border_2,    "Outer width",    "Border settings",     kNoFlags, 0.1, 0.0, 1.0);

DeclareFloatParam (InnerSpace,  "Gap",            "Flash line settings", kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (InnerWidth,  "Line width",     "Flash line settings", kNoFlags, 0.1, 0.0, 1.0);
DeclareIntParam (InnerPos,      "Line position",  "Flash line settings", 0, "Top left / bottom right|Top right / bottom left");
DeclareFloatParam (Flash_L,     "Upper A",        "Flash line settings", kNoFlags, 0.75, 0.0, 1.0);
DeclareFloatParam (Flash_T,     "Upper B",        "Flash line settings", kNoFlags, 0.75, 0.0, 1.0);
DeclareFloatParam (Flash_R,     "Lower A",        "Flash line settings", kNoFlags, 0.125, 0.0, 1.0);
DeclareFloatParam (Flash_B,     "Lower B",        "Flash line settings", kNoFlags, 0.125, 0.0, 1.0);

DeclareColourParam (Colour,     "Border colour",  kNoGroup,              kNoFlags, 1.0, 1.0, 1.0);
DeclareFloatParam (Opacity,     "Opacity",        kNoGroup,              kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Background,  "Background",     kNoGroup,              kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (_FgOrientation);

DeclareFloat4Param (_FgExtents);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define InRange(XY,TL,BR) (all (XY >= TL) && all (BR >= XY))

#define CENTRE 0.5

float4 _TransparentBlack = 0.0.xxxx;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_crop (inout float2 P, out float2 LT, out float2 RB)
{
   float4 crop = float4 (Left, Top, 1.0 - Right, 1.0 - Bottom);

   LT = float2 (Flash_L, Flash_T);
   RB = float2 (Flash_R, Flash_B);

   if (_FgOrientation == 90) {
      crop = crop.wxyz;
      crop.xz = 1.0 - crop.xz;
      P = float2 (P.y, 1.0 - P.x);
   }
   else if (_FgOrientation == 180) {
      crop = 1.0 - crop.zwxy;
      P = 1.0 - P;
   }
   else if (_FgOrientation == 270) {
      crop = crop.yzwx;
      crop.wy = 1.0 - crop.wy;
      P = float2 (1.0 - P.y, P.x);
   }

   if (InnerPos) P = float2 (1.0 - P.x, P.y);

   return crop;
}

float2 fn_position (inout float2 S)
{
   float2 pos = S;

   if (_FgOrientation == 90) {
      pos *= CENTRE - float2 (PosY, PosX);
      S.y /= _OutputAspectRatio;
   }
   else if (_FgOrientation == 180) {
      pos *= float2 (PosX - CENTRE, CENTRE - PosY);
      S.x /= _OutputAspectRatio;
   }
   else if (_FgOrientation == 270) {
      pos *= float2 (PosY, PosX) - CENTRE;
      S.y /= _OutputAspectRatio;
   }
   else {
      pos *= float2 (CENTRE - PosX, PosY - CENTRE);
      S.x /= _OutputAspectRatio;
   }

   return pos - CENTRE;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (ArtDecoTransform)
{
   float scaleX = MasterScale * MasterScale;
   float scaleY = max (1.0e-6, scaleX * YScale * YScale);

   scaleX = max (1.0e-6, scaleX * XScale * XScale);

   float2 B_scale = abs (_FgExtents.xy - _FgExtents.zw);
   float2 Inner_LT, Inner_RB, xy = uv1 + fn_position (B_scale);

   xy /= float2 (scaleX, scaleY);
   xy += CENTRE;

   float2 uv = xy;

   float4 Fgnd, Crop = fn_crop (xy, Inner_LT, Inner_RB);

   float border  = max (Border_1, 1.0e-6);

   float gapFctr = BorderGap / border;
   float linFctr = Border_2 * 1.5 / border;
   float insFctr = InnerSpace / border;
   float inwFctr = InnerWidth / border;

   float2 BorderHV = B_scale * border * 0.025;
   float2 spaceHV  = BorderHV * gapFctr;
   float2 cropLT, cropRB;

   if (InRange (uv, Crop.xy, Crop.zw)) {
      cropLT = Crop.xy + BorderHV;
      cropRB = Crop.zw - BorderHV;

      Fgnd = InRange (uv, cropLT, cropRB) ? ReadPixel (Fg, uv) : float4 (Colour.rgb, 1.0);
   }
   else {
      cropLT = Crop.xy - spaceHV;
      cropRB = Crop.zw + spaceHV;

      if (InRange (uv, cropLT, cropRB)) {
         Fgnd = (GapFill == 2) ? float2 (0.0, 1.0).xxxy
              : (GapFill == 0) ? _TransparentBlack : ReadPixel (Fg, uv);
      }
      else {
         spaceHV = BorderHV * linFctr;
         cropLT -= spaceHV;
         cropRB += spaceHV;

         Fgnd = InRange (uv, cropLT, cropRB) ? float4 (Colour.rgb, 1.0) : _TransparentBlack;
      }
   }

   spaceHV = BorderHV * insFctr;
   cropLT  = Crop.xy + BorderHV + spaceHV;
   cropRB  = Crop.zw - BorderHV - spaceHV;

   spaceHV = BorderHV * inwFctr;

   Crop.xy = cropLT + spaceHV;
   Crop.zw = cropRB - spaceHV;

   if (!InRange (uv, Crop.xy, Crop.zw)) {

      if (InRange (uv, cropLT, cropRB)) {

         Crop.xy = cropRB - cropLT;
         Crop.zw = Crop.xy * Inner_RB;
         Crop.xy *= Inner_LT;
         Crop.xy += cropLT;
         Crop.zw = cropRB - Crop.zw;

         if (InRange (xy, 0.0.xx, Crop.xy) || InRange (xy, Crop.zw, 1.0.xx))
            Fgnd = float4 (Colour.rgb, 1.0);
      }
   }

   float4 Bgnd = lerp (_TransparentBlack, ReadPixel (Bg, uv2), Background);
   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a * Opacity);

   return lerp (Bgnd, retval, tex2D (Mask, uv3));
}
