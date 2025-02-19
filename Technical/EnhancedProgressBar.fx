// @Maintainer jwrl
// @Released 2025-02-19
// @Author jwrl
// @Created 2025-02-19

/**
 This is a more complex version of the simple progress bar generator.  Like that
 effect the bar can be bordered and can be positioned vertically and horizontally.
 The bar background colour and border can each be individually set.  The bar can
 be shown with or without background and border.  However it has been considerably
 enhanced with respect to that earlier effect.

 The bar can have a smooth colour gradient, or can step between fixed colours as it
 progresses.  In step mode it can switch between two colours or three, while in
 gradient mode the three colours are used as reference points for the gradient.
 The border and background colours can be independently adjusted, and the complete
 bar can be faded in and out.

   [*] Opacity:  Fades the bar in or out.
   [*] Progress:  Adjusts the bar range.  This can be keyframed to make the bar grow
                  or shrink.
   [*] Bar mode:  Can be set to display vertical or horizontal steps, or a vertical or
                  horizontal gradient.
   [*] Position X:  Sets the horizontal position of the bar.
   [*] Position Y:  Sets the vertical position of the bar.
   [*] Bar colour
      [*] Break 1:  The point at which the bar will change to the mid colour, colour 1.
      [*] Break 2:  The point at which the bar will change to the end colour, colour 2.
      [*] Colour 0:  The start or minimum colour.
      [*] Colour 1:  The midpoint colour.
      [*] Colour 2:  The end or full range colour.
   [*] Bar shape
      [*] Width:  Adjusts the overall width of the bar.  If the bar is set to vertical
                  mode the width adjusts horizontally, otherwise it adjusts vertically.
      [*] Length:  Adjusts the length of the bar.  If the bar is set to horizontal
                   mode the length changes horizontally, otherwise it changes vertically.
      [*] Show base:  Can either show the background and border or hide it.
      [*] Border width:  Self explanatory.
      [*] Border colour:  Self explanatory.
      [*] Base colour:  The background colour of the bar.

 The way that the breaks work is complex but I feel, logical.  In gradient mode break 2
 is not used at all.  Break 1 will cause the gradient to run from colour 1 to colour 2
 when set to zero, and when set to 100% the gradient range is from colour 0 to colour 1.
 Try it - it should be clear enough once you see what it does on screen.

 In step mode if break 1 is set to zero, colour 1 will be used as the start colour and
 colour 0 will be ignored.  If it's set equal to or greater than break 2 it will be
 ignored and the bar colour will switch from colour 0 to colour 2 at break 2.  Finally,
 if break 2 is set to zero the only colour used will be colour 2.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect EnhancedProgressBar.fx
//
// Version history:
//
// Built 2025-02-19 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Enhanced progress bar", "Matte", "Technical", "A flexible progress bar generator", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity",  kNoGroup, kNoFlags, 1.0,  0.0, 1.0);
DeclareFloatParam (Amount,  "Progress", kNoGroup, kNoFlags, 0.85, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Bar mode", kNoGroup, 1, "Vertical steps|Horizontal steps|Vertical gradient|Horizontal gradient");

DeclareFloatParam (PosX, "Position", kNoGroup, "SpecifiesPointX", 0.1, 0.0, 1.0);
DeclareFloatParam (PosY, "Position", kNoGroup, "SpecifiesPointY", 0.1, 0.0, 1.0);

DeclareFloatParam  (Break_1,  "Break 1",  "Bar colour", kNoFlags, 0.75, 0.0,  1.0);
DeclareFloatParam  (Break_2,  "Break 2",  "Bar colour", kNoFlags, 0.8,  0.0,  1.0);
DeclareColourParam (Colour_0, "Colour 0", "Bar colour", kNoFlags, 0.08, 0.55, 0.03, 1.0);
DeclareColourParam (Colour_1, "Colour 1", "Bar colour", kNoFlags, 1.0,  0.85, 0.0,  1.0);
DeclareColourParam (Colour_2, "Colour 2", "Bar colour", kNoFlags, 0.72, 0.13, 0.0,  1.0);

DeclareFloatParam  (BarWidth,     "Width",         "Bar shape", kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam  (BarLength,    "Length",        "Bar shape", kNoFlags, 0.8, 0.0, 1.0);
DeclareBoolParam   (ShowBase,     "Show base",     "Bar shape", true);
DeclareFloatParam  (BorderWidth,  "Border width",  "Bar shape", kNoFlags, 0.1, 0.0, 1.0);
DeclareColourParam (BorderColour, "Border colour", "Bar shape", kNoFlags, 0.0, 0.0, 0.0, 1.0);
DeclareColourParam (BaseColour,   "Base colour",   "Bar shape", kNoFlags, 0.9, 0.9, 0.9, 1.0);

DeclareFloatParam (_OutputAspectRatio);
DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 makeSteps (float x, float y)
{
   float bar = saturate ((x / BarLength) - y);

   float4 retval;

   if (bar <= Amount) {
      float middle = min (max (Break_1, 0.0), Break_2);

      retval = bar < middle ? Colour_0 : bar < Break_2 ? Colour_1 : Colour_2;
   }
   else retval = ShowBase ? BaseColour : 0.0.xxxx;

   return retval;
}

float4 makeGradient (float x, float y)
{
   float grad = saturate ((x / BarLength) - y);

   float4 retval;

   if (grad <= Amount) {
      float middle = saturate (Break_1);

      if (middle == 0.0) { retval = lerp (Colour_1, Colour_2, grad); }
      else if (middle == 1.0) { retval = lerp (Colour_0, Colour_1, grad); }
      else {
         float grad_1 = smoothstep (0.0, middle, grad);
         float grad_2 = smoothstep (middle, 1.0, grad);

         retval = lerp (lerp (Colour_0, Colour_1, grad_1), Colour_2, grad_2);
      }
   }
   else retval = ShowBase ? BaseColour : 0.0.xxxx;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// Technique 0

DeclareEntryPoint (VerticalBar)
{
   float width = BarWidth * 0.125;

   float2 border = float2 (1.0, _OutputAspectRatio) * BorderWidth * 0.025;
   float2 cropTL = float2 (PosX - width, 1.0 - PosY - BarLength);
   float2 cropBR = float2 (PosX + width, 1.0 - PosY);
   float2 bordTL = saturate (cropTL - border);
   float2 bordBR = saturate (cropBR + border);

   float4 Input  = ReadPixel (Inp, uv1);
   float4 retval = 0.0.xxxx;

   if (all (uv1 > cropTL) && all (uv1 < cropBR)) { retval = makeSteps (1.0 - uv1.y, PosY); }
   else if (all (uv1 > bordTL) && all (uv1 < bordBR) && ShowBase) { retval = BorderColour; }

   return lerp (Input, retval, retval.a * Opacity);
}

//-----------------------------------------------------------------------------------------//

// Technique 1 (default)

DeclareEntryPoint (HorizontalBar)
{
   float height = BarWidth * _OutputAspectRatio * 0.125;

   float2 border = float2 (1.0, _OutputAspectRatio) * BorderWidth * 0.025;
   float2 cropTL = float2 (PosX, 1.0 - PosY - height);
   float2 cropBR = float2 (PosX + BarLength, 1.0 - PosY + height);
   float2 bordTL = saturate (cropTL - border);
   float2 bordBR = saturate (cropBR + border);

   float4 Input  = ReadPixel (Inp, uv1);
   float4 retval = 0.0.xxxx;

   if (all (uv1 > cropTL) && all (uv1 < cropBR)) { retval = makeSteps (uv1.x, PosX); }
   else if (all (uv1 > bordTL) && all (uv1 < bordBR) && ShowBase) { retval = BorderColour; }

   return lerp (Input, retval, retval.a * Opacity);
}

//-----------------------------------------------------------------------------------------//

// Technique 2

DeclareEntryPoint (VerticalGradient)
{
   float width = BarWidth * 0.125;

   float2 border = float2 (1.0, _OutputAspectRatio) * BorderWidth * 0.025;
   float2 cropTL = float2 (PosX - width, 1.0 - PosY - BarLength);
   float2 cropBR = float2 (PosX + width, 1.0 - PosY);
   float2 bordTL = saturate (cropTL - border);
   float2 bordBR = saturate (cropBR + border);

   float4 Input  = ReadPixel (Inp, uv1);
   float4 retval = 0.0.xxxx;

   if (all (uv1 > cropTL) && all (uv1 < cropBR)) { retval = makeGradient (1.0 - uv1.y, PosY); }
   else if (all (uv1 > bordTL) && all (uv1 < bordBR) && ShowBase) { retval = BorderColour; }

   return lerp (Input, retval, retval.a * Opacity);
}

//-----------------------------------------------------------------------------------------//

// Technique 3

DeclareEntryPoint (HorizontalGradient)
{
   float height = BarWidth * _OutputAspectRatio * 0.125;

   float2 border = float2 (1.0, _OutputAspectRatio) * BorderWidth * 0.025;
   float2 cropTL = float2 (PosX, 1.0 - PosY - height);
   float2 cropBR = float2 (PosX + BarLength, 1.0 - PosY + height);
   float2 bordTL = saturate (cropTL - border);
   float2 bordBR = saturate (cropBR + border);

   float4 Input  = ReadPixel (Inp, uv1);
   float4 retval = 0.0.xxxx;

   if (all (uv1 > cropTL) && all (uv1 < cropBR)) { retval = makeGradient (uv1.x, PosX); }
   else if (all (uv1 > bordTL) && all (uv1 < bordBR) && ShowBase) { retval = BorderColour; }

   return lerp (Input, retval, retval.a * Opacity);
}

