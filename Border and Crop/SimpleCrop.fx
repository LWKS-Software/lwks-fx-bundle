// @Maintainer jwrl
// @Released 2023-04-16
// @Author jwrl
// @Created 2017-03-23

/**
 This is a quick simple cropping tool.  You can also use it to blend images without
 using a blend effect.  It provides a simple border and if the foreground is smaller
 than the crop area the overflow is filled with the border colour.  With its extended
 alpha support you can also use it to crop and overlay two images with alpha channels
 over another background using an external blend effect.

 Previously the "sense" of the effect could have been swapped so that background
 became foreground and vice versa.  With the ability to cycle inputs built in to
 Lightworks there's little point in doing that, and it has been dropped.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SimpleCrop.fx
//
// Version history:
//
// Updated 2024-04-16 jwrl.
// Performed some code cleanup and added full comments.
//
// Updated 2023-06-20 jwrl.
// Added masking.
//
// Updated 2023-05-15 jwrl.
// Header reformatted.
//
// Conversion 2023-02-17 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Simple crop", "DVE", "Border and Crop", "A simple crop tool with blend", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (CropLeft, "Top left", kNoGroup, "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (CropTop, "Top left", kNoGroup, "SpecifiesPointY", 0.9, 0.0, 1.0);
DeclareFloatParam (CropRight, "Bottom right", kNoGroup, "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (CropBottom, "Bottom right", kNoGroup, "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareIntParam (AlphaMode, "Alpha channel output", kNoGroup, 3, "Ignore alpha|Background only|Cropped foreground|Combined alpha|Overlaid alpha");

DeclareFloatParam (Border, "Thickness", "Border", kNoFlags, 0.1, 0.0, 1.0);

DeclareColourParam (Colour, "Colour", "Border", kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// Rather than the transparent black outside the Fg frame boundaries that ReadPixel()
// returns, we want opaque black.  The pass below does that while also mapping Fg to
// the sequence coordinates.

DeclarePass (Fgd)
{ return IsOutOfBounds (uv1) ? float4 (0.0.xxx, 1.0) : tex2D (Fg, uv1); }

DeclareEntryPoint (SimpleCrop)
{
   // The border width is calculated first, allowing for the aspect ratio.

   float2 brdrEdge = float2 (1.0, _OutputAspectRatio) * Border * 0.05;

   // Now the crops are set up as float2 values, with the Y coordinates inverted because
   // Lightworks effects expect 0 to be at the top, while the shaders put it at the bottom.
   // Cropping is set up this way so that the user can crop by dragging the diagonally
   // opposite corner pins of the foreground image.  The border is then added outside the
   // crop boundaries.

   float2 cropTL = float2 (CropLeft, 1.0 - CropTop);
   float2 cropBR = float2 (CropRight, 1.0 - CropBottom);
   float2 bordTL = saturate (cropTL - brdrEdge);
   float2 bordBR = saturate (cropBR + brdrEdge);

   // The foreground and background are now recovered, using sequence coordinates for
   // the remapped foreground.  If "Overlaid alpha" is chosen the background is blanked.

   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = AlphaMode == 4 ? kTransparentBlack : ReadPixel (Bg, uv2);

   // The foreground is cropped by first applying the border colour to the area outside
   // the crop boundaries, then blanking the area outside the border boundaries.

   if ((uv3.x < cropTL.x) || (uv3.y < cropTL.y)
    || (uv3.x > cropBR.x) || (uv3.y > cropBR.y)) { Fgnd = Colour; }

   if ((uv3.x < bordTL.x) || (uv3.y < bordTL.y)
    || (uv3.x > bordBR.x) || (uv3.y > bordBR.y)) { Fgnd = kTransparentBlack; }

   // The cropped and bordered foreground is composited over the background.  The alpha
   // value chosen in "Alpha channel output" is then applied.

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a);

   retval.a = (AlphaMode == 0) ? 1.0
            : (AlphaMode == 1) ? Bgnd.a
            : (AlphaMode == 2) ? Fgnd.a : max (Bgnd.a, Fgnd.a);

   // Finally the composited result is masked over the background and returned.

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x);
}
