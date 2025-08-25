// @Maintainer jwrl
// @Released 2025-08-25
// @Author jwrl
// @Created 2024-04-27

/**
 This is an updated version of the original grid generator, and is probably most useful
 for aligning artwork and text.  The grid pattern can be adjusted from 8 to 32 lines
 across the longest image dimension, and the line weight can be adjusted for best
 visibility.  However there have been some changes since this effect was first released.

   * Opacity:  Self explanatory.  Fades the grid in or out of the video input.
   * Grid display:  Selects between add, subtract, difference and opaque (normal)
     blend modes.
   * Maximum lines:  Sets the maximum number of lines that will be displayed.
   * Line weight:  Sets the thickoess of the lines in the grid.
   * Disable video:  Shows the grid over black.

 The most obvious change is that there is no longer a setting called "Squares across".
 Its place has been taken by the "Maximum lines" parameter, which behaves somewhat
 differently to that earlier control.  In square and landscape format sequences its
 behaviour is unchanged.  It still sets the number of squares visible across the screen
 width.  However with portrait formats the number of squares across the screen height
 is adjusted.  This makes more sense: in the older version setting a maximum of 32 was
 set, in portrait mode, vertically that gave 37 lines vertically, which is absurd.

 "Line weight" has also been modified slightly.  It's no longer possible to set the line
 width to nothing.  The zero setting now sets a small number of pixels, so except for
 extremely small formats there should always be lines visible.  The upper size has also
 been slightly reduced.  The earlier version allowed excessive line thickness that could
 obliterate the background video entirely.  Finally, this effect automatically works
 with rotated media, and stays within sequence bounds.

 The behaviour of "Disable video" has also been changed.  When this is activated all
 output processing except for masking has now been disabled.  The grid is simply shown
 as white on black.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect GridGenerator.fx
//
// Version history:
//
// Updated 2025-08-25 jwrl.
// Corrected a geometry bug affecting rotated media.
// Rewrote main code to remove the need for variable length for-next loops.
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with float4 _TransparentBlack for Linux fix.
//
// Built 2024-04-27 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Grid generator", "Key", "Simple tools", "Useful for aligning artwork and text", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity,  "Opacity",       kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam   (GridMode, "Grid display",  kNoGroup, 3, "Add|Subtract|Difference|Opaque");

DeclareFloatParam (MaxLines, "Maximum lines", kNoGroup, kNoFlags, 16.0, 8.0, 32.0);
DeclareFloatParam (Lweight,  "Line weight",   kNoGroup, kNoFlags, 0.2, 0.0, 1.0);

DeclareBoolParam  (Disable,  "Disable video", kNoGroup, false);

DeclareFloatParam (_OutputAspectRatio);

DeclareIntParam (_InputOrientation);

DeclareFloat4Param (_InputExtents);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define ADD      0
#define SUBTRACT 1
#define DIFFRNCE 2
#define OPAQUE   3

#define BLACK    float2(0.0, 1.0).xxxy
#define WHITE      1.0.xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 Hline (float4 video, float v, float pos, float thickness, float blend)
{
   // To calculate the position of the horizontal guide we only need the y coordinate.
   // Since y values in Lightworks have 0 at the top of frame and HLSL / GLSL place
   // it at the bottom the position must be inverted by subtracting it from 1.0.

   float position = /* 1.0 - */ pos;

   // Now we calculate the boundaries by adding and subtracting the line thickness.

   float Abounds = position - thickness;
   float Bbounds = position + thickness;

   // If the Y position is inside the boundaries we can now blend the line over the video.

   if ((v > Abounds) && (v < Bbounds)) {
      video = blend == ADD ? saturate (video + WHITE) :
              blend == DIFFRNCE ? abs (video - WHITE) :
              blend == SUBTRACT ? saturate (video - WHITE) : WHITE;

      // Regardless of the blend mode used, alpha is turned fully on.  This ensures that
      // even if we blend this effect with something else the guide will still show.

      video.a = 1.0;
   }

   return video;
}

