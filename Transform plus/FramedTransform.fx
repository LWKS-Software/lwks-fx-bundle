// @Maintainer jwrl
// @Released 2025-09-15
// @Author jwrl
// @Created 2018-11-14

/**
 This is a combination of two transform effects designed to provide a drop shadow and
 vignette effect while matching Lightworks' transform parameters.  Because of the way
 that the transforms are produced they have exactly the same quality impact on the
 final result as a single transform effect would.

   [*] Opacity:  Self explanatory.
   [*] Transform
      [*] Scale:  Adjusts the scale of the beveled foreground video.
      [*] Z angle:  Rotates the beveled  foreground.
      [*] X position:  Moves the beveled  foreground horizontally.
      [*] Y position:  Moves the beveled  foreground vertically.
   [*] Crop upper left X:  Crops the left of the beveled foreground.
   [*] Crop upper left Y:  Crops the top of the beveled foreground.
   [*] Crop lower right:  Crops the right of the beveled foreground.
   [*] Crop lower right:  Crops the bottom of the beveled foreground.
   [*] Video insert
      [*] Scale:  Scales the foreground inside the bevel.
      [*] X position:  Adjusts the foreground horizontally inside the bevel.
      [*] Y position:  Adjusts the foreground vertically inside the bevel.
   [*] Border
      [*] Border width:  Adjusts the border size including the bevel.
      [*] Bevel width:  Adjusts the bevel width without changing the overall
          border size.
      [*] Bevel sharpness:  Reducing the bevel sharpness increases the apparent
          roundness.
      [*] Outer brightness:  Adjusts the brightness of the outer bevel edge.
      [*] Inner brightness:  Adjusts the brightness of the inner bevel edge.
      [*] Texture scale:  Scales the texture used by the border.
      [*] Texture X:  Adjusts the horizontal position of the texture inside
          the border.
      [*] Texture Y:  Adjusts the vertical position of the texture inside the
          border.
   [*] Shadow
      [*] Opacity:  Adjusts the opacity of the shadow.
      [*] Softness:  Softens the shadow's edge.
      [*] Angle:  Adjusts the angle of the light throwing the shadow:
      [*] Offset:  Adjusts the shadow displacement.
      [*] Distance:  Adjusts the apparent distance of the shadow.  This has the
          effect of reducing the shadow size and changing its displacement.

 The main transform adjusts the foreground, crop, frame and drop shadow.  When the
 foreground is cropped it can be given a beveled textured border.  The bevel can be
 feathered, as can the drop shadow.  The second transform adjusts the size and position
 of the foreground inside the frame.

 Lightworks' masking has also been included. There is actually a third transform of sorts
 that adjusts the size and offset of the border texture.  This is extremely rudimentary
 though. 

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FramedTransform.fx
//
// Version history:
//
// Updated 2025-09-15 jwrl.
// Changed Width to Border width.
// Changed Bevel to Bevel width.
// Changed Outer edge to Outer brightness.
// Changed Inner edge to Inner brightness.
// Changed the crop settings to something much more sensible.  The crop order still
// sucks, but that's inevitable if we want to be able to drag cropping.
//
// Updated 2023-06-24 jwrl.
// Changed foreground autocrop to masking.
//
// Updated 2023-06-19 jwrl.
// Changed DVE references to transform.
// Changed title from "Framed DVE" to "Framed transform"
// Changed subcategory from "DVE Extras" to "Transform plus".
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-02-17 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Framed transform", "DVE", "Transform plus", "Creates a textured frame around the foreground image and resizes and positions the result.", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg, Tx);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (DVE_Scale,   "Scale",      "Transform", kNoFlags, 1.0,    0.0,  10.0);
DeclareFloatParam (DVE_Z_angle, "Z angle",    "Transform", kNoFlags, 0.0, -360.0, 360.0);
DeclareFloatParam (DVE_PosX,    "X position", "Transform", kNoFlags, 0.0,   -1.0,   1.0);
DeclareFloatParam (DVE_PosY,    "Y position", "Transform", kNoFlags, 0.0,   -1.0,   1.0);

DeclareFloatParam (TLcropX, "Crop upper left",  kNoGroup, "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (TLcropY, "Crop upper left",  kNoGroup, "SpecifiesPointY", 0.9, 0.0, 1.0);
DeclareFloatParam (BRcropX, "Crop lower right", kNoGroup, "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (BRcropY, "Crop lower right", kNoGroup, "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam (VideoScale, "Scale",      "Video insert", kNoFlags, 1.0,  0.0, 10.0);
DeclareFloatParam (VideoPosX,  "X position", "Video insert", kNoFlags, 0.0, -1.0,  1.0);
DeclareFloatParam (VideoPosY,  "Y position", "Video insert", kNoFlags, 0.0, -1.0,  1.0);

DeclareFloatParam (BorderWidth,    "Border width",     "Border", kNoFlags,  0.4,  0.0, 1.0);
DeclareFloatParam (BevelWidth,     "Bevel width",      "Border", kNoFlags,  0.4,  0.0, 1.0);
DeclareFloatParam (BevelSharpness, "Bevel sharpness",  "Border", kNoFlags,  0.2,  0.0, 1.0);
DeclareFloatParam (BevelOuter,     "Outer brightness", "Border", kNoFlags,  0.6, -1.0, 1.0);
DeclareFloatParam (BevelInner,     "Inner brightness", "Border", kNoFlags, -0.4, -1.0, 1.0);
DeclareFloatParam (TextureScale,   "Texture scale",    "Border", kNoFlags,  1.0,  0.5, 2.0);
DeclareFloatParam (TextureX,       "Texture X",        "Border", kNoFlags,  0.0, -1.0, 1.0);
DeclareFloatParam (TextureY,       "Texture Y",        "Border", kNoFlags,  0.0, -1.0, 1.0);

DeclareFloatParam (ShadowOpacity,  "Opacity",  "Shadow", kNoFlags,  0.75,   0.0,   1.0);
DeclareFloatParam (ShadowSoft,     "Softness", "Shadow", kNoFlags,  0.2,    0.0,   1.0);
DeclareFloatParam (ShadowAngle,    "Angle",    "Shadow", kNoFlags, 45.0, -180.0, 180.0);
DeclareFloatParam (ShadowOffset,   "Offset",   "Shadow", kNoFlags,  0.5,    0.0,   1.0);
DeclareFloatParam (ShadowDistance, "Distance", "Shadow", kNoFlags,  0.0,    0.0,   1.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_OutputWidth);

DeclareIntParam (_FgOrientation);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BadPos(P, p1, p2) (P < max (0.0, p1)) || (P > min (1.0, 1.0 - p2))
#define CropXY(XY, L, R, T, B)  (BadPos (XY.x, L, -R) || BadPos (XY.y, -T, B))

#define BLACK float2(0.0, 1.0).xxxy

#define BdrPixel(SHADER,XY) (IsOutOfBounds(XY) ? BLACK : tex2D(SHADER, XY))
#define GetMirror(SHD,UV,XY) (any (abs (XY - 0.5.xx) > 0.5) \
                             ? kTransparentBlack \
                             : tex2D (SHD, saturate (1.0.xx - abs (1.0.xx - abs (UV)))))

// Definitions used by this shader

#define HALF_PI      1.5707963268
#define PI           3.1415926536

#define BEVEL_SCALE  0.04
#define BORDER_SCALE 0.05

#define SHADOW_DEPTH 0.1
#define SHADOW_SOFT  0.05

#define CENTRE       0.5.xx

#define WHITE        1.0.xxxx

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Texture)
{ return GetMirror (Tx, uv3, uv3); }

DeclarePass (CropMask)
{
/* Returned values: crop.w - master crop 
                    crop.x - master border (inside crop) 
                    crop.y - border shading
                    crop.z - drop shadow
*/
   float cropX = TLcropX < BRcropX ? TLcropX : BRcropX;
   float cropY = TLcropY > BRcropY ? TLcropY : BRcropY;

   float2 aspect = float2 (1.0, _OutputAspectRatio);
   float2 offset = aspect / _OutputWidth;
   float2 xyCrop = float2 (cropX, 1.0 - cropY);
   float2 ccCrop = (xyCrop + float2 (BRcropX, 1.0 - BRcropY)) * 0.5;
   float2 uvCrop = abs (uv4 - ccCrop);

   xyCrop = abs (xyCrop - ccCrop);

   float2 border = max (0.0.xx, xyCrop - (aspect * BorderWidth * BORDER_SCALE));
   float2 edge_0 = aspect * BorderWidth * BevelWidth * BEVEL_SCALE;
   float2 edge_1 = max (0.0.xx, border + edge_0);

   edge_0 = max (0.0.xx, xyCrop - edge_0);
   edge_0 = (smoothstep (edge_0, xyCrop, uvCrop) + smoothstep (border, edge_1, uvCrop)) - 1.0.xx;
   edge_0 = (clamp (edge_0 * (1.0 + (BevelSharpness * 9.0)), -1.0.xx, 1.0.xx) * 0.5) + 0.5.xx;
   edge_1 = max (0.0.xx, xyCrop - (aspect * ShadowSoft * SHADOW_SOFT));
   edge_1 = smoothstep (edge_1, xyCrop, uvCrop);

   float4 crop = smoothstep (xyCrop - offset, xyCrop + offset, uvCrop).xyxy;

   crop.xy = smoothstep (border - offset, border + offset, uvCrop);
   crop.w = 1.0 - max (crop.w, crop.z);
   crop.x = 1.0 - max (crop.x, crop.y);
   crop.y = max (edge_0.x, edge_0.y);
   crop.z = (1.0 - edge_1.x) * (1.0 - edge_1.y);

   return crop;
}

