// @Maintainer jwrl
// @Released 2025-08-12
// @Author jwrl
// @Created 2018-06-15

/**
 "Enhanced blend" is a variant of the Lightworks blend effect which has been designed
 to emulate the full range of Photoshop blend modes as closely as possible.  You can
 also blend a transparent foreground with a transparent background and the effect
 will export a valid alpha channel of the combined vdeo sources.  This means that
 those combined sources can be used with further blend and transform effects.  It can
 deal directly with foreground inputs that are opaque or have transparency or can
 extract a blended foreground from its background using a difference key.

   * Source selection:  Selects between an extracted foreground, foreground video, image
     key or title, or pre LW 2023.2 image keys or titles.
   * Fg Opacity:  Allows the foreground to be faded in or out.
   * Blend mode:  The only difference between the blend modes used here and the Photoshop
     versions is that instead of "Dissolve" the choice is "Export foreground only".

 To elaborate on the source selection modes, if you choose not to extract a blended
 (transparent) foreground from its background you can use either of the image key or title
 modes, as long as you disconnect any input to the foreground.  There is a reminder to do
 this in the settings.  The pre LW 2023.2 choice improves blending when using titles or
 image keys with versions of Lightworks prior to 2023.2.
*/

//-----------------------------------------------------------------------------------------//
// User effect EnhancedBlend.fx
//
// Version history:
//
// Updated 2025-08-12 jwrl.
// Corrected a potential divide by zero bug when used with GLSL compilers.
//
// Updated 2025-07-31 jwrl.
// Reworked blend modes to better match Photoshop originals.
// Reversed source selection order, set default to "Video, image key or title".
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with float4 _TransparentBlack for Linux fix.
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-05-15 jwrl.
// Header reformatted.
//
// Conversion 2023-01-23 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Enhanced blend", "Mix", "Blend Effects", "This is a customised blend for use in conjunction with other effects.", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Source, "Source selection", "Disconnect title and image key inputs", 1, "Extracted foreground|Video, image key or title|Image key/Title pre LW 2023.2");

DeclareFloatParam (Amount, "Fg Opacity", "Disconnect title and image key inputs", kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Blend mode", "Disconnect title and image key inputs", 0, "Normal|Export foreground only|____________________|Darken|Multiply|Colour Burn|Linear Burn|Darker Colour|____________________|Lighten|Screen|Colour Dodge|Linear Dodge (Add)|Lighter Colour|____________________|Overlay|Soft Light|Hard Light|Vivid Light|Linear Light|Pin Light|Hard Mix|____________________|Difference|Exclusion|Subtract|Divide|____________________|Hue|Saturation|Colour|Luminosity");

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LUM   float3(0.2989, 0.5866, 0.1145)
#define LUMA  float4(LUM, 0.0)

float4 _TransparentBlack = 0.0.xxxx;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 initMedia (sampler F, float2 xy1, sampler B, float2 xy2, out float4 Bgd)
{
   Bgd = ReadPixel (B, xy2);

   // Instead of using ReadPixel for foreground recovery we check for bounds overflow, and
   // quit if so.  Doing this after recovering the background ensures that no unnecessary
   // processing will take place, but a valid foreground and background will be returned.

   if (IsOutOfBounds (xy1)) return _TransparentBlack;

   float4 Fgd = tex2D (F, xy1);

   if (Source == 0) {                  // Extracts foreground alpha using a difference key.
      Fgd.a    = saturate (distance (Bgd.rgb, Fgd.rgb) * 4.0);
      Fgd.rgb *= Fgd.a;
   }
   else if (Source == 2) Fgd.a = pow (Fgd.a, 0.5);    // Enhances alpha for 2022.1 titles.

   return Fgd;
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
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (ExportAlpha)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   float4 retval = float4 (lerp (0.0.xxx, Fgnd.rgb, Fgnd.a), Fgnd.a);

   return lerp (_TransparentBlack, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Dummy_1)
{ return ReadPixel (Bg, uv2); }

//--------------------------------------- GROUP 1 -----------------------------------------//

DeclareEntryPoint (Darken)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.rgb = min (Fgnd.rgb, Bgnd.rgb);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Multiply)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.rgb *= Bgnd.rgb;

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (ColourBurn)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.r = ColourBurnSub (Bgnd.r, Fgnd.r);
   Fgnd.g = ColourBurnSub (Bgnd.g, Fgnd.g);
   Fgnd.b = ColourBurnSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (LinearBurn)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.r = LinearBurnSub (Bgnd.r, Fgnd.r);
   Fgnd.g = LinearBurnSub (Bgnd.g, Fgnd.g);
   Fgnd.b = LinearBurnSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (DarkerColour)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   float luma = dot (Bgnd, LUMA);

   Fgnd.rgb = luma <= dot (Fgnd, LUMA) ? Bgnd.rgb : Fgnd.rgb;

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Dummy_2)
{ return ReadPixel (Bg, uv2); }