float4 Vline (float4 video, float u, float position, float thickness, float blend)
{
   float Abounds = position - thickness;
   float Bbounds = position + thickness;

   if ((u > Abounds) && (u < Bbounds)) {
      video = blend == ADD ? saturate (video + WHITE) :
              blend == DIFFRNCE ? abs (video - WHITE) :
              blend == SUBTRACT ? saturate (video - WHITE) : WHITE;
      video.a = 1.0;
   }

   return video;
}

float4 Hgroup (float pos0, float pos1, float pos2, float pos3,
               float width, float4 video, float2 xy, float b)
{
   float4 retval;

   if (IsOutOfBounds (pos0)) { retval = video; }
   else {
      retval = Hline (video, xy.y, pos0, width, b);

      if (!IsOutOfBounds (pos1)) {
         retval = Hline (retval, xy.y, pos1, width, b);

         if (!IsOutOfBounds (pos2)) {
            retval = Hline (retval, xy.y, pos2, width, b);

            if (!IsOutOfBounds (pos3)) retval = Hline (retval, xy.y, pos3, width, b);
         }
      }
   }

   return retval;
}

float4 Vgroup (float pos0, float pos1, float pos2, float pos3,
               float width, float4 video, float2 xy, float b)
{
   float4 retval;

   if (IsOutOfBounds (pos0)) { retval = video; }
   else {
      retval = Vline (video, xy.x, pos0, width, b);

      if (!IsOutOfBounds (pos1)) {
         retval = Vline (retval, xy.x, pos1, width, b);

         if (!IsOutOfBounds (pos2)) {
            retval = Vline (retval, xy.x, pos2, width, b);

            if (!IsOutOfBounds (pos3)) retval = Vline (retval, xy.x, pos3, width, b);
         }
      }
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (GridGenerator)
{
   float lineNum = floor (MaxLines + 0.25);
   float Hweight = ((Lweight * 4.5) + 0.5) * 0.0025;
   float Vweight =  Hweight;
   float Hlines, Vlines;

   // Start by calculating the number of H and V line amounts and their line weights,
   // allowing for the sequence aspect ratio.

   if (_OutputAspectRatio > 1.0) {
      Hlines = lineNum / _OutputAspectRatio;
      Vlines = lineNum;
      Hweight *= _OutputAspectRatio;
   }
   else {
      Hlines = lineNum;
      Vlines = lineNum * _OutputAspectRatio;
      Vweight /= _OutputAspectRatio;
   }

   float Hpos = 1.0 / Hlines;
   float Vpos = 1.0 / Vlines;

   float Hline0 = Hpos;
   float Hline1 = Hline0 + Hpos;
   float Hline2 = Hline1 + Hpos;
   float Hline3 = Hline2 + Hpos;

   float Vline0 = Vpos;
   float Vline1 = Vline0 + Vpos;
   float Vline2 = Vline1 + Vpos;
   float Vline3 = Vline2 + Vpos;

   Hpos *= 4.0;
   Vpos *= 4.0;

   // Recover the video input and set up the line blend variable in retval.

   float4 video;

   float amount;

   int blend;

   if (Disable) {
      video  = BLACK;
      amount = 1.0;
      blend  = OPAQUE;
   }
   else {
      video  = ReadPixel (Input, uv1);
      amount = Opacity;
      blend  = GridMode;
   }

   float2 uv = (_InputOrientation != 0) ? uv1
             : float2 ((uv1.x - _InputExtents.x) / (_InputExtents.z - _InputExtents.x),
                       (uv1.y - _InputExtents.y) / (_InputExtents.w - _InputExtents.y));

   float4 retval = video;

   for (int i = 0; i < 9; i++) {
      retval = Hgroup (Hline0, Hline1, Hline2, Hline3, Hweight, retval, uv, blend);
      retval = Vgroup (Vline0, Vline1, Vline2, Vline3, Vweight, retval, uv, blend);

      Hline0 += Hpos;
      Hline1 += Hpos;
      Hline2 += Hpos;
      Hline3 += Hpos;

      Vline0 += Vpos;
      Vline1 += Vpos;
      Vline2 += Vpos;
      Vline3 += Vpos;
   }

   // Finally mix back the lines over the original video and quit.

   return lerp (video, retval, amount * tex2D (Mask, uv1).x);;
}
