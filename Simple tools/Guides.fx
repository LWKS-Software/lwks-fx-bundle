// @Maintainer jwrl
// @Released 2025-08-25
// @Author jwrl
// @Created 2025-08-17

/**
 This is just a simple guide line generator which can display up to four horizontal
 and four vertical lines.  It will handle both portrait and landscape format media at
 any resolution supported by Lightworks.  It also has a rule of thirds grid generator
 built in.  See the settings below for further details.

   * Opacity:  Fades all lines in or out.
   * Line weight:  Sets the thickness of the displayed lines.
   * Rule of thirds:  Enables or disables rule of thirds display.  The default is off.
   * Guide blending:  Selects between add, subtract or difference blend modes.  The
     default blend mode is difference.
   * Horizontal
      * Show guide 1:  Enables or disables horizontal guide line 1 display.  The default
        is on.
      * Guide 1:  Sets the vertical  position of horizontal guide line 1.
      * Show guide 2:  As for show guide 1 except that the default is off.
      * Guide 2:  As for guide 1.
      * Show guide 3:  As for show guide 2.
      * Guide 3:  As for guide 2.
      * Show guide 4:  As for show guide 3.
      * Guide 4:  As for guide 3.
   * Vertical
      * Show guide 1:  Enables or disables vertical guide line 1 display.  The default
        is on.
      * Guide 1:  Sets the horizontal position of vertical guide line 1.
      * Show guide 2:  As for show guide 1 except that the default is off.
      * Guide 2:  As for guide 1.
      * Show guide 3:  As for show guide 2.
      * Guide 3:  As for guide 2.
      * Show guide 4:  As for show guide 3.
      * Guide 4:  As for guide 3.

 This effect works with rotated media, and works within sequence bounds.  It is NOT
 designed to lock the guides to the input media size and aspect ratio.

 The effect is suitable for use with LW versions above 2022.1, but is unlikely to
 compile on earlier versions.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Guides.fx
//
// Version history:
//
// Updated 2025-08-25 jwrl.
// Corrected a geometry bug affecting rotated media.
//
// Built 2025-08-17 by jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Guides", "Key", "Simple tools", "Displays up to four horizontal guides and four vertical", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity,   "Opacity",        kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Lweight,   "Line weight",    kNoGroup, kNoFlags, 0.2, 0.0, 1.0);

DeclareBoolParam  (Rule3rds,  "Rule of thirds", kNoGroup, false);

DeclareIntParam   (BlendMode, "Guide blending", kNoGroup, 2, "Add|Subtract|Difference");

DeclareBoolParam  (Show_H0, "Show guide 1", "Horizontal", true);
DeclareFloatParam (Hguide0, "Guide 1",      "Horizontal", kNoFlags, 0.5,  0.0, 1.0);
DeclareBoolParam  (Show_H1, "Show guide 2", "Horizontal", false);
DeclareFloatParam (Hguide1, "Guide 2",      "Horizontal", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam  (Show_H2, "Show guide 3", "Horizontal", false);
DeclareFloatParam (Hguide2, "Guide 3",      "Horizontal", kNoFlags, 0.75, 0.0, 1.0);
DeclareBoolParam  (Show_H3, "Show guide 4", "Horizontal", false);
DeclareFloatParam (Hguide3, "Guide 4",      "Horizontal", kNoFlags, 0.95, 0.0, 1.0);

DeclareBoolParam  (Show_V0, "Show guide 1", "Vertical", true);
DeclareFloatParam (Vguide0, "Guide 1",      "Vertical", kNoFlags, 0.5,  0.0, 1.0);
DeclareBoolParam  (Show_V1, "Show guide 2", "Vertical", false);
DeclareFloatParam (Vguide1, "Guide 2",      "Vertical", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam  (Show_V2, "Show guide 3", "Vertical", false);
DeclareFloatParam (Vguide2, "Guide 3",      "Vertical", kNoFlags, 0.75, 0.0, 1.0);
DeclareBoolParam  (Show_V3, "Show guide 4", "Vertical", false);
DeclareFloatParam (Vguide3, "Guide 4",      "Vertical", kNoFlags, 0.05, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareIntParam (_InpOrientation);

DeclareFloat4Param (_InpExtents);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

// Index values for subtract and difference settings as used by BlendMode

#define SUBTRACT 1
#define DIFFRNCE 2

#define WHITE    1.0.xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 setPos (float P0, float P1, float P2, float P3,
               bool bP0, bool bP1, bool bP2, bool bP3)
{
   float sP0 = bP0 ? saturate (P0) : -1.0;
   float sP1 = bP1 ? saturate (P1) : -1.0;
   float sP2 = bP2 ? saturate (P2) : -1.0;
   float sP3 = bP3 ? saturate (P3) : -1.0;

   return float4 (sP1, sP2, sP3, sP0);
}

float4 Hline (float4 video, float2 uv, float pos, float thickness)
{
   if (IsOutOfBounds (pos)) return video;

   // To calculate the position of the horizontal guide we only need the y coordinate.
   // Since y values in Lightworks have 0 at the top of frame and HLSL / GLSL place
   // it at the bottom the position must be inverted by subtracting it from 1.0.

   float position = 1.0 - pos;

   // First remap the Y coords to sequence space if there's 0 degree orientation.

   if (_InpOrientation == 0)
      uv.y = (uv.y - _InpExtents.y) / (_InpExtents.w - _InpExtents.y);

   // Now we calculate the boundaries by adding and subtracting the line thickness.

   float Abounds = position - thickness;
   float Bbounds = position + thickness;

   // If the Y position is inside the boundaries we can now blend the line over the video.

   if ((uv.y > Abounds) && (uv.y < Bbounds)) {
      video = BlendMode == DIFFRNCE ? abs (video - WHITE) :
              BlendMode == SUBTRACT ? saturate (video - WHITE) : saturate (video + WHITE);

      // Regardless of the blend mode used, alpha is turned fully on.  This ensures that
      // even if we blend this effect with something else the guide will still show.

      video.a = 1.0;
   }

   return video;
}

float4 Vline (float4 video, float2 uv, float position, float thickness)
{
   if (IsOutOfBounds (position)) return video;

   // X coordinates don't need inversion so this process is as shown in Hline() after
   // the position inversion.  First remap the X coords to sequence space if there's
   // 0 degree orientation.

   if (_InpOrientation == 0)
      uv.x = (uv.x - _InpExtents.x) / (_InpExtents.z - _InpExtents.x);

   float Abounds = position - thickness;
   float Bbounds = position + thickness;

   if ((uv.x > Abounds) && (uv.x < Bbounds)) {
      video = BlendMode == DIFFRNCE ? abs (video - WHITE) :
              BlendMode == SUBTRACT ? saturate (video - WHITE) : saturate (video + WHITE);

      video.a = 1.0;
   }

   return video;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (RefLine)
{
   // Start by calculating the H and V guide line weights, allowing for the aspect ratio.

   float Hweight = ((Lweight * 4.5) + 0.5) * 0.001;
   float Vweight;

   // Next take care of any rotation.  90 degree and 270 degree rotation means that the
   // X and Y position coordinates must be swapped, and X must be inverted by subtracting
   // it from 1.0.  The line weights must also be adjusted to match.

   float4 Xguide, Yguide;

   if ((_InpOrientation == 0) || (_InpOrientation == 180)) {
      Vweight = Hweight;
      Hweight *= _OutputAspectRatio;
      Xguide = setPos (Hguide0, Hguide1, Hguide2, Hguide3,
                       Show_H0, Show_H1, Show_H2, Show_H3);
      Yguide = setPos (Vguide0, Vguide1, Vguide2, Vguide3,
                       Show_V0, Show_V1, Show_V2, Show_V3);
   }
   else {
      Vweight = Hweight * _OutputAspectRatio;
      Xguide = 1.0.xxxx - setPos (Vguide0, Vguide1, Vguide2, Vguide3,
                                  Show_V0, Show_V1, Show_V2, Show_V3);
      Yguide = setPos (Hguide0, Hguide1, Hguide2, Hguide3,
                       Show_H0, Show_H1, Show_H2, Show_H3);
   }

   // If the rotation is greater than 90 degrees both positions must be further inverted.

   if (_InpOrientation > 90) {
      Xguide = 1.0.xxxx - Xguide;
      Yguide = 1.0.xxxx - Yguide;
   }

   // Recover the video input and set up the guide blend variable in retval.

   float4 Input  = ReadPixel (Inp, uv1);
   float4 retval = Input;

   // If we want to display the rule of thirds grid we do that first.  Since it doesn't
   // matter if the position coordinates are rotated we only need correct line weights.

   if (Rule3rds) {
      retval =  Hline (Input,  uv1, 0.33333333, Hweight);
      retval =  Hline (retval, uv1, 0.66666667, Hweight);
      retval =  Vline (retval, uv1, 0.33333333, Vweight);
      retval =  Vline (retval, uv1, 0.66666667, Vweight);
   }

   // Now do the four horizontal guides then the four verticals.  The float4 suffixes
   // are actually in the order xyzw, but for readability I have run them in alphabetic
   // order both here and in setPos ().  Order really doesn't matter in this context.

   retval = Hline (retval, uv1, Xguide.w, Hweight);
   retval = Hline (retval, uv1, Xguide.x, Hweight);
   retval = Hline (retval, uv1, Xguide.y, Hweight);
   retval = Hline (retval, uv1, Xguide.z, Hweight);

   retval = Vline (retval, uv1, Yguide.w, Vweight);
   retval = Vline (retval, uv1, Yguide.x, Vweight);
   retval = Vline (retval, uv1, Yguide.y, Vweight);
   retval = Vline (retval, uv1, Yguide.z, Vweight);

   // Finally mix back the guides over the original video and quit.

   return lerp (Input, retval, Opacity);
}
