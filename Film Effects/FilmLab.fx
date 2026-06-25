// @Maintainer jwrl
// @Released 2026-06-25
// @Author jwrl
// @Created 2020-07-27

/**
 This applies a range of tweaks to simulate the look of various colour film laboratory
 operations.  While similar to the older Film Fx, it differs in several important ways.
 The first and most important difference is that the previous effect suffered from
 range overflow.  This could result in highlights becoming grey, and colours suffering
 arbitrary shifts of both hue and saturation.  This effect corrects that.

   [*]Amount:  Fades the effect to reveal the unmodified input.
   [*]Video settings
      [*]Saturation:  Adjusts the input video saturation.
      [*]Gamma:  Adjusts the input video gamma.
      [*]Contrast: Adjusts the input video contrast.
   [*]Lab operations
      [*]Linearity:  Adjusts the linearity of the video to lab colour space conversion.
      [*]Bleach:  Short for bleach bypas, this simulates the effect of the bleach
         process being skipped during film development.
      [*]Film ageing: Simulates the dye fading as film stocks age.
   [*]Preprocessing curves
      [*]RGB:  Applies a luminance S-curve.
      [*]Red:  Applies an S-curve to the red channel.
      [*]Green:  Applies an S-curve to the green channel.
      [*]Blue: Applies an S-curve to the green channel.
   [*]Gamma presets
      [*]RGB:  Applies gamma to the output luminance.
      [*]Red:  Applies gamma to the red channel.
      [*]Green:  Applies gamma to the green channel.
      [*]Blue:  Applies gamma to the blue channel.
   [*]Mask:  The Lightworks mask effect.

 There are also a collection of parameter changes.  The first and most obvious difference
 is in the grouping and order of settings.  Often the name of a group, its settings and
 occasionally even range differs.  The group "Master Effect" has been dropped entirely,
 and three of the parameters that were previously in it, "Saturation", "Gamma" and
 "Contrast" are now in a new group called "Video settings".  "Linearization", "Bleach"
 and "Fade" have also been placed in their own group, "Lab operations".  They are now
 named "Linearity", "Bleach" (unchanged) and "Film ageing".  The group "Curves" is now
 called "Preprocessing curves", and "Gamma" is now "Gamma presets".  That leaves the
 "Strength" setting ungrouped.  It has been replaced by "Amount" which ranges from 0% to
 100%, where 0% outputs the unmodified video input.

 In "Video settings" the direction of action of "Saturation" has changed to be more
 logical and now ranges from 50% to 150%.  "Contrast" ranges from 50% to 150% not 0.6
 to 1, where 100% is normal contrast.  In the lab operations the "Bleach" has been
 retained.  While not as clear as bleach bypass, it at least fits in the space allowed
 for the setting!  The preprocessing curves range from 1 to 10 where in Film Fx they
 ranged from 0% to 100%.  The label RGB in that group and in "Gamma presets" is used
 in place of Base, which wasn't as clear.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FilmLab.fx
//
// This is based on ideas from Avery Lee's Virtualdub GPU shader, v1.6 - 2008(c) Jukka
// Korhonen.  However this effect is new code from the ground up.
//
// Version history:
//
// Updated 2026-06-25 jwrl.
// Rewrote the headings text to match the forum text.
//
// Updated 2026-06-24 jwrl.
// Now uses all mask channels instead of just one.
// Changed "Bleach bypass" to "Blch bypass" to fit LW 2026 parameter size.
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with float4 _TransparentBlack for Linux fix.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Film lab", "Colour", "Film Effects", "This is a colour film processing lab for video", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount,     "Amount",      kNoGroup,               kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Saturation, "Saturation",  "Video settings",       "DisplayAsPercentage", 1.0, 0.5, 1.5);
DeclareFloatParam (Gamma,      "Gamma",       "Video settings",       kNoFlags, 1.0, 0.1, 2.5);
DeclareFloatParam (Contrast,   "Contrast",    "Video settings",       "DisplayAsPercentage", 1.0, 0.5, 1.5);

DeclareFloatParam (Linearity,  "Linearity",   "Lab operations",       kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Bypass,     "Blch bypass", "Lab operations",       kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Ageing,     "Film ageing", "Lab operations",       kNoFlags, 0.3, 0.0, 1.0);

DeclareFloatParam (LumaCurve,  "RGB",         "Preprocessing curves", kNoFlags, 1.0, 1.0, 10.0);
DeclareFloatParam (RedCurve,   "Red",         "Preprocessing curves", kNoFlags, 10.0, 1.0, 10.0);
DeclareFloatParam (GreenCurve, "Green",       "Preprocessing curves", kNoFlags, 5.5, 1.0, 10.0);
DeclareFloatParam (BlueCurve,  "Blue",        "Preprocessing curves", kNoFlags, 1.0, 1.0, 10.0);

DeclareFloatParam (LumaGamma,  "RGB",         "Gamma presets",        kNoFlags, 1.4, 0.1, 2.5);
DeclareFloatParam (RedGamma,   "Red",         "Gamma presets",        kNoFlags, 1.0, 0.1, 2.5);
DeclareFloatParam (GreenGamma, "Green",       "Gamma presets",        kNoFlags, 1.0, 0.1, 2.5);
DeclareFloatParam (BlueGamma,  "Blue",        "Gamma presets",        kNoFlags, 1.0, 0.1, 2.5);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

float4 _TransparentBlack = 0.0.xxxx;

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (FilmLab)
{
   if (IsOutOfBounds (uv1)) return _TransparentBlack;

   float lin = (Linearity * 1.5) + 1.0;

   float4 src = tex2D (Inp, uv1);
   float4 vid = pow (src, 1.0 / Gamma);

   vid.a = src.a;

   float4 lab = lerp (0.01.xxxx, pow (vid, lin), Contrast);

   float3 print = pow (lab.rgb, 1.0 / LumaGamma);
   float3 grade = dot ((1.0 / 3.0).xxx, lab.rgb).xxx;
   float3 flash = float3 (RedCurve, GreenCurve, BlueCurve);
   float3 light = 1.0.xxx / (1.0.xxx + exp (flash / 2.0));

   grade = 0.5.xxx - grade;
   grade = (1.0.xxx / (1.0.xxx + exp (flash * grade)) - light) / (1.0.xxx - (2.0 * light));
   grade = lerp (grade, 1.0.xxx - grade, Bypass);

   grade.x = pow (grade.x, 1.0 / RedGamma);
   grade.y = pow (grade.y, 1.0 / GreenGamma);
   grade.z = pow (grade.z, 1.0 / BlueGamma);

   grade = (2.0 * grade) - 1.0.xxx;

   lab.r = (grade.x < 0.0) ? print.r * (grade.x * (1.0 - print.r) + 1.0)
                           : grade.x * (sqrt (print.r) - print.r) + print.r;
   lab.g = (grade.y < 0.0) ? print.g * (grade.y * (1.0 - print.g) + 1.0)
                           : grade.y * (sqrt (print.g) - print.g) + print.g;
   lab.b = (grade.z < 0.0) ? print.b * (grade.z * (1.0 - print.b) + 1.0)
                           : grade.z * (sqrt (print.b) - print.b) + print.b;
   flash.x = LumaCurve;
   flash.y = 1.0 / (1.0 + exp (LumaCurve / 2.0));
   flash.z  = 1.0 - (2.0 * flash.y);

   grade   = 0.5.xxx - lab.rgb;
   lab.rgb = (1.0.xxx / (1.0.xxx + exp (flash.x * grade)) - flash.yyy) / flash.z;
   lab.gb  = lerp (lab.gb, lab.bg, Ageing * 0.495);

   float adjust = dot (2.0.xxx / 3.0, lab.rgb) - 1.0;

   lab = (adjust < 0.0) ? lab * (adjust * (1.0.xxxx - lab) + 1.0.xxxx)
                        : adjust * (sqrt (lab) - lab) + lab;
   print = lerp ((lab.r + lab.g + lab.b).xxx / 3.0, lab.rgb, (Saturation - 0.5) * 2.0);
   lab = float4 (pow (print, 1.0 / lin), vid.a);

   vid = lerp (_TransparentBlack, lerp (vid, lab, Amount), src.a);

   return lerp (src, vid, tex2D (Mask, uv1));
}