DeclareEntryPoint (FramedTransform)
{
   float temp, ShadowX, ShadowY, scale = DVE_Scale < 0.0001 ? 10000.0 : 1.0 / DVE_Scale;

   sincos (radians (ShadowAngle), ShadowY, ShadowX);

   float2 xy0, xy1 = (uv4 - CENTRE) * scale;
   float2 xy2 = float2 (ShadowX, ShadowY * _OutputAspectRatio) * ShadowOffset * SHADOW_DEPTH;
   float2 xy3;

   sincos (radians (DVE_Z_angle), xy0.x, xy0.y);
   temp = (xy0.y * xy1.y) - (xy0.x * xy1.x * _OutputAspectRatio);
   xy1  = float2 ((xy0.x * xy1.y / _OutputAspectRatio) + (xy0.y * xy1.x), temp);

   xy1 += CENTRE - (float2 (DVE_PosX, -DVE_PosY) * 2.0);
   xy3  = xy1;

   float shadow = ShadowDistance * 0.3333333333;

   xy2 += float2 (1.0, 1.0 / _OutputAspectRatio) * shadow * xy2 / max (xy2.x, xy2.y);
   temp = (xy0.y * xy2.y) - (xy0.x * xy2.x * _OutputAspectRatio);
   xy2  = float2 ((xy0.x * xy2.y / _OutputAspectRatio) + (xy0.y * xy2.x), temp);
   xy2  = ((xy1 - xy2 - CENTRE) * (shadow + 1.0) / ((ShadowSoft * 0.05) + 1.0)) + CENTRE;

   float4 MaskIt = ReadPixel (CropMask, xy3);

   MaskIt.z = IsOutOfBounds (xy2) ? 0.0 : tex2D (CropMask, xy2).z;

   scale = VideoScale < 0.0001 ? 10000.0 : 1.0 / VideoScale;
   xy1   = (CENTRE + ((xy1 - CENTRE) * scale)) - (float2 (VideoPosX, -VideoPosY) * 2.0);
   scale = TextureScale < 0.0001 ? 10000.0 : 1.0 / TextureScale;
   xy3   = (CENTRE + ((xy3 - CENTRE) * scale)) - (float2 (TextureX, -TextureY) * 2.0);

   float4 Fgnd = BdrPixel (Fgd, xy1);
   float4 Bgnd = ReadPixel (Bg, uv2);
   float4 frame = GetMirror (Texture, xy3, uv4);
   float4 retval = lerp (Bgnd, BLACK, MaskIt.z * ShadowOpacity);

   float alpha_O = ((2.0 * MaskIt.y) - 1.0);
   float alpha_I = max (0.0, -alpha_O) * abs (BevelInner);

   alpha_O = max (0.0, alpha_O) * abs (BevelOuter);
   frame = BevelOuter > 0.0 ? lerp (frame, WHITE, alpha_O) : lerp (frame, BLACK, alpha_O);
   frame = BevelInner > 0.0 ? lerp (frame, WHITE, alpha_I) : lerp (frame, BLACK, alpha_I);
   retval = lerp (retval, frame, MaskIt.w);
   retval = lerp (retval, Fgnd, MaskIt.x);

   return lerp (Bgnd, retval, tex2D (Mask, uv4).x * Opacity);
}
