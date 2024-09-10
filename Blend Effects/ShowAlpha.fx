// @Maintainer jwrl
// @Released 2024-09-10
// @Author jwrl
// @Created 2024-09-08

/**
 Show alpha is a utility designed to show the presence of the alpha channel in a graphic
 or animated sequence.  The modes and what they do are:

   • Normal blend:  Identical to the Lightworks blend effect.
   • Foreground only:  Shows the foreground, but with black wherever there is transparency.
   • Show alpha as checkerboard:  Shows the foreground over a checkerboard pattern.
   • Show alpha:  The alpha (transparency) channel is shown as white over black.

 The amount control in normal blend mode works as the opacity does in the blend effect.
 In the next two display modes it fades between foreground over background at 0% to the
 selected mode at 100%.  Show alpha just fades the alpha display in or out.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ShowAlpha.fx
//
// Version history:
//
// Modified 2024-09-10 by jwrl.
// Changed mask behaviour so that it registers as part of alpha in every display mode.
// Now uses conditional tests instead of SetTechnique to select display mode.
// Changed default setting to checkerboard display.
//
// Built 2024-09-08 by jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Show alpha", "Mix", "Blend Effects", "Performs a simple blend or just shows the alpha channel", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg, Linear, Mirror);
DeclareInput (Bg, Linear, Mirror);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam   (Display, "Display", kNoGroup, 2, "Normal blend|Foreground only|Show alpha as checkerboard|Show alpha");

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define BLEND   0
#define FG_ONLY 1
#define ALPHA   3

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (ShowAlpha)
{
   float msk = tex2D (Mask, uv3).x;

   // Masking happens AS WE LOAD THE FOREGROUND, because we need the composite alpha
   // to be available so that true alpha values can be shown.

   float4 Fgnd = lerp (kTransparentBlack, tex2D (Fgd, uv3), msk);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 Foreground, Background;

   // After the next conditionals are executed Foreground contains the chosen composite.
   // Background can be simple Bg, blended Fg over Bg, or opaque back.

   if (Display == BLEND) {
      Foreground = lerp (Bgnd, Fgnd, Fgnd.a);
      Background = Bgnd;
   }
   else if (Display == FG_ONLY) {               // This blacks Fg out wherever alpha is zero
      Foreground = float4 (Fgnd.rgb, 1.0) * Fgnd.a;
      Background = lerp (Bgnd, Fgnd, Fgnd.a);   // The background is the blended Fg/Bg composite
   }
   else if (Display == ALPHA) {                 // Alpha is shown as opaque white on black.
      Foreground = float4 (Fgnd.aaa, 1.0);
      Background = float4 (0.0.xxx, 1.0);
   }
   else {               // This is the default setting and shows alpha as a checkerboard pattern

      // The checkerboard routine scales the xy cooordinates by a fraction of width and height then
      // rounds the fractional result to make alternating zeros and ones.  The difference between
      // those is the checkerboard pattern, used to give luminance of 0.25 (zero) or 0.2 (one).

      float x = round (frac (uv3.x * _OutputWidth  / 64.0));
      float y = round (frac (uv3.y * _OutputHeight / 64.0));
      float z = 0.25 - min (abs (x - y), 0.05);

      Foreground = lerp (float4 (z, z, z, 0.0), Fgnd, Fgnd.a);
      Background = lerp (Bgnd, Fgnd, Fgnd.a);   // The background is the blended Fg/Bg composite
   }

   return lerp (Background, Foreground, Amount);
}
