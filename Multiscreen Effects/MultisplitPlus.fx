// @Maintainer jwrl
// @Released 2026-06-18
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
       [*] Desaturate:  Dissolves video 1 to monochrome.
    [*] V2 settings.  Identical to V1 settings.
    [*] V3 settings.  Identical to V1 settings.
    [*] Border settings.
       [*] Position:  Trims border position horizontally.  This is a limited range
           adjustment, and is symmetrical when adjusting triple video parameters.
       [*] Width:  Sets the width of both borders.
       [*] Angle:  Sets the border angle.  The second border is the reciprocal of the
           first when using three video inputs.
       [*] Colour:  Sets the colour used by both borders.
    [*] Right border.
       [*] Settings:  In triple mode, allows the right border settings to be
           independently adjustable.  Otherwise they are the inverse of the left.
       [*] Position:  In triple video mode, if right border settings are enabled this
           adjusts the border position.  If not, the main border settings are used.
       [*] Width:  If right border settings are enabled in triple video mode, this
           becomes active.
       [*] Angle:  If right border settings are enabled in triple video mode, this
           becomes active.
       [*] Colour:  If right border settings are enabled in triple video mode, this
           becomes active.

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
// Modified 2026-06-18 jwrl.
// Changed "Monochrome" setting name in V1, V2 and V3 to "Desaturate".
//
// Modified 2026-05-18 jwrl.
// Added the ability to control the right wipe independently of the left.
//
// Modified 2026-03-20 jwrl.
// Reduced the border antialiassing.
//
// Modified 2026-03-19 jwrl.
// Added simple antialiassing to the border generation.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Multisplit plus", "DVE", "Multiscreen Effects", "Two and three way splits with angled dividers", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (V1, V2, V3);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (SetTechnique,    "Effect mode", kNoGroup, 0,      "V1 left, V2 right|V1 left, V2 centre, V3 right");

DeclareFloatParam (V1PosX,        "Position",   "V1 settings",     "SpecifiesPointX|DisplayAsPercentage", 0.0, -1.5, 1.5);
DeclareFloatParam (V1PosY,        "Position",   "V1 settings",     "SpecifiesPointY|DisplayAsPercentage", 0.0, -1.5, 1.5);
DeclareFloatParam (V1size,        "Size",       "V1 settings",     "DisplayAsPercentage", 1.0, 1.0, 5.0);
DeclareFloatParam (V1mono,        "Desaturate", "V1 settings",     kNoFlags,              0.0, 0.0, 1.0);

DeclareFloatParam (V2PosX,        "Position",   "V2 settings",     "SpecifiesPointX|DisplayAsPercentage", 0.0, -1.5, 1.5);
DeclareFloatParam (V2PosY,        "Position",   "V2 settings",     "SpecifiesPointY|DisplayAsPercentage", 0.0, -1.5, 1.5);
DeclareFloatParam (V2size,        "Size",       "V2 settings",     "DisplayAsPercentage", 1.0, 1.0, 5.0);
DeclareFloatParam (V2mono,        "Desaturate", "V2 settings",     kNoFlags,              0.0, 0.0, 1.0);

DeclareFloatParam (V3PosX,        "Position",   "V3 settings",     "SpecifiesPointX|DisplayAsPercentage", 0.0, -1.5, 1.5);
DeclareFloatParam (V3PosY,        "Position",   "V3 settings",     "SpecifiesPointY|DisplayAsPercentage", 0.0, -1.5, 1.5);
DeclareFloatParam (V3size,        "Size",       "V3 settings",     "DisplayAsPercentage", 1.0, 1.0, 5.0);
DeclareFloatParam (V3mono,        "Desaturate", "V3 settings",     kNoFlags,              0.0, 0.0, 1.0);

