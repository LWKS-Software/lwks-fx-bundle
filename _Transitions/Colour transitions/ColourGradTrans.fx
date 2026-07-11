// @Maintainer jwrl
// @Released 2026-07-11
// @Author jwrl
// @Created 2016-07-31

/**
 This effect fades two images or a blended foreground such as a title or image key in
 or out through a user-selected colour gradient.  The gradient can be a single flat
 colour, a vertical gradient, a horizontal gradient, a four corner gradient or even
 a monochrome mix of the two components.  The timing of the maximum colour strength is
 adjustable using the transition centre setting, and the dwell time can be controlled
 by means of the transition curve setting.

   [*]Amount:  The transition progress.
   [*]Mid point: Sets the time during the transition at which 100% colour mix
      will be reached.
   [*]Colour setup
      [*]Opacity: Sets the transparency of the colour mix.
      [*]Profile: Adjusts the curve of the mix to colour.
      [*]Gradient type: Sets the colour gradient to flat, a range of gradients, or to
         a black and white version of the mix.
      [*]Grad. mid X: Sets the horizontal position of the gradient midpoint.
      [*]Grad. mid Y: Sets the vertical position of the gradient midpoint.
      [*]Top left: The colour to be used at the top left of screen.
      [*]Top right: The colour to be used at the top right of screen.
      [*]Bot. left: The colour to be used at the bottom left of screen.
      [*]Bot. right: The colour to be used at the bottom right of screen.
      [*]Show grad.: Displays the colour to be used at the midpoint for setup
         purposes.
   [*]Enable blend transitions:  Changes the mode from opaque video to transparent
      video such as titles and the like.
   [*]Blend settings
      [*]Source:  Selects between an extracted video source and transparent video.
      [*]Transition into blend:  Selects between transitioning into or out of a
         blended video source.
      [*]Fine tune:  Fine tunes the separation of an extracted video source from
         its background.
      [*]Show foreground key:  Showing the key helps in setting up the clip.
      [*]Swap sources:  This can be necessary when using a folded delta key
         (extracted) transition.

 NOTE:  This effect has been revised for Lightworks version 2026 and higher.  Part of
 the revision process has meant the removal of masking.  In all other respects this
 behaves as the earlier versions did, and can be installed on any Lightworks version
 above 2022.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ColourGradTrans.fx
//
// Version history:
//
// Updated 2023-08-02 jwrl.
//
// Updated 2026-07-11 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-08 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
// Added means of previewing colour gradient while setting up.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-05-05 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Colour gradient transition", "Mix", "Colour transitions", "Transitions in or out through monochrome or a colour gradient", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",        kNoGroup,         kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (FxCentre,       "Mid point",     kNoGroup,         kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (cAmount,        "Opacity",       "Colour setup",   kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (cCurve,         "Profile",       "Colour setup",   kNoFlags, 0.0, 0.0, 1.0);
DeclareIntParam   (cGradient,      "Gradient type", "Colour setup", 5, "Flat (uses only the top left colour)|Horizontal blend (top left > top right)|Horizontal blend to centre (TL > TR > TL)|Vertical blend (top left > bottom left)|Vertical blend to centre (TL > BL > TL)|Four way gradient|Four way gradient to centre|Four way gradient to centre (horizontal)|Four way gradient to centre (vertical)|Radial (TL outer > TR centre)|Black and white");
DeclareFloatParam (OffsX,          "Grad. mid",     "Colour setup",   "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (OffsY,          "Grad. mid",     "Colour setup",   "SpecifiesPointY", 0.5, 0.0, 1.0);
DeclareColourParam (topLeft,       "Top left",      "Colour setup",   kNoFlags, 0.0, 0.0, 0.0, 1.0);
DeclareColourParam (topRight,      "Top right",     "Colour setup",   kNoFlags, 0.5, 0.0, 0.8, 1.0);
DeclareColourParam (botLeft,       "Bot. left",     "Colour setup",   kNoFlags, 0.0, 0.0, 1.0, 1.0);
DeclareColourParam (botRight,      "Bot. right",    "Colour setup",   kNoFlags, 0.0, 0.8, 0.5, 1.0);
DeclareBoolParam  (ShowGrad,       "Show gradient", "Colour setup",   false);

DeclareBoolParam  (Blended,        "Enable blend transitions",       kNoGroup, false);

DeclareIntParam   (Source,         "Source",        "Blend settings", 0, "Extracted foreground|Image key or title (disconnect input)");
DeclareBoolParam  (SwapDir,        "Transition into blend",           "Blend settings", true);
DeclareFloatParam (KeyGain,        "Fine tune",     "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam  (ShowKey,        "Show foreground key",             "Blend settings", false);
DeclareBoolParam  (SwapSource,     "Swap sources",  "Blend settings", false);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI      3.1415926536
#define HALF_PI 1.5707963268

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_gradient (float4 Fgd, float4 Bgd, float2 uv)
{
   if (cGradient == 0) return topLeft;

   float4 retval;

   if (cGradient > 9) {
      float4 Vsub = saturate (Fgd + Bgd);

      Vsub.a = max (Fgd.a, Bgd.a);
      return float4 (dot (Vsub.rgb, float3 (0.299, 0.587, 0.114)).xxx, Vsub.a);
   }

   float buff_1, buff_2, horiz, vert = 1.0 - OffsY;
   float buff_0 = (OffsX <= 0.0)  ? (uv.x / 2.0) + 0.5 :
                  (OffsX >= 1.0)  ? uv.x / 2.0 :
                  (OffsX > uv.x) ? uv.x / (2.0 * OffsX) : ((uv.x - OffsX) / (2.0 * (1.0 - OffsX))) + 0.5;

   if ((cGradient == 2) || (cGradient == 6) || (cGradient == 8) || (cGradient == 9)) horiz = sin (PI * buff_0);
   else {
      sincos (HALF_PI * buff_0, buff_1, buff_2);
      buff_2 = 1.0 - buff_2;
      horiz = lerp (buff_1, buff_2, buff_0);
   }

   buff_0 = (vert <= 0.0) ? (uv.y / 2.0) + 0.5 :
            (vert >= 1.0) ? uv.y / 2.0 :
            (vert > uv.y) ? uv.y / (2.0 * vert) : ((uv.y - vert) / (2.0 * (1.0 - vert))) + 0.5;

   if ((cGradient == 4) || (cGradient == 6) || (cGradient == 7) || (cGradient == 9)) vert = sin (PI * buff_0);
   else {
      sincos (HALF_PI * buff_0, buff_1, buff_2);
      buff_2 = 1.0 - buff_2;
      vert = lerp (buff_1, buff_2, buff_0);
   }

   if ((cGradient == 3) || (cGradient == 4)) { retval = lerp (topLeft, botLeft, vert); }
   else {
      retval = lerp (topLeft, topRight, horiz);
   
      if (cGradient == 9) retval = lerp (topLeft, retval, vert);
      else if (cGradient > 4) {
         float4 botRow = lerp (botLeft, botRight, horiz);
         retval = lerp (retval, botRow, vert);
      }
   }

   return retval;
}

float4 fn_colour (float4 Fgnd, float4 Bgnd, float amt, float2 xy)
{
   float Mix = (FxCentre + 1.0) / 2.0;

   Mix = (Mix <= 0.0) ? (amt / 2.0) + 0.5 :
         (Mix >= 1.0) ? amt / 2.0 :
         (Mix > amt) ? amt / (2.0 * Mix) : ((amt - Mix) / (2.0 * (1.0 - Mix))) + 0.5;

   float4 retval = fn_gradient (Fgnd, Bgnd, xy);
   float4 colDx, rawDx = lerp (Fgnd, Bgnd, Mix);

   float nonLin = sin (Mix * PI);

   Mix += Mix;

   if (Mix > 1.0) {
      Mix = lerp (2.0 - Mix, nonLin, cCurve);
      colDx = lerp (Bgnd, retval, Mix);
   }
   else {
      Mix = lerp (Mix, nonLin, cCurve);
      colDx = lerp (Fgnd, retval, Mix);
   }

   return lerp (rawDx, colDx, cAmount);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   if (!Blended) return float4 ((ReadPixel (Fg, uv1)).rgb, 1.0);

   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (Bg, uv2);
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      Fgnd = ReadPixel (Fg, uv1);
      Bgnd = ReadPixel (Bg, uv2);
   }

   if (Source == 0) Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));

   // If alpha is zero we need any video to be blanked.  We do NOT need it to be
   // multiplied, so this is the simplest way to fix things.

   if (Fgnd.a == 0.0) Fgnd = kTransparentBlack;

   return Fgnd;
}

DeclarePass (Bgd)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

DeclareEntryPoint (ColourMixTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 retval;

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         if (ShowGrad) { retval = float4 (fn_gradient (Fgnd, Bgnd, uv0).rgb, 1.0); }
         else {
            float amt = SwapDir ? 1.0 - Amount : Amount;

            retval = lerp (Bgnd, fn_colour (Fgnd, Bgnd, amt, uv0), Fgnd.a);
         }
      }
   }
   else {
      if (ShowGrad) { retval = float4 (fn_gradient (Fgnd, Bgnd, uv0).rgb, 1.0); }
      else retval = fn_colour (Fgnd, Bgnd, Amount, uv0);
   }

   return retval;
}