//--------------------------------------- GROUP 2 -----------------------------------------//

DeclareEntryPoint (Lighten)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.rgb = max (Fgnd.rgb, Bgnd.rgb);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Screen)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb));

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (ColourDodge)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.r = ColourDodgeSub (Bgnd.r, Fgnd.r);
   Fgnd.g = ColourDodgeSub (Bgnd.g, Fgnd.g);
   Fgnd.b = ColourDodgeSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (LinearDodge)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.r = LinearDodgeSub (Bgnd.r, Fgnd.r);
   Fgnd.g = LinearDodgeSub (Bgnd.g, Fgnd.g);
   Fgnd.b = LinearDodgeSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (LighterColour)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   float luma  = dot (Bgnd, LUMA);

   Fgnd.rgb = luma > dot (Fgnd, LUMA) ? Bgnd.rgb : Fgnd.rgb;

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Dummy_3)
{ return ReadPixel (Bg, uv2); }

//--------------------------------------- GROUP 3 -----------------------------------------//

DeclareEntryPoint (Overlay)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.r = OverlaySub (Bgnd.r, Fgnd.r);
   Fgnd.g = OverlaySub (Bgnd.g, Fgnd.g);
   Fgnd.b = OverlaySub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (SoftLight)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.r = SoftLightSub (Bgnd.r, Fgnd.r);
   Fgnd.g = SoftLightSub (Bgnd.g, Fgnd.g);
   Fgnd.b = SoftLightSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (HardLight)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.r = HardLightSub (Bgnd.r, Fgnd.r);
   Fgnd.g = HardLightSub (Bgnd.g, Fgnd.g);
   Fgnd.b = HardLightSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (VividLight)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.r = VividLightSub (Bgnd.r, Fgnd.r);
   Fgnd.g = VividLightSub (Bgnd.g, Fgnd.g);
   Fgnd.b = VividLightSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (LinearLight)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.r = LinearLightSub (Bgnd.r, Fgnd.r);
   Fgnd.g = LinearLightSub (Bgnd.g, Fgnd.g);
   Fgnd.b = LinearLightSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (PinLight)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.r = PinLightSub (Bgnd.r, Fgnd.r);
   Fgnd.g = PinLightSub (Bgnd.g, Fgnd.g);
   Fgnd.b = PinLightSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (HardMix)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.r = HardMixSub (Bgnd.r, Fgnd.r);
   Fgnd.g = HardMixSub (Bgnd.g, Fgnd.g);
   Fgnd.b = HardMixSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Dummy_4)
{ return ReadPixel (Bg, uv2); }

//--------------------------------------- GROUP 4 -----------------------------------------//

DeclareEntryPoint (Difference)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.rgb = abs (Fgnd.rgb - Bgnd.rgb);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Exclusion)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb - (2.0 * Bgnd.rgb * Fgnd.rgb));

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Subtract)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.rgb = max (Bgnd.rgb - Fgnd.rgb, 0.0.xxx);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Divide)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.r = DivideSub (Bgnd.r, Fgnd.r);
   Fgnd.g = DivideSub (Bgnd.g, Fgnd.g);
   Fgnd.b = DivideSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Dummy_5)
{ return ReadPixel (Bg, uv2); }

//--------------------------------------- GROUP 5 -----------------------------------------//

DeclareEntryPoint (Hue)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.rgb = SetLuma (SetSat (Fgnd.rgb, GetSat (Bgnd.rgb)), dot (Bgnd, LUMA));

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Sat)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.rgb = SetLuma (SetSat (Bgnd.rgb, GetSat (Fgnd.rgb)), dot (Bgnd, LUMA));

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Colour)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.rgb = SetLuma (Fgnd.rgb, dot (Bgnd, LUMA));

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

DeclareEntryPoint (Luma)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Bgnd);

   Fgnd.rgb = SetLuma (Bgnd.rgb, dot (Fgnd, LUMA));

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}
