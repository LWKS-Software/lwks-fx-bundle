// @Maintainer jwrl
// @Released 2025-08-17
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

 It's suitable for use with LW versions over 2022.1, but is unlikely to compile on any
 earlier versions.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Guides.fx
//
// Version history:
//
// Built 2025-08-17 by jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Guides", "Key", "Simple tools", "Displays up to four horizontal guides and four vertical", CanSize);

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

DeclareBoolParam  (Show_H1, "Show guide 1", "Horizontal", true);
DeclareFloatParam (Hguide1, "Guide 1",      "Horizontal", kNoFlags, 0.5,  0.0, 1.0);
DeclareBoolParam  (Show_H2, "Show guide 2", "Horizontal", false);
DeclareFloatParam (Hguide2, "Guide 2",      "Horizontal", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam  (Show_H3, "Show guide 3", "Horizontal", false);
DeclareFloatParam (Hguide3, "Guide 3",      "Horizontal", kNoFlags, 0.75, 0.0, 1.0);
DeclareBoolParam  (Show_H4, "Show guide 4", "Horizontal", false);
DeclareFloatParam (Hguide4, "Guide 4",      "Horizontal", kNoFlags, 0.95, 0.0, 1.0);

DeclareBoolParam  (Show_V1, "Show guide 1", "Vertical", true);
DeclareFloatParam (Vguide1, "Guide 1",      "Vertical", kNoFlags, 0.5,  0.0, 1.0);
DeclareBoolParam  (Show_V2, "Show guide 2", "Vertical", false);
DeclareFloatParam (Vguide2, "Guide 2",      "Vertical", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam  (Show_V3, "Show guide 3", "Vertical", false);
DeclareFloatParam (Vguide3, "Guide 3",      "Vertical", kNoFlags, 0.75, 0.0, 1.0);
DeclareBoolParam  (Show_V4, "Show guide 4", "Vertical", false);
DeclareFloatParam (Vguide4, "Guide 4",      "Vertical", kNoFlags, 0.05, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareIntParam (_InpOrientation);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define WHITE    1.0.xxxx

// Index values for subtract and difference settings as used by BlendMode

#define SUBTRACT 1
#define DIFFRNCE 2

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 Hline (float4 video, float2 uv, float pos, float thickness)
{
   // To calculate the position of the horizontal guide we only need the y coordinate.
   // Since y values in Lightworks have 0 at the top of frame and HLSL / GLSL place
   // it at the bottom the position must be inverted by subtracting it from 1.0.

   float position = 1.0 - pos;

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
   // X coordinates don't need inversion so this process is as shown in Hline() after
   // the position inversion.

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
   // Start by calculating the H and V guide line weights.  The H and V values allow
   // for the aspect ratio.

   float Hweight = ((Lweight * 4.5) + 0.5) * 0.001;
   float Vweight;

   if ((_InpOrientation == 0) || (_InpOrientation == 180)) {
      Vweight = Hweight;
      Hweight *= _OutputAspectRatio;
   }
   else Vweight = Hweight * _OutputAspectRatio;

   // Recover the video input and set up the guide blend variable.

   float4 Input  = ReadPixel (Inp, uv1);
   float4 retval;

   // If we want to display the rule of thirds grid we do that first.  Otherwise we
   // preload retval with the background video.

   if (Rule3rds) {
      retval =  Hline (Input,  uv1, 0.333333, Hweight);
      retval =  Hline (retval, uv1, 0.666667, Hweight);
      retval =  Vline (retval, uv1, 0.333333, Vweight);
      retval =  Vline (retval, uv1, 0.666667, Vweight);
   }
   else retval = Input;

   // Now do the four horizontal guides then the four verticals.

   if (Show_H1) retval = Hline (retval, uv1, Hguide1, Hweight);
   if (Show_H2) retval = Hline (retval, uv1, Hguide2, Hweight);
   if (Show_H3) retval = Hline (retval, uv1, Hguide3, Hweight);
   if (Show_H4) retval = Hline (retval, uv1, Hguide4, Hweight);

   if (Show_V1) retval = Vline (retval, uv1, Vguide1, Vweight);
   if (Show_V2) retval = Vline (retval, uv1, Vguide2, Vweight);
   if (Show_V3) retval = Vline (retval, uv1, Vguide3, Vweight);
   if (Show_V4) retval = Vline (retval, uv1, Vguide4, Vweight);

   // Finally mix back the guides over the original video and quit.

   return lerp (Input, retval, Opacity);
}