DeclareFloatParam  (BrdrPosn_1,   "Position",   "Border settings", "DisplayAsPercentage", 0.0,  -0.1, 0.1);
DeclareFloatParam  (BrdrWidth_1,  "Width",      "Border settings", "DisplayAsPercentage", 0.005, 0.0, 0.02);
DeclareFloatParam  (BrdrAngle_1,  "Angle",      "Border settings", kNoFlags, 0.0, -1.0, 1.0);
DeclareColourParam (BrdrColour_1, "Colour",     "Border settings", kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareIntParam    (AdjRight,     "Settings",   "Right border",    0, "Lock to main border|Adjust independently");
DeclareFloatParam  (BrdrPosn_2,   "Position",   "Right border",    "DisplayAsPercentage", 0.0,  -0.1, 0.1);
DeclareFloatParam  (BrdrWidth_2,  "Width",      "Right border",    "DisplayAsPercentage", 0.005, 0.0, 0.02);
DeclareFloatParam  (BrdrAngle_2,  "Angle",      "Right border",    kNoFlags, 0.0, -1.0, 1.0);
DeclareColourParam (BrdrColour_2, "Colour",     "Right border",    kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SLOPE (BrdrAngle_1 / 5.0)

#define _TransparentBlack 0.0.xxxx

#define LOOP    30         // The blur loop size used for antialiassing
#define DIVISOR 60.0       // The blur divisor is twice loop size because we offset twice
#define RADIUS  0.000625   // Blur sample radius
#define ANGLE   0.10472    // Six degrees expressed in radians.

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 mirror2D (sampler Mir, float2 xy)
{
   float2 uv = (0.5 - abs (abs (frac (xy / 2.0)) - 0.5.xx)) * 2.0;

   return tex2D (Mir, uv);
}

float4 getVideo (sampler V, float2 xy, float amount)
{
   float4 retval = tex2D (V, xy);

   float luma = dot (retval, float4 (0.25, 0.64, 0.11, 0.0));

   return float4 (lerp (retval.rgb, luma.xxx, amount), retval.a);
}

float4 Antialias (sampler Bdr, float2 uv, float wdth)
{
   float4 retval = _TransparentBlack;

   if (wdth > 0.0) {
      float4 Fgd = tex2D (Bdr, uv);

      float2 xy, radius = float2 (1.0, _OutputAspectRatio) * (1.0 + abs (wdth)) * RADIUS;

      float angle = 0.0;

      for (int i = 0; i < LOOP; i++) {
         sincos (angle, xy.x, xy.y);
         xy *= radius;
         retval += mirror2D (Bdr, uv + xy);
         retval += mirror2D (Bdr, uv - xy);
         angle  += ANGLE;
      }

      retval /= DIVISOR;
   }

   return retval;
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

   float2 xy = uv3 + float2 (0.25 - V1PosX - ((BrdrPosn_1 - (max (1.0e-6, BrdrWidth_1) / 2.0)) / 2.0), V1PosY);

   // Return the video mapped to sequence coordinates.

   return ReadPixel (F1, xy);
}

DeclarePass (Fg2)
{
   // F2 processing is essentially the same as F1 processing.

   float2 xy = uv3 - float2 (0.25 + V2PosX + ((BrdrPosn_1 + (max (1.0e-6, BrdrWidth_1) / 2.0)) / 2.0), -V2PosY);

   return ReadPixel (F2, xy);
}

DeclarePass (Bd0)
{
   // Calculate the border position and slope.

   float border = ((0.5 - uv3.y) * SLOPE) + BrdrPosn_1 + 0.5;
   float width  = max (1.0e-6, BrdrWidth_1);

   // If we're inside the border area, return the border colour.

   if ((uv3.x > border - width) && (uv3.x < border + width))
      return BrdrColour_1;

   // If the border test fails, return transparent black.

   return _TransparentBlack;
}

DeclareEntryPoint (DoubleSplit)
{
   // Calculate the border position and slope.

   float border = ((0.5 - uv3.y) * SLOPE) + BrdrPosn_1 + 0.5;

   // Recover the antialiassed border and the mixed V1 and V2

   float4 retbdr = Antialias (Bd0, uv3, max (1.0e-6, BrdrWidth_1));
   float4 retval = uv3.x < border ? tex2D (Fg1, uv3) : tex2D (Fg2, uv3);

   // Return the video halves with the border being produced by the border colour in
   // retbdr overlaid where retbdr is opaque.

   return lerp (retval, retbdr, retbdr.a);
}

//-----------------------------------------------------------------------------------------//

DeclarePass (Lft_1)
{
   // First set up the coordinates around zero and adjust the size.

   float2 xy = ((uv1 - 0.5.xx) / V1size) + 0.5.xx;

   // Return the video, converted to monochrome if needed.

   return getVideo (V1, xy, V1mono);
}

DeclarePass (Cen_1)
{
   // V2 processing is essentially the same as V1 processing.

   float2 xy = ((uv2 - 0.5.xx) / V2size) + 0.5.xx;

   return getVideo (V2, xy, V2mono);
}

DeclarePass (Rgt_1)
{
   // V3 processing is essentially the same as V1 processing.

   float2 xy = ((uv3 - 0.5.xx) / V3size) + 0.5.xx;

   return getVideo (V3, xy, V3mono);
}

DeclarePass (Left1)
{
   // First we adjust the position, allowing for the border position and width.

   float2 xy = uv4 + float2 (0.33333333 - V1PosX - ((BrdrPosn_1 - (max (1.0e-6, BrdrWidth_1) / 2.0)) / 2.0), V1PosY);

   // Return the video mapped to sequence coordinates.

   return ReadPixel (Lft_1, xy);
}

DeclarePass (Centre1)
{
   // Cen_1 processing does not need to allow for border position and width.

   float2 xy = uv4 - float2 (V2PosX, -V2PosY);

   return ReadPixel (Cen_1, xy);
}

DeclarePass (Right1)
{
   // First calculate the right position.  This is either the inverse of Lft_1
   // processing or can be independently adjusted.

   float position = AdjRight ? (BrdrPosn_2 - (max (1.0e-6, BrdrWidth_2) / 2.0)) / 2.0
                             : (BrdrPosn_1 - (max (1.0e-6, BrdrWidth_1) / 2.0)) / 2.0;

   // Rgt_1 processing is now returned.

   float2 xy = uv4 - float2 (0.33333333 + V3PosX - position, -V3PosY);

   return ReadPixel (Rgt_1, xy);
}

DeclarePass (Bd1)
{
   // Calculate the border position and angle.  Note that the angle of the
   // right border is by default the reciprocal of the left and its position
   // can be offset.  If AdjRight is set the right can be independently set
   // from the left.

   float border0 = ((uv4.y - 0.5) * SLOPE);
   float border1 = 0.33333333 - border0 + BrdrPosn_1;
   float border2 = 0.66666667;
   float brdr_width2, brdr_width1 = max (1.0e-6, BrdrWidth_1);

   float4 right_colour;

   if (AdjRight) {
      right_colour = BrdrColour_2;
      brdr_width2  = max (1.0e-6, BrdrWidth_2);
      border2     -= BrdrPosn_2 - ((uv4.y - 0.5) * (BrdrAngle_2 / 5.0));
   }
   else {
      right_colour = BrdrColour_1;
      brdr_width2  = brdr_width1;
      border2     -= BrdrPosn_1 - border0;
   }

   // If the pixel address falls inside either of the border areas return the
   // appropriate border colour.

   if ((uv4.x > border1 - brdr_width1) && (uv4.x < border1 + brdr_width1)) return BrdrColour_1;
   if ((uv4.x > border2 - brdr_width2) && (uv4.x < border2 + brdr_width2)) return right_colour;

   // If both the above fail, fall through to transparent black.

   return _TransparentBlack;
}

DeclareEntryPoint (TripleSplit)
{
   // Calculate the border position and angle.  Note that the angle of the
   // right border is by default the reciprocal of the left and its position
   // can be offset.  If AdjRight is set the right can be independently set
   // to the left.

   float border0 = ((uv4.y - 0.5) * SLOPE);
   float border1 = 0.33333333 - border0 + BrdrPosn_1;
   float border2 = 0.66666667;

   if (AdjRight) {
      border2 += ((uv4.y - 0.5) * (BrdrAngle_2 / 5.0)) - BrdrPosn_2;
   }
   else border2 += border0 - BrdrPosn_1;

   // Derive the the border width to use for left and right borders depending
   // on whether locked or independent border widths are chosen.

   float width = AdjRight && (uv4.x < (border1 + border2) / 2.0)
               ? max (1.0e-6, BrdrWidth_2) : max (1.0e-6, BrdrWidth_1);

   // Recover the antialiassed borders and the combined V1, V2 and V3.

   float4 retbdr = Antialias (Bd1, uv4, width);
   float4 retval;

   if (uv4.x < border1) { retval = tex2D (Left1, uv4); }
   else if (uv4.x < border2) { retval = tex2D (Centre1, uv4); }
   else retval = tex2D (Right1, uv4);

   // Return the three combined video segments with the appropriate border
   // colours in retbdr being shown where ever retbdr is opaque.

   return lerp (retval, retbdr, retbdr.a);
}
