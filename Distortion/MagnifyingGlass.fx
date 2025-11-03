// @Maintainer jwrl
// @Released 2025-11-03

// @Author schrauber
// @Author jwrl
// @Created 2017-01-05

/**
 This is similar in operation to the regional zoom effect, but instead of non-linear
 distortion a linear zoom is performed.  The zoomed area will always be centered on
 the centre of the masked area.  When Proportions is below zero the aspect ratio only
 affects the horizontal size, and affects the vertical size when it's above zero.  The
 settings are:

   [*] Shape:  Selects between elliptical  or rectangular lens shape.
   [*] Zoom:  Sets the amount of zoom.
   [*] Glass size
      [*] Dimensions:  Adjusts the size of the mask shape.
      [*] Proportions:  Sets the aspect ratio of the mask shape.
   [*] Centre X:  Sets the horizontal position,
   [*] Centre Y:  Sets the vertical position,
   [*] Transparent bg:  Enables background transparency.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MagnifyingGlass.fx
//
// Version history:
//
// Updated 2026-11-03 jwrl.
// Substantial changes have been made to this version of "Magnifying glass".  Because
// of that jwrl is now described as co-author.
// 1. The rectangular shape setting now defaults to a square shape rather than the
//    previous rectangle.
// 2. The aspect ratio settings now range from -100% to +100%, where previously they
//    ran from 0.1 to 10.0 and described the actual ratio.
// 3. Because of the above change, "Aspect ratio" is now called "Proportions".  The
//    same physical size change as before is applied when it's adjusted.
// 4. The proportion control affects the horizontal size when it's below zero, and the
//    vertical size when it's above zero.
// 5. Masking has been removed and replaced with a transparency switch.  That makes
//    the unmodified input a transparent background for potential downstream blends.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Magnifying glass", "DVE", "Distortion", "Similar in operation to a bulge effect but performs a flat linear zoom", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam   (SetTechnique, "Shape",          kNoGroup, 0, "Round or elliptical lens|Rectangular lens");

DeclareFloatParam (Zoom,         "Zoom",           kNoGroup,     kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Dimensions,   "Dimensions",     "Glass size", kNoFlags, 0.1,  0.0, 1.0);
DeclareFloatParam (Proportions,  "Proportions",    "Glass size", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (Xcentre,      "Centre",         kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Ycentre,      "Centre",         kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareBoolParam  (Transparent,  "Transparent bg", kNoGroup, false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

DeclareFloatParam (_OutputAspectRatio);

#define _TransparentBlack 0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 MirrorEdge (sampler S, float2 uv)
{
   float2 xy = 1.0.xx - abs (2.0 * (frac (uv / 2.0) - 0.5.xx));

   return tex2D (S, xy);
}

float2 initGeometry (inout float2 xy0)
{
   float2 xy1 = float2 (0.0, abs (Proportions) * 9.0) + 1.0.xx;
   float2 xy2 = Proportions > 0.0 ? 1.0 / xy1 : xy1.yx;

   xy0    = float2 (Xcentre, 1.0 - Ycentre) - xy0;
   xy2.y /= _OutputAspectRatio;

   return xy2;
}

float4 initBgd (sampler S, inout float2 uv, float2 xy)
{
   float4 retval = tex2D (S, uv);         // Load the unmodified input as the background

   if (Transparent) retval.a = 0.0;       // Make the background transparent if needed

   uv += Zoom * xy;                       // Set the zoomed range coordinates

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Ellipse)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (MagnifyEllipse)
{
   // The initGeometry() function does a lot in a short space.  It gets the distance
   // from the uv2 position to the centre of the Zoom and returns it in xydist.  The
   // xyprop value holds the amount that the horizontal and vertical mask size changes,
   // which is returned by the function itself.

   float2 xy1    = uv2;                   // Reference address
   float2 xydist = xy1;                   // xydist will become the centering position
   float2 xyprop = initGeometry (xydist); // xyprop is the proportion from 0.1 to 10.0

   // Calculate the mask radius, already corrected for aspect ratio in initGeometry().

   float radius = length (float2 (xydist.x / xyprop.x, xydist.y * xyprop.y));

   // Load Input as the background and update xy1 using xydist.

   float4 Inp = initBgd (Ellipse, xy1, xydist);

   // Check if the radius falls outside Dimensions and return Input if so.  If not return
   // the zoomed image.

   return radius > Dimensions ? Inp : MirrorEdge (Ellipse, xy1);
}

//-----------------------------------------------------------------------------------------//

DeclarePass (Rectangle)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (MagnifyRectangle)
{
   float2 xy1 = uv2, xydist = xy1;
   float2 xyprop = initGeometry (xydist);

   // Invert the X sense of xyprop then use xyprop to set the range in xy0

   xyprop.x = 1.0 / xyprop.x;          

   float2 xy0 = abs (xydist) * xyprop;

   float4 Inp = initBgd (Rectangle, xy1, xydist);

   // If Input is inside the rectangular lens mask return the zoomed image

   return any (xy0 > Dimensions) ? Inp : MirrorEdge (Rectangle, xy1);
}

