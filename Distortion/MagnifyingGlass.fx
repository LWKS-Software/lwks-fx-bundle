// @Maintainer jwrl
// @Released 2025-11-04
// @Author schrauber
// @Author jwrl
// @Created 2017-01-05

/**
 This effect is similar in operation to the "Regional zoom" or "Bulge" effects, but
 instead of the non-linear distortion that those effects apply a linear zoom is performed.
 The zoomed area will always be centred on the middle of the masked area.

 Versions released after November 3 2025 have had several substantial changes made to
 them.  In this version of "Magnifying glass" those changes include:

   1.  The rectangular shape setting now defaults to a square rather than as previously,
       a rectangle with the same aspect ratio as the sequence.
   2.  The aspect ratio settings now range from -100% to +100%, where previously they
       ran from 0.1 to 10.0.  The same aspect ratio range as before is available with
       the new setting.
   3.  As a result of that change the setting no longer describes the actual ratio, so
       "Aspect ratio" is now called "Proportions".
   4.  Adjusting Proportions from 0% to -100% increases the shape width, thus changing
       the aspect ratio.  Similarly, adjusting Proportions between 0% and +100%
       increases the shape height.
   5.  Lightworks masking has been removed and replaced with a transparency switch.
       That changes the input background into a transparent layer for potential use in
       downstream blending operations.  Input opacity is preserved inside the shape.

 The settings now are:

   [*] Shape:  Selects between elliptical  or rectangular lens shape.
   [*] Zoom:  Sets the amount of zoom.
   [*] Glass size
      [*] Dimensions:  Adjusts the size of the mask shape.
      [*] Proportions:  Sets the aspect ratio of the mask shape.
   [*] Centre X:  Sets the horizontal position,
   [*] Centre Y:  Sets the vertical position,
   [*] Transparent bg:  Enables background transparency.

 NOTE:  This effect will break resolution independence.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MagnifyingGlass.fx
//
// Version history:
//
// Updated 2025-11-04 jwrl.
// Commented the code for clarity.
//
// Updated 2025-11-03 jwrl.
// Substantial changes have been made to this version of "Magnifying glass".  For full
// details, see the change list in the descriptive header, above.  Because of that jwrl
// is now described as the co-author.
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

DeclareIntParam   (SetTechnique, "Shape",          kNoGroup, 0, "Round or elliptical lens|Square or rectangular lens");
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

DeclareFloatParam (_InputWidth);
DeclareFloatParam (_InputHeight);
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

float2 initGeometry (out float2 uv, float2 xy)
{
   // Get the distance from xy to the centre of the shape and return it in uv.

   uv = float2 (Xcentre, 1.0 - Ycentre) - xy;

   // Calculate the amount that the horizontal and vertical mask size changes.
   // If it increases X is set to 1.0 and Y ranges from 1.0 to 0.1.  If it
   // reduces X ranges from 1.0 to 10.0 and Y is set to 1.0.

   xy    = float2 (0.0, abs (Proportions) * 9.0) + 1.0.xx;
   xy    = Proportions > 0.0 ? 1.0 / xy : xy.yx;
   xy.y /= _OutputAspectRatio;      // Correct Y by the aspect ratio.

   return xy;
}

float4 initBgd (sampler S, inout float2 uv, float2 xy)
{
   float4 retval = tex2D (S, uv);   // Load the unmodified input as the background

   // Since xy is already centred around the shape position, multiplying it by Zoom
   // will give a scaling offset for the input video address.  That can be simply
   // added to uv to give the final zoomed coordinates.

   uv += Zoom * xy;

   if (Transparent) retval.a = 0.0; // Make the background transparent if needed

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (MagnifyEllipse)
{
   // The initGeometry() function does a lot in a short space.  It gets the uv2 position
   // of the shape and returns it in xydist.  The horizontal and vertical mask sizes are
   // returned in xyprop.  The video address is used twice before finally being altered
   // by initBgd() for the zoom at the shader exit.

   float2 xydist, xy1 = uv1;
   float2 xyprop = initGeometry (xydist, xy1);

   // Calculate the mask radius, already corrected for aspect ratio in initGeometry().

   float radius = length (float2 (xydist.x / xyprop.x, xydist.y * xyprop.y));

   // Load Input as the background and update xy1 for the zoom using xydist.

   float4 Inp = initBgd (Input, xy1, xydist);

   // Check if the radius falls outside Dimensions and return Inp if so.  If not
   // return the zoomed image.

   return radius > Dimensions ? Inp : MirrorEdge (Input, xy1);
}

//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (MagnifyRectangle)
{
   float2 xydist, xy1 = uv1;
   float2 xyprop = initGeometry (xydist, xy1);

   // Invert the X sense of xyprop then use xyprop to set the range in rect.  This works
   // because if xyprop.x is unused it's set to 1.0.  Inverting 1.0 will give 1.0.

   xyprop.x = 1.0 / xyprop.x;

   float2 rect = abs (xydist) * xyprop;

   float4 Inp = initBgd (Input, xy1, xydist);

   // If Inp is inside the rectangular lens mask return the zoomed image.

   return any (rect > Dimensions) ? Inp : MirrorEdge (Input, xy1);
}
