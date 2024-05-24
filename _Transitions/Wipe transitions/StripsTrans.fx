// @Maintainer jwrl
// @Released 2024-05-04
// @Author jwrl
// @Created 2018-06-13

/**
 A transition that splits a blended foreground image into strips and compresses it to zero
 height.  The vertical centring can be adjusted so that the collapse is symmetrical or
 asymmetrical.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect StripsTrans.fx
//
// Version history:
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with 0.0.xxxx to fix Linux lerp()/mix() bug.
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-10 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Strips transition", "Mix", "Wipe transitions", "Splits the foreground into strips and compresses it to zero height", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Spacing, "Spacing", "Strips", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Spread, "Spread", "Strips", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (centreX, "Centre", "Strips", "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (centreY, "Centre", "Strips", "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareIntParam (Source, "Source", "Blend settings", 0, "Extracted foreground|Image key/Title pre 2023.2, no input|Image or title without connected input");
DeclareBoolParam (SwapDir, "Transition into blend", "Blend settings", true);
DeclareFloatParam (KeyGain, "Key adjustment", "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam (ShowKey, "Show foreground key", "Blend settings", false);
DeclareBoolParam (SwapSource, "Swap sources", "Blend settings", false);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HEIGHT   20.0

#define PI       3.1415926536
#define HALF_PI  1.5707963268

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   float4 Fgnd, Bgnd;

   if (SwapSource) {
      Fgnd = ReadPixel (Bg, uv2);
      Bgnd = ReadPixel (Fg, uv1);
   }
   else {
      Fgnd = ReadPixel (Fg, uv1);
      Bgnd = ReadPixel (Bg, uv2);
   }

   if (Source == 0) { Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb)); }
   else if (Source == 1) { Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0)); }

   if (Fgnd.a == 0.0) Fgnd.rgb = Fgnd.aaa;

   return Fgnd;
}

DeclarePass (Bgd)
{ return SwapSource ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclareEntryPoint (StripsTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);

   if (ShowKey) { return lerp (0.0.xxxx, Fgnd, Fgnd.a * tex2D (Mask, uv3).x); }

   float4 Bgnd = tex2D (Bgd, uv3);
   float4 retval, maskBg = Bgnd;

   float amount   = SwapDir ? 1.0 - Amount : Amount;
   float Width    = 10.0 + (Spacing * 40.0);
   float centre_X = 1.0 - (2.0 * centreX);
   float centre_Y = 1.0 - centreY;
   float offset   = sin (Width * uv3.y * PI);
   float Height   = 1.0 + ((1.0 - cos (amount * HALF_PI)) * HEIGHT);

   if (abs (offset) > 0.5) offset = -offset;

   offset = ((floor (offset * 5.2) / 5.0) + centre_X) * amount;
   amount = 1.0 - amount;

   float2 xy = uv3 + float2 (offset, -centre_Y);

   offset *= 2.0 * Spread;
   xy.y = (xy.y * Height) + offset + centre_Y;

   Fgnd = ReadPixel (Fgd, xy);
   retval = lerp (Bgnd, Fgnd, Fgnd.a * amount);

   return lerp (maskBg, retval, tex2D (Mask, uv3).x);
}
