// @Maintainer jwrl
// @Released 2026-06-27
// @Author khaver
// @Created 2011-06-27

/**
 Originally called perspective, the current name of the effect better describes what
 it does.  It also avoids a conflict with another effect of the same name.  It's a
 neat, simple effect for skewing the image to add a perspective illusion to a flat
 plane.  With resolution independence, the image will only wrap to the boundaries
 of the undistorted image.  If the aspect ratio of the input video is such that it
 doesn't fill the frame, neither will the warped image.

   [*]Show grid:  Shows a grid of the distorted image.
   [*]Top left X:  Sets the distorted horizontal top left point of the image.
   [*]Top left Y:  Sets the distorted vertical top left point of the image.
   [*]Top right X:  Sets the distorted horizontal top right point of the image.
   [*]Top right Y:  Sets the distorted vertical top right point of the image.
   [*]Bottom left X:  Sets the distorted horizontal bottom left point of the image.
   [*]Bottom left Y:  Sets the distorted vertical bottom left point of the image.
   [*]Bottom right X:  Sets the distorted horizontal bottom right point of the image.
   [*]Bottom right Y:  Sets the distorted vertical bottom right point of the image.
   [*]Pan X:  Adjusts the horizontal position of the skewed image.
   [*]Pan Y:  Adjusts the vertical position of the skewed image.
   [*]Zoom:  Adjusts the size of the distorted image.

*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Skew.fx
//
// Version history:
//
// Updated 2026-06-27 jwrl.
// Masking now uses RGBA, not R or A.
// Added settings description to header text.
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with float4 _TransparentBlack for Linux fix.
// Replaced WHITE with float4 _OpaqueWhite.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-05-08 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Skew", "DVE", "Distortion", "A neat, simple effect for adding a perspective illusion to a flat plane", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters 
//-----------------------------------------------------------------------------------------//

DeclareBoolParam (showGrid, "Show grid",    kNoGroup, false);

DeclareFloatParam (TLX,     "Top left",     kNoGroup, "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (TLY,     "Top left",     kNoGroup, "SpecifiesPointY", 0.9, 0.0, 1.0);
DeclareFloatParam (TRX,     "Top right",    kNoGroup, "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (TRY,     "Top right",    kNoGroup, "SpecifiesPointY", 0.9, 0.0, 1.0);

DeclareFloatParam (BLX,     "Bottom left",  kNoGroup, "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (BLY,     "Bottom left",  kNoGroup, "SpecifiesPointY", 0.1, 0.0, 1.0);
DeclareFloatParam (BRX,     "Bottom right", kNoGroup, "SpecifiesPointX", 0.9, 0.0, 1.0);
DeclareFloatParam (BRY,     "Bottom right", kNoGroup, "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam (ORGX,    "Pan",          kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (ORGY,    "Pan",          kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (Zoom,    "Zoom",         kNoGroup, kNoFlags,          1.0, 0.0, 2.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

float4 _OpaqueWhite = 1.0.xxxx;
float4 _TransparentBlack = 0.0.xxxx;

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// This preamble pass means that we handle rotated video correctly.

DeclarePass (Input)
{ return ReadPixel (Inp, uv1); }

DeclareEntryPoint (Perspective)
{
   float x1 = lerp (0.1 - TLX, 1.9 - TRX, uv2.x);
   float x2 = lerp (0.1 - BLX, 1.9 - BRX, uv2.x);
   float y1 = lerp (TLY - 0.9, BLY + 0.9, uv2.y);
   float y2 = lerp (TRY - 0.9, BRY + 0.9, uv2.y);

   float2 xy;

   xy.x = lerp (x1, x2, uv2.y) + (0.5 - ORGX);
   xy.y = lerp (y1, y2, uv2.x) + (ORGY - 0.5);

   float2 zoomit = ((xy - 0.5.xx) / Zoom) + 0.5.xx;

   float4 color = ReadPixel (Input, zoomit);

   if (showGrid) {
      xy = frac (uv2 * 10.0);

      if (any (xy <= 0.02) || any (xy >= 0.98))
         color = _OpaqueWhite - color;
   }

   return lerp (_TransparentBlack, color, tex2D (Mask, uv2));
}
