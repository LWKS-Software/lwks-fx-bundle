// @Maintainer jwrl
// @Released 2026-09-14
// @Author ejvanderpoll
// @Created 2026-09-01

/**
 Spotmeter shows a moveable crosshair and the IRE measurements at that point, averaged
 and per colour.  The crosshair can be dragged on the screen with the mouse to assist
 with setup precision.  There are only five settings, and they are:

   [*]Meter display:  Switches the IRE meter display between top right and bottom
      right, the default position.
   [*]Selection crosshair
      [*]Position X:  Self explanatory.
      [*]Position Y:  Self explanatory.
      [*]Size:  Adjusts the crosshair size from very small to moderate.
   [*]Channel:  The four settings choose between the averaged RGB values of the current
      pixel, and the red, green or blue components.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Spotmeter.fx
//
// Version history
//
// Modified jwrl 2026-09-14.
// Added "Meter display" parameter.
// Added output aspect ratio adjustment to meter display scaling.
// General code tightening.
//
// Built ejvanderpoll (lwks1310599915) 2026-09-01
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Spotmeter", "User", "Technical", "Moveable IRE sampling spotmeter", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (mBox, "Meter display", kNoGroup, 0, "Bottom right|Top right");

DeclareFloatParam (flX,    "Position", "Selection crosshair", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (Yfl,    "Position", "Selection crosshair", "SpecifiesPointY", 0.5, 0.0, 1.0);
DeclareFloatParam (flSize, "Size",     "Selection crosshair", kNoFlags,          0.0, 0.0, 1.0);

DeclareIntParam (iChannel, "Channel",  kNoGroup, 0, "RGB|R|G|B");

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_InputWidth);
DeclareFloatParam (_InputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define CROSSHAIR_THICKNESS 0.002
#define CROSSHAIR_AVERAGE_WINDOW 2.0
#define CROSSHAIR_SCALE_FACTOR 0.05
#define CROSSHAIR_SCALE_OFFSET 0.01

// Definition of printable characters
// These are 7 segment characters, the segments numbered from 0 to 6 like this
//
//  0000
//  3  5
//  3  5
//  1111
//  4  6
//  4  6
//  2222
//
// The character decals are sets of 7 booleans, false if the segment is off, true if the segment is on
// There are 10 character defined, the numbers 0 to 9 and a space character
// The display has 3 digits which will be displayed as a black background with white characters

#define DIGIT_COUNT 3

#define CHR_0 0
#define CHR_1 1
#define CHR_2 2
#define CHR_3 3
#define CHR_4 4
#define CHR_5 5
#define CHR_6 6
#define CHR_7 7
#define CHR_8 8
#define CHR_9 9
#define CHR_COUNT 8

#define SEGMENT_COUNT 7

#define DIGIT_BORDER 0.01
#define DIGIT_WIDTH 0.04
#define DIGIT_HEIGHT 0.12
#define DIGIT_EXTENT (DIGIT_WIDTH + DIGIT_BORDER)

#define DIGIT1_OFFSET DIGIT_BORDER
#define DIGIT2_OFFSET (DIGIT1_OFFSET + DIGIT_EXTENT)
#define DIGIT3_OFFSET (DIGIT2_OFFSET + DIGIT_EXTENT)
#define DIGIT4_OFFSET (DIGIT3_OFFSET + DIGIT_EXTENT)

#define H_SEGMENT_SIZE (DIGIT_WIDTH / 8.0)
#define V_SEGMENT_SIZE (DIGIT_HEIGHT / 16.0)
#define V_SEGMENT_LENGTH ((DIGIT_HEIGHT - (3.0 * V_SEGMENT_SIZE)) / 2.0)
#define V_SEGMENT_1 (V_SEGMENT_SIZE + V_SEGMENT_LENGTH) 
#define V_SEGMENT_2 (V_SEGMENT_1 + V_SEGMENT_SIZE + V_SEGMENT_LENGTH) 

#define DISPLAY_X 0.85
#define DISPLAY_Y 0.85
#define DISPLAYuY 0.025

#define DISPLAY_WIDTH ((DIGIT_COUNT * (DIGIT_WIDTH + DIGIT_BORDER)) + DIGIT_BORDER)
#define DISPLAY_HEIGHT (DIGIT_HEIGHT + (2.0 * DIGIT_BORDER))

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool Segment (int iSegment, bool bSeg0, bool bSeg1, bool bSeg2,
              bool bSeg3, bool bSeg4, bool bSeg5, bool bSeg6)
{
   if (iSegment == 0) return bSeg0;
   if (iSegment == 1) return bSeg1;
   if (iSegment == 2) return bSeg2;
   if (iSegment == 3) return bSeg3;
   if (iSegment == 4) return bSeg4;
   if (iSegment == 5) return bSeg5;

   return bSeg6;
}

bool ChrSegment (int iChr, int iSegment)
{
   if (iChr == 0) return Segment (iSegment, true, false, true, true, true, true, true);
   if (iChr == 1) return Segment (iSegment, false, false, false, false, false, true, true);
   if (iChr == 2) return Segment (iSegment, true, true, true, false, true, true, false);
   if (iChr == 3) return Segment (iSegment, true, true, true, false, false, true, true);
   if (iChr == 4) return Segment (iSegment, false, true, false, true, false, true, true);
   if (iChr == 5) return Segment (iSegment, true, true, true, true, false, false, true);
   if (iChr == 6) return Segment (iSegment, true, true, true, true, true, false, true);
   if (iChr == 7) return Segment (iSegment, true, false, false, false, false, true, true);
   if (iChr == 8) return Segment (iSegment, true, true, true, true, true, true, true);
   if (iChr == 9) return Segment (iSegment, true, true, true, true, false, true, true);

   // Testing for 0 through 9 has failed, so we fall through
   // to the default of all segments off and return false.

   return false;
}

bool DisplayDigit (int iChr, float flXOffset, float flYOffset)
{
   if (flXOffset > DIGIT_WIDTH) { return false; }  // No digits to display here
   // segment 0
   if (flYOffset < V_SEGMENT_SIZE) { return ChrSegment(iChr, 0); }
   // segment 1
   if ((flYOffset > V_SEGMENT_1) && (flYOffset < (V_SEGMENT_1 + V_SEGMENT_SIZE))) {
      return ChrSegment(iChr, 1);
   }
   // segment 2
   if ((flYOffset > V_SEGMENT_2) && (flYOffset < (V_SEGMENT_2 + V_SEGMENT_SIZE))) {
      return ChrSegment(iChr, 2);
   }
   // segments 3 & 5
   if (flYOffset < V_SEGMENT_1) {
      // segment 3
      if (flXOffset < H_SEGMENT_SIZE) { return ChrSegment(iChr, 3); }
      // segment 5
      if (flXOffset > (DIGIT_WIDTH - H_SEGMENT_SIZE)) { return ChrSegment(iChr, 5); }
   }
   // segments 4 & 6
   else if (flYOffset < V_SEGMENT_2) {
      // segment 4
      if (flXOffset < H_SEGMENT_SIZE) { return ChrSegment(iChr, 4); }
      // segment 6
      if (flXOffset > (DIGIT_WIDTH - H_SEGMENT_SIZE)) { return ChrSegment(iChr, 6); }
   }

   return false;
}

bool Crosshair (float x, float y)
{
   float flY = 1.0 - Yfl;
   float Ythickness = _OutputAspectRatio * CROSSHAIR_THICKNESS;

   if ((x > (flX - CROSSHAIR_THICKNESS)) && (x < (flX + CROSSHAIR_THICKNESS))) {
      return true;      // display crosshair
   }
   if ((y > (flY - Ythickness)) && (y < (flY + Ythickness))) {
      return true;      // display crosshair
   }

   return false;
}

bool IsWhite (float flXOffset, float flYOffset, float4 ire)
{
   if ((flXOffset < DIGIT_BORDER) ||
       (flYOffset < DIGIT_BORDER) || (flYOffset > (DISPLAY_HEIGHT - DIGIT_BORDER))) {
      return false;
   }

   if (flXOffset < DIGIT2_OFFSET) {
      if (DisplayDigit((int)(ire.r * 10.0), flXOffset - DIGIT1_OFFSET, flYOffset - DIGIT_BORDER)) {
         return true;
      }
   }
   else if (flXOffset < DIGIT3_OFFSET) {
      if (DisplayDigit((int)(ire.g * 10.0), flXOffset - DIGIT2_OFFSET, flYOffset - DIGIT_BORDER)) {
         return true;
      }
   }
   else if (flXOffset < DIGIT4_OFFSET) {
      if (DisplayDigit((int)(ire.b * 10.0), flXOffset - DIGIT3_OFFSET, flYOffset - DIGIT_BORDER)) {
         return true;
      }
   }

   return false;   
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (phAcquire)
{
   float flY = 1.0 - Yfl;     // Inverts the Y position to match Lightworks parameters.

   // Xsize and Ysize are two new parameters to allow precentage display of size while
   // limiting the range.  Ysize also compensates for the output aspect ratio.

   float Xsize = (flSize * CROSSHAIR_SCALE_FACTOR) + CROSSHAIR_SCALE_OFFSET;
   float Ysize = Xsize * _OutputAspectRatio;

   if ((uv1.x <= (1.0 / _InputWidth)) && (uv1.y <= (1.0 / _InputHeight))) {
      // calculate IRE and store the result in this pixel
      float2 offset;

      float4 incolor;
      float4 outcolor;

      int iIRE;

      float flTotalR = 0.0;
      float flTotalG = 0.0;
      float flTotalB = 0.0;
      float flCount  = 1.0;

      offset.x = flX;
      offset.y = flY;
      incolor = ReadPixel(Input, offset);

      flTotalR += incolor.r;
      flTotalG += incolor.g;
      flTotalB += incolor.b;

      // at minimum size we only calculate IRE for one pixel, else we calculate for 9 pixels,
      // spread out over the region defined by Xsize

      if (Xsize > 0.015) {

         offset.x = flX - Xsize;

         for (int i = 0; i < 3; i++) {
            offset.y = flY - Ysize;

            for (int j = 0; j < 3; j++) {
               incolor = ReadPixel (Input, offset);

               flTotalR += incolor.r;
               flTotalG += incolor.g;
               flTotalB += incolor.b;

               offset.y += Ysize;
            }

            offset.x += Xsize;
         }

         flCount = 9.0;
      }

      if (iChannel == 0) {
         iIRE = (int)(((flTotalR + flTotalG + flTotalB) / (flCount * 3.0)) * 100.0);
      }
      else if (iChannel == 1) {
         iIRE = (int)((flTotalR / flCount) * 100.0);
      }
      else if (iChannel == 2) {
         iIRE = (int)((flTotalG / flCount) * 100.0);
      }
      else if (iChannel == 3) {
         iIRE = (int)((flTotalB / flCount) * 100.0);
      }

      if (iIRE < 0) {
         iIRE = 0;
      }
      if (iIRE > 100) {
         iIRE = 100;
      }

      outcolor.r = (float)(iIRE / 100);

      if (outcolor.r == 0.0) {
         outcolor.r = 10.0;
      }
      outcolor.r /= 10.0;
      outcolor.r += 0.025;

      iIRE %= 100;

      outcolor.g = (float)(iIRE / 10);
      if ((outcolor.r == 1.025) && (outcolor.g == 0.0)) {
         outcolor.g = 10.0;
      }

      outcolor.g /= 10.0;
      outcolor.g += 0.025;

      iIRE %= 10;

      outcolor.b = (float)iIRE;
      outcolor.b /= 10.0;
      outcolor.b += 0.025;

      outcolor.a = 1.0;

      return outcolor;
   }

   return kTransparentBlack;
}

DeclareEntryPoint (Spotmeter)
{
   float4 incolor = tex2D(Input, uv1);
   float4 outcolor = incolor;

   if (IsOutOfBounds(uv1)) {
      return kTransparentBlack;
   }

   float flY = 1.0 - Yfl;     // Inverts the Y position to match Lightworks parameters.
   float Ydisplay = mBox ? DISPLAYuY : DISPLAY_Y;     // Switches the IRE display between top and bottom right.

   // Xsize and Ysize are two new parameters to allow precentage display of size while
   // limiting the range.  Ysize also compensates for the output aspect ratio.

   float Xsize = (flSize * CROSSHAIR_SCALE_FACTOR) + CROSSHAIR_SCALE_OFFSET;
   float Ysize = Xsize * _OutputAspectRatio;

   if ((uv1.x > (flX - Xsize)) && (uv1.x < (flX + Xsize)) && (uv1.y > (flY - Ysize)) && (uv1.y < (flY + Ysize))) {
      // we're in the crosshair
      if (Crosshair(uv1.x, uv1.y)) {
         // This is an attempt to make the crosshairs visible over any background including
         // black.  It seems to work, but I'm sure it could be simplified and improved on.

         float3 retval = ((abs (incolor.rgb - 1.0.xxx) - 0.5.xxx) * 2.0) + 0.5.xxx;

         retval = saturate (max (retval.r, max (retval.g, retval.b)).xxx);

         return float4 (retval, 1.0);
      }
   }
   else if ((uv1.x > DISPLAY_X) && (uv1.x < (DISPLAY_X + DISPLAY_WIDTH)) && (uv1.y > Ydisplay) && (uv1.y < (Ydisplay + DISPLAY_HEIGHT))) {
      // we're in the display area
      float2 offset;
      offset.x = 0.0;
      offset.y = 0.0;
      float4 ire = tex2D(phAcquire, offset);

      if (IsWhite(uv1.x - DISPLAY_X, uv1.y - Ydisplay, ire)) {
         outcolor.r = 1.0;
         outcolor.g = 1.0;
         outcolor.b = 1.0;
      }
      else {
         return kTransparentBlack;
      }
   }

   return outcolor;
}
