// @Maintainer jwrl
// @Released 2026-09.10
// @Author jwrl
// @Created 2026-09.10

/**
 This is a replacement for the now withdrawn Lightworks Transform (2D DVE) effect.
 It performs the same way as that did, except that there is a difference in the
 way that the drop shadow is produced.  Instead of being derived from the cropped
 edges of the frame as it was in the Lightworks effect the cropped foreground
 alpha channel is used.  This means that the drop shadow will appear where it
 should and not just at the edge of frame, as it did with the Lightworks effect.

   [*]Position X:  Sets the horizontal position of the foreground.
   [*]Position Y:  Sets the verical position of the foreground.
   [*]Opacity:  Adjusts the foreground opacity to fade it in or out.
   [*]Scaling
      [*]Master:  The master scaling.  Self explanatory.
      [*]X:  Horizontal scaling.
      [*]Y:  Vertical scaling.
   [*]Crop
      [*]Left:  Crops the left side of the foreground.
      [*]Top:  Self explanatory.
      [*]Right:  Self explanatory.
      [*]Bottom:  Self explanatory.
   [*]Shadow
      [*]Reduction:  Sets the drop shadow transparency.
      [*]X Offset:  Sets the horizontal offset of the drop shadow.
      [*]Y Offset:  Sets the vertical offset of the drop shadow.
   [*]Invert Y direction:  Changes the direction of operation of the
      Y position and Y offset paramters.

 Lightworks masking is included, and as the drop shadow does with crops, the mask
 is displaced on the drop shadow to match the foreground masking.  The drop shadow
 has another difference from the original Transform effect.  In the drop shadow
 settings instead of "Transparency" you will find "Reduction".  This has been done
 because LW 2026.1 cut the last letter of "Transparency".  The name is different,
 but the function is the same.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ClassicTransform.fx
//
// Version history:
//
// Built jwrl 2026-09.10.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Classic transform", "DVE", "Transform plus", "A replacement for the 2D DVE / 2D Transform effect.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Xpos,        "X position", kNoGroup,  "DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (Ypos,        "Y position", kNoGroup,  "DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (Opacity,     "Opacity",    kNoGroup,  kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (MasterScale, "Master",     "Scaling", kNoFlags, 1.0, 0.0, 10.0);
DeclareFloatParam (XScale,      "X",          "Scaling", kNoFlags, 1.0, 0.0, 10.0);
DeclareFloatParam (YScale,      "Y",          "Scaling", kNoFlags, 1.0, 0.0, 10.0);

DeclareFloatParam (CropL,       "Left",       "Crop",    kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (CropT,       "Top",        "Crop",    kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (CropR,       "Right",      "Crop",    kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (CropB,       "Bottom",     "Crop",    kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (Reduction,   "Reduction",  "Shadow",  kNoFlags, 0.75, 0.0, 1.0);
DeclareFloatParam (ShadeX,      "X offset",   "Shadow",  kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (ShadeY,      "Y offset",   "Shadow",  kNoFlags, 0.0, -1.0, 1.0);

DeclareBoolParam  (InvertY,     "Invert Y direction",    kNoGroup, true);

DeclareIntParam   (_FgOrientation);
DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define _TransparentBlack   0.0.xxxx
#define _ShadowOffsetScale  0.2

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
// Perform the cropping ahead of anything else so as to not impact the rest of the effect.
{
   float4 crop = float4 (CropL, CropT, 1.0 - CropR, 1.0 - CropB);

   if (_FgOrientation == 90) {
      crop = crop.wxyz;
      crop.xz = 1.0 - crop.xz;
   }
   else if (_FgOrientation == 180) {
      crop = 1.0 - crop.zwxy;
   }
   else if (_FgOrientation == 270) {
      crop = crop.yzwx;
      crop.wy = 1.0 - crop.wy;
   }

   return (uv1.x >= crop.x) && (uv1.x <= crop.z) && (uv1.y <= crop.w) && (uv1.y >= crop.y)
        ? ReadPixel (Fg, uv1) : _TransparentBlack;
}

DeclarePass (Bgd)
// Map the background to sequence coordinates.
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (ClassicTransform)
{
   // First we recover the raw scale factors.

   float xScale = max (1e-6, MasterScale * XScale);
   float yScale = max (1e-6, MasterScale * YScale);
   float xShade = ShadeX * _ShadowOffsetScale;
   float yShade = ShadeY * _ShadowOffsetScale;

   // Now we adjust the foreground position (xy1) and from that calculate the
   // drop shadow offset and put that in xy2.  The values of both are centred
   // around the screen midpoint.

   float2 xy1, xy2, xy3 = uv3;

   if (InvertY) {
      xy1 = uv3 + float2 (0.5 - Xpos, Ypos - 0.5);
      xy2 = xy1 - float2 (xShade, yShade);
   }
   else {
      xy1 = uv3 + float2 (0.5 - Xpos, 0.5 - Ypos);
      xy2 = xy1 - float2 (xShade, -yShade);
   }

   // Now we perform the scaling of the foreground coordinates, allowing for
   // the aspect ratio.  The drop shadow offset is scaled to match the
   // foreground scaling.

   xy1.x = (xy1.x - 0.5) * _OutputAspectRatio / xScale;
   xy1.y = (xy1.y - 0.5) / yScale;
   xy2.x = lerp (xy1.x, (xy2.x - 0.5) * _OutputAspectRatio / xScale, xScale);
   xy2.y = lerp (xy1.y, (xy2.y - 0.5) / yScale, yScale);

   // Aspect ratio adjustment and centring is now removed for xy1 and xy2.

   xy1.x /= _OutputAspectRatio;
   xy2.x /= _OutputAspectRatio;
   xy3   -= xy1 - xy2;

   xy1 += 0.5.xx;
   xy2 += 0.5.xx;

   // Recover the background, foreground and raw drop shadow data.

   float4 Fgnd = ReadPixel (Fgd, xy1);
   float4 Bgnd = ReadPixel (Bgd, uv3);
   float4 sMsk = ReadPixel (Mask, xy3);

   // The drop shadow is derived from the foreground alpha, which is first
   // masked using the RGB channels of sMsk.  It is then adjusted in level
   // using the inverse of the Reduction.

   float ShadowMask = max (sMsk.r, max (sMsk.g, sMsk.b));

   ShadowMask *= ReadPixel (Fgd, xy2).a;
   ShadowMask *= 1.0 - Reduction;

   // The drop shadow is laid over the background.  The masked foreground is
   // then added to it and the opacity is controlled by mixing the result
   // over the clean background.

   float4 retval = lerp (Bgnd, _TransparentBlack, ShadowMask);

   retval.a = Bgnd.a;
   retval   = lerp (retval, Fgnd, tex2D (Mask, uv3) * Fgnd.a);

   return lerp (Bgnd, retval, Opacity);
}

