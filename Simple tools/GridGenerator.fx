// @Maintainer jwrl
// @Released 2024-05-24
// @Author jwrl
// @Created 2024-04-27

/**
 This grid generator is probably most useful for aligning artwork and text.  The grid
 pattern can be adjusted from 8 to 32 lines across the image width, and the line weight
 can be adjusted for best visibility.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect GridGenerator.fx
//
// Version history:
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with float4 _TransparentBlack for Linux fix.
//
// Built 2024-04-27 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Grid generator", "Key", "Simple tools", "Useful for aligning artwork and text", "CanSize|HasMinOutputSize|HasMaxOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam (ShowGrid, "Grid display", kNoGroup, 3, "Add|Subtract|Difference|Opaque");

DeclareFloatParam (GridLines, "Squares across", kNoGroup, kNoFlags, 16.0, 8.0, 32.0);
DeclareFloatParam (GridWeight, "Line weight", kNoGroup, kNoFlags, 0.2, 0.0, 1.0);

DeclareBoolParam (DisableVideo, "Disable video", kNoGroup, false);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLACK   float2(0.0, 1.0).xxxy
#define WHITE   1.0.xxxx

#define SUBTRACT    1         // Subtract value used by showIt and showSafeArea
#define DIFFERENCE  2         // Difference value used by showIt and showSafeArea
#define OPAQUE      3         // Disabled value used by showIt

#define MAX_LINES   32        // Maximum number of horizontal crosshatch lines

#define LINE_SCALE  0.000926  // Line weight scale factor - arbitrarily chosen

float4 _TransparentBlack = 0.0.xxxx;

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fg)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (GridGenerator)
{
   float GridAmt, pixVal, xGrid, yGrid, Grid = 0.0;

   float4 retval, Video = tex2D (Fg, uv2);
   float4 Bgnd = DisableVideo ? BLACK : Video;

   // If the video is disabled we show black or white, depending on the grid polarity
   // Otherwise we get the background video and set the opacity values.

   if (DisableVideo) {
      Bgnd = (ShowGrid == SUBTRACT) ? WHITE : _TransparentBlack;
      GridAmt = 1.0;
    }
   else GridAmt = Opacity;

   // Now we calculate the grid overlay.  Only do this if opacity isn't zero and grid isn't disabled.

   if (GridAmt > 0.0) {

      // Calculate the horizontal and vertical line weights

      float Yval = ((GridWeight * 5.0) + 1.0) * LINE_SCALE;
      float Xval = Yval / _OutputAspectRatio;

      float xLines = ceil (GridLines);                // Get the integer value of the number of lines
      float xLine_increment = 1.0 / xLines;           // Calculate the percentage increment to achieve that
      float halfInc = xLine_increment / 2;            // Use this to offset lines so they stay centred

      bool oddLines = (fmod (xLines, 2.0) > 0.25);    // We set up this boolean here so we don't calculate it inside the loop

      for (int i = 0; i <= MAX_LINES; i++) {          // The loop executes a fixed amount to resolve a Windows compatibility issue.
         xGrid = xLine_increment * i;                 // The alternative would have been to build a unique Windows-specific version.

         if (oddLines) {                              // If there are an odd number of lines offset them by half the line spacing
            xGrid = saturate (xGrid - halfInc);
         }

         pixVal = abs (uv2.x - xGrid);                // This is really the first part of a compare operation

         if (pixVal < Xval) { Grid = 1.0; };          // If we fall inside the line width turn the pixel on

         // To get the y value we must allow for the aspect ratio.  This is a little complex because any scaling must be centred.

         yGrid = (xGrid - 0.5) * _OutputAspectRatio;
         yGrid = clamp ((yGrid + 0.5), 0.0, 1.0);

         // Repeat our line width boundary calculation from above.

         pixVal = abs (uv2.y - yGrid);

         if (pixVal < Yval) { Grid = 1.0; };
      }
   }

   // This overlays the actual grid, whether normal, add, subtract or difference

   if (ShowGrid == OPAQUE) { retval = lerp (Bgnd, Grid.xxxx, Grid * GridAmt); }
   else {
      float4 overlay = lerp (_TransparentBlack, Grid.xxxx, GridAmt);   // The level setting is applied at this point

      if (ShowGrid == DIFFERENCE) { retval = abs (Bgnd - overlay); }
      else retval = clamp (((ShowGrid == SUBTRACT) ? Bgnd - overlay : Bgnd + overlay), 0.0, 1.0);

      retval.a = max (Bgnd.a, overlay.a);
   }

   return lerp (Video, retval, tex2D (Mask, uv2).x);;
}
