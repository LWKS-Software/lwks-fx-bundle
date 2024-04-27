// @Maintainer jwrl
// @Released 2024-04-27
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

DeclareFloatParam (GridLines, "Grid size", kNoGroup, kNoFlags, 16.0, 8.0, 32.0);
DeclareFloatParam (GridWeight, "Line weight", kNoGroup, kNoFlags, 0.2, 0.0, 1.0);

DeclareBoolParam (DisableVideo, "Disable video", kNoGroup, false);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

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

#define GRID_SCALE  32.0      // Grid size scale factor - arbitrarily chosen
#define LINE_SCALE  1.0       // Line weight scale factor - arbitrarily chosen

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fg)
{ return ReadPixel (Input, uv1); }

DeclareEntryPoint (GridGenerator)
{
   float GridAmt, Grid;

   float4 retval, Video = tex2D (Fg, uv2);
   float4 Bgnd = DisableVideo ? BLACK : Video;

   // If the video is disabled we show black or white, depending on the grid polarity
   // Otherwise we get the background video and set the opacity values.

   if (DisableVideo) {
      Bgnd = (ShowGrid == SUBTRACT) ? WHITE : kTransparentBlack;
      GridAmt = 1.0;
    }
   else GridAmt = Opacity;

   // Now we calculate the grid overlay.  Only do this if uv2 is legal.

   if (IsOutOfBounds (uv2)) { Grid = 0.0; }
   else {
      float2 xy0 = abs (uv2 - 0.5.xx);
      float2 xy1 = (saturate (GridWeight) + 0.21875) * GridLines / 64.0;

      xy0.y /= _OutputAspectRatio;

      if (_OutputWidth < _OutputHeight) xy0 *= 0.5;

      float2 xy2 = frac ((xy0 * GridLines) + (xy1 / 2.0));

      Grid = (xy2.x < xy1.x) || (xy2.y < xy1.y) ? 1.0 : 0.0;
   }

   // This overlays the actual grid, whether normal, add, subtract or difference

   if (ShowGrid == OPAQUE) { retval = lerp (Bgnd, Grid.xxxx, Grid * GridAmt); }
   else {
      float4 overlay = lerp (kTransparentBlack, Grid.xxxx, GridAmt);   // The level setting is applied at this point

      if (ShowGrid == DIFFERENCE) { retval = abs (Bgnd - overlay); }
      else retval = clamp (((ShowGrid == SUBTRACT) ? Bgnd - overlay : Bgnd + overlay), 0.0, 1.0);

      retval.a = max (Bgnd.a, overlay.a);
   }

   return lerp (Video, retval, tex2D (Mask, uv2).x);;
}
