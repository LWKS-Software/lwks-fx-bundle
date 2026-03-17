// @Maintainer jwrl
// @Released 2026-03-17
// @Author jwrl
// @Created 2026-03-17

/**
 This is an effect that does two and three-way splits - with a difference.  The border
 between the two or three panels can be angled and coloured.  Unlike Lightworks wipe
 borders, these borders are a single flat colour.  They are also hard edged.  Where
 two borders are required for the three way split the same colour and thickness is
 used for both.

 The two way split uses V1 for the left panel and V2 for the right.  Input V3 is not
 used, and neither is border 2.  All parameter settings for V3 are also ignored.  The
 three way split uses V1 for the left panel, V2 for the centre and V3 for the right.
 In both modes video in all panels can be independently rendered as monochrome if so
 desired.  The software settings are:

    [*] Effect mode:  Selects between two or three video sources.
    [*] V1 settings.
       [*] Position X:  Sets the horizontal position of the video 1 input.
       [*] Position Y:  Sets the vertical position of the video 1 input.
       [*] Size:  Increases the size of the video 1 input.
       [*] Monochrome:  Dissolves video 1 to monochrome.
    [*] V2 settings.
       [*] Position X:  As for video 1.
       [*] Position Y:  As for video 1.
       [*] Size:  As for video 1.
       [*] Monochrome:  As for video 1.
    [*] V3 settings.
       [*] Position X:  As for video 1.
       [*] Position Y:  As for video 1.
       [*] Size:  As for video 1.
       [*] Monochrome:  As for video 1.
    [*] Border settings.
       [*] Position:  Trims border position horizontally.  This is a limited range
           adjustment, and is symmetrical when adjusting triple video parameters.
       [*] Width:  Sets the width of both borders.
       [*] Angle:  Sets the border angle.  The second border is the reciprocal of the
           first when using three video inputs.
       [*] Colour:  Sets the colour used by both borders.

 Each input video defaults to the centre of its panel but can also be independently
 horizontally and vertically positioned.  No frame overshoot protection is provided.
 This means that each input can be positioned so that it falls completely outside
 its panel and is thus completely invisible.  A limited zoom range is available for
 each input.

 NOTE:  There is no masking provided in this effect.  Given the nature of what it's
 designed to do, masking would be rather pointless.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect MultisplitPlus.fx
//
// Version history:
//
// Built 2026-03-17 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Multisplit plus", "DVE", "Multiscreen Effects", "Two and three way splits with angled dividers", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (V1, V2, V3);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique, "Effect mode", kNoGroup, 0, "V1 left, V2 right|V1 left, V2 centre, V3 right");

DeclareFloatParam (V1PosX, "Position",   "V1 settings", "SpecifiesPointX|DisplayAsPercentage", 0.0, -1.5, 1.5);
DeclareFloatParam (V1PosY, "Position",   "V1 settings", "SpecifiesPointY|DisplayAsPercentage", 0.0, -1.5, 1.5);
DeclareFloatParam (V1size, "Size",       "V1 settings", "DisplayAsPercentage", 1.0, 1.0, 5.0);
DeclareFloatParam (V1mono, "Monochrome", "V1 settings", kNoFlags,              0.0, 0.0, 1.0);

DeclareFloatParam (V2PosX, "Position",   "V2 settings", "SpecifiesPointX|DisplayAsPercentage", 0.0, -1.5, 1.5);
DeclareFloatParam (V2PosY, "Position",   "V2 settings", "SpecifiesPointY|DisplayAsPercentage", 0.0, -1.5, 1.5);
DeclareFloatParam (V2size, "Size",       "V2 settings", "DisplayAsPercentage", 1.0, 1.0, 5.0);
DeclareFloatParam (V2mono, "Monochrome", "V2 settings", kNoFlags,              0.0, 0.0, 1.0);

DeclareFloatParam (V3PosX, "Position",   "V3 settings", "SpecifiesPointX|DisplayAsPercentage", 0.0, -1.5, 1.5);
DeclareFloatParam (V3PosY, "Position",   "V3 settings", "SpecifiesPointY|DisplayAsPercentage", 0.0, -1.5, 1.5);
DeclareFloatParam (V3size, "Size",       "V3 settings", "DisplayAsPercentage", 1.0, 1.0, 5.0);
DeclareFloatParam (V3mono, "Monochrome", "V3 settings", kNoFlags,              0.0, 0.0, 1.0);

DeclareFloatParam  (BorderPosn,   "Position", "Border settings", "DisplayAsPercentage", 0.0,  -0.1, 0.1);
DeclareFloatParam  (BorderWidth,  "Width",    "Border settings", "DisplayAsPercentage", 0.005, 0.0, 0.02);
DeclareFloatParam  (BorderAngle,  "Angle",    "Border settings", kNoFlags, 0.0, -1.0, 1.0);
DeclareColourParam (BorderColour, "Colour",   "Border settings", kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SLOPE (BorderAngle / 5.0)

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 getVideo (sampler V, float2 xy, float amount)
{
   float4 retval = tex2D (V, xy);

   float luma = dot (retval, float4 (0.25, 0.64, 0.11, 0.0));

   return float4 (lerp (retval.rgb, luma.xxx, amount), retval.a);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (F1)
{
   // First set up the coordinates around zero and adjust the size.

   float2 xy = ((uv1 - 0.5.xx) / V1size) + 0.5.xx;

   // Return the video, converted to monochrome if needed.

   return getVideo (V1, xy, V1mono);
}

DeclarePass (F2)
{
   // V2 processing is essentially the same as V1 processing.

   float2 xy = ((uv2 - 0.5.xx) / V2size) + 0.5.xx;

   return getVideo (V2, xy, V2mono);
}

DeclarePass (Fg1)
{
   // Adjust the position, allowing for the border position and width.

   float2 xy = uv3 + float2 (0.25 - V1PosX - ((BorderPosn - (BorderWidth / 2.0)) / 2.0), V1PosY);

   // Return the video mapped to sequence coordinates.

   return ReadPixel (F1, xy);
}

DeclarePass (Fg2)
{
   // F2 processing is essentially the same as F1 processing.

   float2 xy = uv3 - float2 (0.25 + V2PosX + ((BorderPosn + (BorderWidth / 2.0)) / 2.0), -V2PosY);

   return ReadPixel (F2, xy);
}

DeclareEntryPoint (DoubleSplit)
{
   // Calculate the border position and slope.

   float border = ((0.5 - uv3.y) * SLOPE) + BorderPosn + 0.5;

   // If we're inside the border area, return the border colour.

   if ((uv3.x > border - BorderWidth) && (uv3.x < border + BorderWidth))
      return BorderColour;

   // Otherwise return the video halves.

   return uv3.x < border ? tex2D (Fg1, uv3) : tex2D (Fg2, uv3);
}

//-----------------------------------------------------------------------------------------//

DeclarePass (Lft)
{
   // First set up the coordinates around zero and adjust the size.

   float2 xy = ((uv1 - 0.5.xx) / V1size) + 0.5.xx;

   // Return the video, converted to monochrome if needed.

   return getVideo (V1, xy, V1mono);
}

DeclarePass (Cen)
{
   // V2 processing is essentially the same as V1 processing.

   float2 xy = ((uv2 - 0.5.xx) / V2size) + 0.5.xx;

   return getVideo (V2, xy, V2mono);
}

DeclarePass (Rgt)
{
   // V3 processing is essentially the same as V1 processing.

   float2 xy = ((uv3 - 0.5.xx) / V3size) + 0.5.xx;

   return getVideo (V3, xy, V3mono);
}

DeclarePass (Left)
{
   // First we adjust the position, allowing for the border position and width.

   float2 xy = uv4 + float2 (0.33333333 - V1PosX - ((BorderPosn - (BorderWidth / 2.0)) / 2.0), V1PosY);

   // Return the video mapped to sequence coordinates.

   return ReadPixel (Lft, xy);
}

DeclarePass (Centre)
{
   // Cen processing does not need to allow for border position and width.

   float2 xy = uv4 - float2 (V2PosX, -V2PosY);

   return ReadPixel (Cen, xy);
}

DeclarePass (Right)
{
   // Rgt processing is essentially the inverse of Lft processing.

   float2 xy = uv4 - float2 (0.33333333 + V3PosX - ((BorderPosn - (BorderWidth / 2.0)) / 2.0), -V3PosY);

   return ReadPixel (Rgt, xy);
}

DeclareEntryPoint (TripleSplit)
{
   // Calculate the border position and angle.  Note that the right border is the
   // reciprocal of the left.

   float border0 = ((uv4.y - 0.5) * SLOPE) - BorderPosn;
   float border1 = 0.33333333 - border0;
   float border2 = 0.66666667 + border0;

   // If the pixel address falls inside either of the border areas return the
   // border colour.

   if (((uv4.x > border1 - BorderWidth) && (uv4.x < border1 + BorderWidth))  ||
       ((uv4.x > border2 - BorderWidth) && (uv4.x < border2 + BorderWidth)))
      return BorderColour;

   // Otherwise return the three video components.

   return uv4.x < border1 ? tex2D (Left, uv4) :
          uv4.x < border2 ? tex2D (Centre, uv4) : tex2D (Right, uv4);
}

