// @Maintainer jwrl
// @Released 2025-08-30
// @Author jwrl
// @Created 2020-02-29

/**
 This is is the analogue equivalent of a digital logic gate.  AND, OR, NAND, NOR
 and XOR have been implemented while the analogue levels of the alpha channel have
 been maintained.  The background video is blended with the A and B logic result,
 and the logic is fully implemented in the alpha channel.  Also included is a
 means of masking B with A.  In that case the same operation as with AND is
 performed on the alpha channels, but the background video is taken only from the
 B channel.

 In all modes the default is to premultiply the RGB by the alpha channel.  This is
 done to ensure that transparency displays as black as far as the gating is
 concerned.  However in this effect RGB can also be simply set to zero when alpha
 is zero.  This can be done independently for each channel.

 The levels of the A and B inputs can also be adjusted independently.  In mask mode
 reducing the A level to zero will fade the mask, revealing the background video in
 its entirety.  In that mode reducing the B level to zero fades the effect to black.

 There is also a means of using a luminance key on both A and B videos to create an
 artificial alpha channel for each channel.  The alpha value, however it is produced,
 is output for possible use by the blending logic.  Where the final output alpha
 channel is zero the video is blanked to allow for the boolean result to be used in
 external blend and transform effects.

   [*] Boolean function:  Sets the boolean function used to combine A with B.  Can be
       AND, OR, NAND, NOR, XOR or mask B with A.
   [*] Blend mode:  Photoshop style blend mode used to blend the A and B logic over
       the background.
   [*] Blend opacity:  Fades the blend into or out of the background.
   [*] A video
      [*] Amount:  Mixes the A channel into the logic.
      [*] Transparency:  Selects whether to use A transparency, unpremultiplied A
          transparency or a luminance key.
   [*] B video
      [*] Amount:  Mixes the B channel into the logic.
      [*] Transparency:  Selects whether to use B transparency, unpremultiplied B
          transparency or a luminance key.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BoolBlendPlus.fx
//
// Version history:
//
// Updated 2025-08-30 jwrl.
// Reworked blend modes to better match Photoshop.
//
// Updated 2023-05-15 jwrl.
// Header reformatted.
//
// Conversion 2023-01-23 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Boolean blend plus", "Mix", "Blend Effects", "Combines two images using an analogue equivalent of boolean logic then blends the result over background video", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (A, B, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Logic, "Boolean function", kNoGroup, 0, "AND|OR|NAND|NOR|XOR|Mask B with A");
DeclareIntParam (SetTechnique, "Blend mode", kNoGroup, 0, "Normal|Export boolean only|____________________|Darken|Multiply|Colour Burn|Linear Burn|Darker Colour|____________________|Lighten|Screen|Colour Dodge|Linear Dodge (Add)|Lighter Colour|____________________|Overlay|Soft Light|Hard Light|Vivid Light|Linear Light|Pin Light|Hard Mix|____________________|Difference|Exclusion|Subtract|Divide|____________________|Hue|Saturation|Colour|Luminosity");
DeclareFloatParam (Amount,   "Blend opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Amount_A, "Amount",       "A video", kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam   (Alpha_A,  "Transparency", "A video", 1, "Standard|Unpremultiplied|Alpha from RGB)";

DeclareFloatParam (Amount_B, "Amount",       "B video", kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam   (Alpha_B,  "Transparency", "B video", 1, "Standard|Unpremultiplied|Alpha from RGB)";

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define AND    0
#define OR     1
#define NAND   2
#define NOR    3
#define XOR    4
#define MASK   5

#define LUM    float3(0.2989, 0.5866, 0.1145)
#define LUMA   float4(LUM, 0.0)

#define BLACK  float4 (0.0.xxx, 1.0)

float4 _TransparentBlack = 0.0.xxxx;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 initLogic (float2 xy1, float2 xy2, float2 xy3, out float4 Bgd)
{
   Bgd = ReadPixel (Bg, xy3);

   if (IsOutOfBounds (xy1) && IsOutOfBounds (xy2))
      return (Logic == NAND) || (Logic == NOR) ? BLACK : _TransparentBlack;

   float4 vidA = ReadPixel (A, xy1);
   float4 vidB = ReadPixel (B, xy2);
   float4 retval;

   // If premultiply is not set, alpha at zero causes the RGB values to be replaced
   // with zero (absolute black).  If alpha is not available, RGB values can be used
   // instead but premutliply is not available in that mode.

   if (Alpha_A == 1) { vidA.rgb *= vidA.a; }
   else if (Alpha_A == 2) {
      vidA.a  = max (vidA.r, max (vidA.g, vidA.b));
      vidA.a *= vidA.a;
   }
   else if (vidA.a == 0.0) vidA = _TransparentBlack;

   if (Logic == MASK) {
      // The mask operation differs slightly from a simple boolean, in that only
      // the B video will be displayed after it's masked and not a mix of A and B.

      if (Alpha_B == 2) {
         vidB.a  = max (vidB.r, max (vidB.g, vidB.b));
         vidB.a *= vidB.a;
      }

      vidB *= Amount_B;

      retval = float4 (vidB.rgb, min (vidA.a, vidB.a));

      // The premultiply for B is done now to clean up the video after masking.

      if (Alpha_B == 1) { retval.rgb *= retval.a; }
      else if (retval.a == 0.0) retval = _TransparentBlack;

      return lerp (vidB, retval, Amount_A);
   }

   if (Alpha_B == 1) { vidB.rgb *= vidB.a; }
   else if (Alpha_B == 2) {
      vidB.a  = max (vidB.r, max (vidB.g, vidB.b));
      vidB.a *= vidB.a;
   }
   else if (vidB.a == 0.0) vidB = _TransparentBlack;

   vidA *= Amount_A;
   vidB *= Amount_B;

   // In all boolean modes the video is initially OR-ed.  This is so that whatever is
   // subsequently done to the alpha channel, appropriate video will be output.

   retval = max (vidA, vidB);

   // The boolean logic is now applied to the alpha channel only.  Nothing needs to be
   // done if the logic setting is OR, because we already have that result.

   if (Logic == AND) retval.a = min (vidA.a, vidB.a);
   if (Logic == NAND) retval.a = 1.0 - min (vidA.a, vidB.a);
   if (Logic == NOR) retval.a = 1.0 - retval.a;
   if (Logic == XOR) retval.a *= 1.0 - min (vidA.a, vidB.a);

   if (retval.a == 0.0) retval = _TransparentBlack;         // Blanks the video if alpha is zero

   return retval;
}

//---------------------------  Functions for main blend series  ---------------------------//

float ColourBurnSub (float B, float F)
// Increases contrast to darken the B channel based on the F channel.
{
   return B >= 1.0 ? 1.0 : F <= 0.0 ? 0.0 : 1.0 - min (1.0, (1.0 - B) / F);
}

float LinearBurnSub (float B, float F)
// Decreases brightness of the summed B and F channels to darken the output.
{
   return max (0.0, B + F - 1.0);
}

float ColourDodgeSub (float B, float F)
// Brightens the B channel using the F channel to decrease contrast.
{
   return B <= 0.0 ? 0.0 : F >= 1.0 ? 1.0 : min (1.0, B / (1.0 - F));
}

float LinearDodgeSub (float B, float F)
// Sums B and F channels and limits them to a maximum of 1.
{
   return min (1.0, B + F);
}

float OverlaySub (float B, float F)
// Multiplies or screens the channels, depending on the B channel.
{
   return B <= 0.5 ? 2.0 * B * F : 1.0 - (2.0 * (1.0 - B) * (1.0 - F));
}

float SoftLightSub (float B, float F)
// Darkens or lightens the channels, depending on the F channel.
{
   if (F <= 0.5) { return B - ((1.0 - 2.0 * F) * B * (1.0 - B)); }

   float d = B <= 0.25 ?  ( (16.0 * B - 12.0) * B + 4.0) * B : sqrt (B);

   return B + (2.0 * F - 1.0) * (d - B);
}

float HardLightSub (float B, float F)
// Multiplies or screens the channels, depending on the F channel.
{
   return F <= 0.5 ? 2.0 * B * F : 1.0 - (2.0 * (1.0 - B) * (1.0 - F));
}

float VividLightSub (float B, float F)
// Burns or dodges the channels, depending on the F value.
{
   return F <= 0.5 ? ColourBurnSub (B, 2.0 * F)
                    : ColourDodgeSub (B, 2.0 * (F - 0.5));
}

float LinearLightSub (float B, float F)
// Burns or dodges the channels depending on the F value.
{
   return F <= 0.5 ? LinearBurnSub (B, 2.0 * F)
                    : LinearDodgeSub (B, 2.0 * (F - 0.5));
}

float PinLightSub (float B, float F)
// Replaces the channel values, depending on the F channel.
{
   F *= 2.0;

   if (B > F) return F;
   else F -= 1.0;

   return B < F ? F : B;
}

float HardMixSub (float B, float F)
// Add F to B and if the result is 1 or greater, return 1, otherwise return 0.
{
   return step (1.0, B + F);
}

float DivideSub (float B, float F)
// If F is less than or equal to 0 return 1, otherwise divide B by F.
{
   return F > 0.0 ? min (1.0, B / F) : 1.0;
}

//---------------------------  Functions for HSL-based effects  ---------------------------//

float3 SetLuma (float3 abc, float lum)
{
   float diff = lum - dot (abc, LUM);

   abc.rgb += diff.xxx;

   lum = dot (abc, LUM);

   float RGBmin = min (abc.r, min (abc.g, abc.b));
   float RGBmax = max (abc.r, max (abc.g, abc.b));

   return RGBmin < 0.0 ? lerp (lum.xxx, abc, lum / (lum - RGBmin)) :
          RGBmax > 1.0 ? lerp (lum.xxx, abc, (1.0 - lum) / (RGBmax - lum)) : abc;
}

float GetSat (float3 abc)
{
   return max (abc.r, max (abc.g, abc.b)) - min (abc.r, min (abc.g, abc.b));
}

float3 SetSatRange (float3 abc, float sat)
// Set saturation if colour components are sorted in ascending order.
{
   if (abc.z > abc.x) {
      abc.y = ((abc.y - abc.x) * sat) / (abc.z - abc.x);
      abc.z = sat;
   }
   else {
      abc.y = 0.0;
      abc.z = 0.0;
   }

   abc.x = 0.0;

   return abc;
}

float3 SetSat (float3 abc, float sat)
{
   if ((abc.r <= abc.g) && (abc.r <= abc.b)) {
      if  (abc.g <= abc.b) { abc.rgb = SetSatRange (abc.rgb, sat); }
      else abc.rbg = SetSatRange (abc.rbg, sat);
   }
   else if ((abc.g <= abc.r) && (abc.g <= abc.b)) {
      if  (abc.r <= abc.b)
         abc.grb = SetSatRange (abc.grb, sat);
      else abc.gbr = SetSatRange (abc.gbr, sat);
   }
   else {
      if (abc.r <= abc.g)
         abc.brg = SetSatRange (abc.brg, sat);
      else abc.bgr = SetSatRange (abc.bgr, sat);
   }

   return abc;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Normal)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);
   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Export)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);
   float4 retval = float4 (lerp (0.0.xxx, Fgnd.rgb, Fgnd.a), Fgnd.a);

   return lerp (_TransparentBlack, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Dummy_0)
{ return ReadPixel (Bg, uv3); }

//--------------------------------------- GROUP 1 -----------------------------------------//

DeclareEntryPoint (Darken)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.rgb = min (Fgnd.rgb, Bgnd.rgb);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Multiply)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.rgb *= Bgnd.rgb;

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (ColourBurn)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.r = ColourBurnSub (Bgnd.r, Fgnd.r);
   Fgnd.g = ColourBurnSub (Bgnd.g, Fgnd.g);
   Fgnd.b = ColourBurnSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (LinearBurn)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.r = LinearBurnSub (Bgnd.r, Fgnd.r);
   Fgnd.g = LinearBurnSub (Bgnd.g, Fgnd.g);
   Fgnd.b = LinearBurnSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (DarkerColour)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   float luma = dot (Bgnd, LUMA);

   Fgnd.rgb = luma <= dot (Fgnd, LUMA) ? Bgnd.rgb : Fgnd.rgb;

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Dummy_1)
{ return ReadPixel (Bg, uv3); }

//--------------------------------------- GROUP 2 -----------------------------------------//

DeclareEntryPoint (Lighten)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.rgb = max (Fgnd.rgb, Bgnd.rgb);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Screen)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb));

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (ColourDodge)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.r = ColourDodgeSub (Bgnd.r, Fgnd.r);
   Fgnd.g = ColourDodgeSub (Bgnd.g, Fgnd.g);
   Fgnd.b = ColourDodgeSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (LinearDodge)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.r = LinearDodgeSub (Bgnd.r, Fgnd.r);
   Fgnd.g = LinearDodgeSub (Bgnd.g, Fgnd.g);
   Fgnd.b = LinearDodgeSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (LighterColour)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   float luma  = dot (Bgnd, LUMA);

   Fgnd.rgb = luma > dot (Fgnd, LUMA) ? Bgnd.rgb : Fgnd.rgb;

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Dummy_2)
{ return ReadPixel (Bg, uv3); }

//--------------------------------------- GROUP 3 -----------------------------------------//

DeclareEntryPoint (Overlay)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.r = OverlaySub (Bgnd.r, Fgnd.r);
   Fgnd.g = OverlaySub (Bgnd.g, Fgnd.g);
   Fgnd.b = OverlaySub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (SoftLight)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.r = SoftLightSub (Bgnd.r, Fgnd.r);
   Fgnd.g = SoftLightSub (Bgnd.g, Fgnd.g);
   Fgnd.b = SoftLightSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (HardLight)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.r = HardLightSub (Bgnd.r, Fgnd.r);
   Fgnd.g = HardLightSub (Bgnd.g, Fgnd.g);
   Fgnd.b = HardLightSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (VividLight)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.r = VividLightSub (Bgnd.r, Fgnd.r);
   Fgnd.g = VividLightSub (Bgnd.g, Fgnd.g);
   Fgnd.b = VividLightSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (LinearLight)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.r = LinearLightSub (Bgnd.r, Fgnd.r);
   Fgnd.g = LinearLightSub (Bgnd.g, Fgnd.g);
   Fgnd.b = LinearLightSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (PinLight)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.r = PinLightSub (Bgnd.r, Fgnd.r);
   Fgnd.g = PinLightSub (Bgnd.g, Fgnd.g);
   Fgnd.b = PinLightSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (HardMix)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.r = HardMixSub (Bgnd.r, Fgnd.r);
   Fgnd.g = HardMixSub (Bgnd.g, Fgnd.g);
   Fgnd.b = HardMixSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Dummy_3)
{ return ReadPixel (Bg, uv3); }

//--------------------------------------- GROUP 4 -----------------------------------------//

DeclareEntryPoint (Difference)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.rgb = abs (Fgnd.rgb - Bgnd.rgb);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Exclusion)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb - (2.0 * Bgnd.rgb * Fgnd.rgb));

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Subtract)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.rgb = max (Bgnd.rgb - Fgnd.rgb, 0.0.xxx);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Divide)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.r = DivideSub (Bgnd.r, Fgnd.r);
   Fgnd.g = DivideSub (Bgnd.g, Fgnd.g);
   Fgnd.b = DivideSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Dummy_4)
{ return ReadPixel (Bg, uv3); }

//--------------------------------------- GROUP 5 -----------------------------------------//

DeclareEntryPoint (Hue)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.rgb = SetLuma (SetSat (Fgnd.rgb, GetSat (Bgnd.rgb)), dot (Bgnd, LUMA));

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Saturation)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.rgb = SetLuma (SetSat (Bgnd.rgb, GetSat (Fgnd.rgb)), dot (Bgnd, LUMA));

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Colour)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.rgb = SetLuma (Fgnd.rgb, dot (Bgnd, LUMA));

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Luminosity)
{
   float4 Bgnd, Fgnd = initLogic (uv1, uv2, uv3, Bgnd);

   Fgnd.rgb = SetLuma (Bgnd.rgb, dot (Fgnd, LUMA));

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}
