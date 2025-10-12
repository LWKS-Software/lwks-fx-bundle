// @Maintainer jwrl
// @Released 2025-10-12
// @Author jwrl
// @Created 2025-10-12

/**
 This effect is designed to apply a mini transform effect to three background video
 sources.  The intention is to use it with a series of delayed video sources to create
 the classic video feedback effect.  It can be daisy chained to add visual complexity.
 If the result that you get isn't visually very interesting it's usually because the
 images used have low contrast and/or high luminance. You will get the best results
 with high contrast images, or better still, transparent images.  If in doubt, try the
 luminance key or chromakey settings.

 The three background layers can be blurred, scaled, cropped and / or positioned with
 the one common set of controls. The effect of those controls is cumulative.  For
 example, if B1 is moved vertically by 10 pixels, B2 will move by 20 and B3 by 30.
 The combined output of the effect can be zoomed and / or positioned in a similar way
 to the Lightworks zoom effect.

   [*] Foreground:  Adjusts the mix of the foreground over the transformed background.
   [*] Key clip:  Self explanatory.  Only active in the key modes.
   [*] Key softness:  Self explanatory.  Only active in the key modes.
   [*] Key invert:  Self explanatory.  Only active in the key modes.
   [*] Key colour:  Self explanatory.  Only active in chromakey mode.
   [*] Fg blend mode:  Selects from Normal, Lumakey, Chromakey, Darken, Multiply,
       Colour Burn, Linear burn, Darker colour, Lighten, Screen, Colour Dodge, Add,
       Lighter Colour, Overlay, Soft Light, Hard Light, Linear Light, Pin Light or
       Hard Mix blend modes.
   [*] Backgrounds
      [*] Bg blend mode:  Uses the foreground blend settings or else independently
          selects from the same range of blends available to the foreground.
      [*] Use bg tracks:  Allows enabling or disabling B2 and / or B3 layers.
      [*] Bg levels:  Adjusts the background opacity.
      [*] Softness:  Softens the background slightly or the softens the lumakey.  It's
          not intended to produce really strong blurs because this would destroy multi
          layer versions of the effect.
      [*] Scale:  Scales the backgrounds.  This has the same reduction range of the
          transform effect, but can only double enlargement size.
      [*] Position X:  Adjusts the horizontal position of the background.
      [*] Position Y:  Adjusts the vertical position of the background.
      [*] Opaque output:  Disables or enables blend result transparency.  When enabled it
          will make the lowest active background layer opaque, full size and uncropped.
   [*] Crop
      [*] Left:  Crops the left side of the background.
      [*] Top:  Crops the top edge of the background.
      [*] Right:  Crops the right side of the background.
      [*] Bottom:  Crops the bottom edge of the background.
   [*] Zoom
      [*] Size:  Zooms in up to ten times on the master effect.
      [*] Position X:  Adjusts the horizontal position of the master effect.
      [*] Position Y:  Adjusts the vertical position of the master effect.

 The luminance key is similar to, but not the same as the Lightworks luminance effect.
 Because it's accessed via the blend mode settings it can be applied to all four layers,
 just the foreground or just the three background layers.  It uses the term "Key clip"
 instead of the "Tolerance" that Lightworks uses, but functions in the same way.  It's
 based on the Analogue lumakey effect in the Key Extras library.  Key softness is similar
 to that adjustment in the Lightworks lumakey.

 The other keying component supplied is a very much cutdown version of a chromakeyer.
 It shares the key clip and softness controls that the luminance key uses, but adds a
 colour selection panel.  While extremely simple, it should be adequate for the needs
 of this effect.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VideoTrails.fx
//
// Created 2025-10-12 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Video trails", "Stylize", "Video artefacts", "Produces video trails up to three layers deep", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, B1, B2, B3);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (FgOpacity,    "Foreground",    kNoGroup,      kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (KeyClip,      "Key clip",      kNoGroup,      kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (KeySoftness,  "Key softness",  kNoGroup,      kNoFlags, 0.2, 0.0, 1.0);
DeclareBoolParam  (KeyInvert,    "Key invert",    kNoGroup,      false);
DeclareColourParam (KeyColour,   "Key colour",    kNoGroup,      kNoFlags, 0.0, 0.8, 0.0, 1.0);
DeclareIntParam   (FgBlendMode,  "Fg blend mode", kNoGroup,      0, "Normal|Lumakey|Chromakey|Darken|Multiply|Colour Burn|Linear burn|Darker colour|Lighten|Screen|Colour Dodge|Add|Lighter colour|Overlay|Soft light|Hard light|Vivid light|Linear Light|Pin Light|Hard Mix");

DeclareIntParam   (SetTechnique, "Bg blend mode", "Backgrounds", 0, "Same as Foreground|Normal|Lumakey|Chromakey|Darken|Multiply|Colour Burn|Linear burn|Darker colour|Lighten|Screen|Colour Dodge|Add|Lighter colour|Overlay|Soft light|Hard light|Vivid light|Linear Light|Pin Light|Hard Mix");
DeclareIntParam   (Tracks,       "Use bg tracks", "Backgrounds", 0, "B1, B2 and B3|B1 and B2|B1 only");
DeclareFloatParam (BgLevels,     "Bg levels",     "Backgrounds", kNoFlags, 0.9,  0.0, 1.0);
DeclareFloatParam (Softness,     "Softness",      "Backgrounds", kNoFlags, 0.05, 0.0, 1.0);
DeclareFloatParam (Scale,        "Scale",         "Backgrounds", "DisplayAsPercentage", 0.85, 0.5, 2.0);
DeclareFloatParam (Pos_X,        "Position X",    "Backgrounds", "DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (Pos_Y,        "Position Y",    "Backgrounds", "DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareBoolParam  (OpaqueOutput, "Opaque output", "Backgrounds", false);

DeclareFloatParam (CropLeft,     "Left",          "Crop",        kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (CropTop,      "Top",           "Crop",        kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (CropRight,    "Right",         "Crop",        kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (CropBottom,   "Bottom",        "Crop",        kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (ZoomSize,     "Size",          "Zoom",        kNoFlags, 1.0,  1.0, 10.0);
DeclareFloatParam (Zpos_X,       "Position",      "Zoom",        "SpecifiesPointX", 0.5, -5.0, 5.0);
DeclareFloatParam (Zpos_Y,       "Position",      "Zoom",        "SpecifiesPointY", 0.5, -5.0, 5.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LUM     float3(0.2989, 0.5866, 0.1145)
#define LUMA    float4(0.2989, 0.5866, 0.1145, 0.0)

float4 _TransparentBlack = 0.0.xxxx;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 mirror2D (sampler S, float2 xy)
// Provides mirror addressing for media locked to sequence coords.
{
   float2 uv = 1.0.xx - abs (abs (xy) - 1.0.xx);

   return tex2D (S, uv);
}

//--------------------------------  Colour blend modules  ---------------------------------//

float ColourBurnSub (float B, float F)
// Increases contrast to darken the B channel based on the F channel.
{
   return B >= 1.0 ? 1.0 : F <= 0.0 ? 0.0 : 1.0 - min (1.0, (1.0 - B) / F);
}

float ColourDodgeSub (float B, float F)
// Brightens the B channel using the F channel to decrease contrast.
{
   return B <= 0.0 ? 0.0 : F >= 1.0 ? 1.0 : min (1.0, B / (1.0 - F));
}

float LinearBurnSub (float B, float F)
// Decreases brightness of the summed B and F channels to darken the output.
{
   return max (0.0, B + F - 1.0);
}

float LinearDodgeSub (float B, float F)
// Sums B and F channels and limits them to a maximum of 1.
{
   return min (1.0, B + F);
}

//-------------------------------  Subroutines for blends  --------------------------------//

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
   return F <= 0.5 ? ColourBurnSub  (B, 2.0 * F)
                   : ColourDodgeSub (B, 2.0 * (F - 0.5));
}

float LinearLightSub (float B, float F)
// Burns or dodges the channels depending on the F value.
{
   return F <= 0.5 ? max (0.0, (2.0 * F) + B - 1.0)
                   : min (1.0, (2.0 * F) + B - 1.0);
}

float PinLightSub (float B, float F)
// Replaces the channel values, depending on the F channel.
{
   F *= 2.0;

   if (B > F) return F;
   else F -= 1.0;

   return B < F ? F : B;
}

//--------------------------------  Functions for blends  ---------------------------------//

float4 NormalMode (float4 B, float4 F, float Amount)
{
   float4 retval = float4 (lerp (B, F, F.a).rgb, max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 DarkenMode (float4 B, float4 F, float Amount)
{
   float4 retval = float4 (lerp (B.rgb, min (F.rgb, B.rgb), F.a), max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 MultiplyMode (float4 B, float4 F, float Amount)
{
   float4 retval = float4 (lerp (B.rgb, (F * B).rgb, F.a), max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 ColourBurnMode (float4 B, float4 F, float Amount)
{
   F.r = ColourBurnSub (B.r, F.r);
   F.g = ColourBurnSub (B.g, F.g);
   F.b = ColourBurnSub (B.b, F.b);

   float4 retval = float4 (lerp (B.rgb, F.rgb, F.a), max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 LinearBurnMode (float4 B, float4 F, float Amount)
{
   F.r = max (0.0, B.r + F.r - 1.0);
   F.g = max (0.0, B.g + F.g - 1.0);
   F.b = max (0.0, B.b + F.b - 1.0);

   float4 retval = float4 (lerp (B, F, F.a).rgb, max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 DarkerColourMode (float4 B, float4 F, float Amount)
{
   float Bluma = dot (B, LUMA);
   float Fluma = dot (F, LUMA);

   F.rgb = Bluma <= Fluma ? B.rgb : F.rgb;

   float4 retval = float4 (lerp (B, F, F.a).rgb, max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 LightenMode (float4 B, float4 F, float Amount)
{
   float4 retval = float4 (lerp (B.rgb, max (F.rgb, B.rgb), F.a), max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 ScreenMode (float4 B, float4 F, float Amount)
{
   float4 retval = float4 (lerp (B.rgb, saturate (F.rgb + B.rgb - (F * B).rgb), F.a), max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 ColourDodgeMode (float4 B, float4 F, float Amount)
{
   F.r = ColourDodgeSub (B.r, F.r);
   F.g = ColourDodgeSub (B.g, F.g);
   F.b = ColourDodgeSub (B.b, F.b);

   float4 retval = float4 (lerp (B, F, F.a).rgb, max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 AddMode (float4 B, float4 F, float Amount)
{
   F.r = min (1.0, B.r + F.r);
   F.g = min (1.0, B.g + F.g);
   F.b = min (1.0, B.b + F.b);

   float4 retval = float4 (lerp (B, F, F.a).rgb, max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 LighterColourMode (float4 B, float4 F, float Amount)
{
   float B_luma = dot (B, LUMA);
   float F_luma = dot (F, LUMA);

   if (B_luma > F_luma) F.rgb = B.rgb;

   float4 retval = float4 (lerp (B, F, F.a).rgb, max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 OverlayMode (float4 B, float4 F, float Amount)
{
   F.r = OverlaySub (B.r, F.r);
   F.g = OverlaySub (B.g, F.g);
   F.b = OverlaySub (B.b, F.b);

   float4 retval = float4 (lerp (B, F, F.a).rgb, max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 SoftLightMode (float4 B, float4 F, float Amount)
{
   F.r = SoftLightSub (B.r, F.r);
   F.g = SoftLightSub (B.g, F.g);
   F.b = SoftLightSub (B.b, F.b);

   float4 retval = float4 (lerp (B, F, F.a).rgb, max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 HardLightMode (float4 B, float4 F, float Amount)
{
   F.r = HardLightSub (B.r, F.r);
   F.g = HardLightSub (B.g, F.g);
   F.b = HardLightSub (B.b, F.b);

   float4 retval = float4 (lerp (B, F, F.a).rgb, max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 VividLightMode (float4 B, float4 F, float Amount)
{
   F.r = VividLightSub (B.r, F.r);
   F.g = VividLightSub (B.g, F.g);
   F.b = VividLightSub (B.b, F.b);

   float4 retval = float4 (lerp (B, F, F.a).rgb, max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 LinearLightMode (float4 B, float4 F, float Amount)
{
   F.r = LinearLightSub (B.r, F.r);
   F.g = LinearLightSub (B.g, F.g);
   F.b = LinearLightSub (B.b, F.b);

   float4 retval = float4 (lerp (B, F, F.a).rgb, max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 PinLightMode (float4 B, float4 F, float Amount)
{
   F.r = PinLightSub (B.r, F.r);
   F.g = PinLightSub (B.g, F.g);
   F.b = PinLightSub (B.b, F.b);

   float4 retval = float4 (lerp (B, F, F.a).rgb, max (B.a, F.a));

   return lerp (B, retval, Amount);
}

float4 HardMixMode (float4 B, float4 F, float Amount)
{
   F.r = step (1.0, B.r + F.r);
   F.g = step (1.0, B.g + F.g);
   F.b = step (1.0, B.b + F.b);

   float4 retval = float4 (lerp (B, F, F.a).rgb, max (B.a, F.a));

   return lerp (B, retval, Amount);
}

//-------------------------------  Clip recovery and blur  --------------------------------//

float2 scaleXY (float2 xy, float scale, float pX, float pY, float d)
{
   // Scales and positions X-Y coordinates according to the layer number in d.

   float2 pXY = float2 (0.5 - pX, pY - 0.5) * d; // Scale the position
   float2 uv = xy + pXY;   // Add the X-Y position to xy.

   uv -= 0.5.xx;           // Centre the X-Y coordinates
   uv /= pow (scale, d);   // Apply the scale corrected for depth

   return uv + 0.5.xx;     // Return the scaled and corrected coordinates
}

float MakeKey (float4 video, int keyType)
{
   float alpha;

   if (keyType == 1) { alpha = dot (video, LUMA) + (KeySoftness * 0.5); }
   else if (keyType == 2) { alpha = distance (KeyColour.rgb, video.rgb); }
   else return video.a;

   float range = max (1.0e-6, KeySoftness);  // Prevents divide by zero (NAN).

   // Limit alpha to over Keyclip then produce the key softness by dividing alpha
   // by the softness range.  The alpha result is then limited to legal values.

   alpha = saturate ((alpha - KeyClip) / range);

   if (KeyInvert) alpha = 1.0 - alpha;       // Invert the key if necessary.

   return alpha * video.a;                   // Blend key with input video alpha.
}

float4 TransformVid (sampler S, float2 uv, float depth, int keygen)
{
   // This is a mini transform which scales and offsets the video referenced by S.
   // The amount is adjusted according to depth.  First scale the X-Y coordinates.

   float2 xy = scaleXY (uv, Scale, Pos_X, Pos_Y, depth);

   float L = CropLeft * depth;               // Scale the left crop value
   float R = 1.0 - (CropRight * depth);      // Scale and invert the right crop
   float T = CropTop * depth;                // Scale the top crop
   float B = 1.0 - (CropBottom * depth);     // Scale and invert the bottom crop

   // Now crop the video and return transparent black if outside crop bounds.

   float4 retval = (xy.x < L) || (xy.x > R) || (xy.y < T) || (xy.y > B)
                 ? _TransparentBlack : ReadPixel (S, xy);

   retval.a  = MakeKey (retval, keygen);

   return retval;
}

float4 BlurVid (sampler Vid, float2 uv, float depth)
{
   // This blurs the background video referenced by Vid according to the softness
   // and depth.

   float4 retval = mirror2D (Vid, uv);

   float2 radius = float2 (1.0, _OutputAspectRatio) * Softness * 0.01333333;
   float2 xy, xy1, xy2;

   float angle = 0.0;

   radius *= depth;                    // Scale the blur radius by the depth.

   // What follows is the standard radial blur loop sampled at 13.85 degrees intervals.
   // Get a full 360 degree rotation by adding and subtracting the radial offset to uv.

   for (int i = 0; i < 13; i++) {
      sincos (angle, xy.x, xy.y);      // Put the sine of angle in xy.x and the cos in xy.y
      xy     *= radius;                // Scale the radius by by the xy trig values.
      xy1     = uv + xy;               // Add the scaled trig values to the pixel address
      xy2     = uv - xy;               // Also subtract them from the pixel address
      retval += mirror2D (Vid, xy1);   // Add the pixel pointed to by xy1 to retval
      retval += mirror2D (Vid, xy2);   // Add the pixel pointed to by xy2 also
      angle  += 0.24166097;            // Increment the angle by 13.85 degrees in radians.
   }

   retval   /= 27;                     // The loop is 26 because sampling has been doubled.

   return retval;
}

float4 BlurB1 (sampler A, float2 xy1, sampler B, float2 xy2)
{ return (Tracks == 2) && OpaqueOutput ? ReadPixel (A, xy1) : BlurVid (B, xy2, 1.0); }

float4 BlurB2 (sampler A, float2 xy1, sampler B, float2 xy2)
{ return (Tracks == 1) && OpaqueOutput ? ReadPixel (A, xy1) : BlurVid (B, xy2, 2.0); }

float4 BlurB3 (sampler A, float2 xy1, sampler B, float2 xy2)
{ return (Tracks == 0) && OpaqueOutput ? ReadPixel (A, xy1) : BlurVid (B, xy2, 3.0); }

float4 FgVideo (sampler S, float2 uv, int keyBg)
{
   float4 retval = ReadPixel (S, uv);

  float keyFg = FgBlendMode == 0 ? keyBg : FgBlendMode;

   retval.a  = MakeKey (retval, keyFg);

   return retval;
}

//--------------------------------  Blend mode selection  ---------------------------------//

float4 BlendMode (float4 X, float4 Y, float amount, int Method)
{
   // This function is necessary because we cannot use SetTechnique twice, which would
   // be the only way to independently set the blend mode for Fg from the other 3 inputs.

   if (Method == 3)  return DarkenMode (X, Y, amount);
   if (Method == 4)  return MultiplyMode (X, Y, amount);
   if (Method == 5)  return ColourBurnMode (X, Y, amount);
   if (Method == 6)  return LinearBurnMode (X, Y, amount);
   if (Method == 7)  return DarkerColourMode (X, Y, amount);
   if (Method == 8)  return LightenMode (X, Y, amount);
   if (Method == 9)  return ScreenMode (X, Y, amount);
   if (Method == 10) return ColourDodgeMode (X, Y, amount);
   if (Method == 11) return AddMode (X, Y, amount);
   if (Method == 12) return LighterColourMode (X, Y, amount);
   if (Method == 13) return OverlayMode (X, Y, amount);
   if (Method == 14) return SoftLightMode (X, Y, amount);
   if (Method == 15) return HardLightMode (X, Y, amount);
   if (Method == 16) return VividLightMode (X, Y, amount);
   if (Method == 17) return LinearLightMode (X, Y, amount);
   if (Method == 18) return PinLightMode (X, Y, amount);
   if (Method == 19) return HardMixMode (X, Y, amount);

   return NormalMode (X, Y, amount);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

//-----  Same as Foreground  --------------------------------------------------------------//

DeclarePass (B3_0)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, FgBlendMode); }

DeclarePass (B2_0)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, FgBlendMode); }

DeclarePass (B1_0)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, FgBlendMode); }

DeclarePass (Fg_0)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_0)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_0, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_0, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_0, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      float amount3 = amount2 * BgLevels;

      if (!OpaqueOutput) {
         if ((FgBlendMode == 1) || (FgBlendMode == 2)) {
            B_3 = BlendMode (B_3, _TransparentBlack, amount3, FgBlendMode);
         }
         else B_3 *= amount3;
      }

      B_3 = BlendMode (B_3, B_2, amount2, FgBlendMode);
      B_3 = BlendMode (B_3, B_1, amount1, FgBlendMode);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = BlendMode (B_2, B_1, amount1, FgBlendMode);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (Default)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_0, xy);
   float4 Fgnd   = tex2D (Fg_0, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Normal  --------------------------------------------------------------------------//

DeclarePass (B3_1)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_1)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_1)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_1)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_1)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_1, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_1, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_1, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = NormalMode (B_3, B_2, amount2);
      B_3 = NormalMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = NormalMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (Normal)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_1, xy);
   float4 Fgnd   = tex2D (Fg_1, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----------------------------------------------------------------------------------------//

//-----  Lumakey  -------------------------------------------------------------------------//

DeclarePass (B3_2)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 1); }

DeclarePass (B2_2)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 1); }

DeclarePass (B1_2)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 1); }

DeclarePass (Fg_2)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_2)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_2, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_2, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_2, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 = NormalMode (B_3, _TransparentBlack, amount2 * BgLevels);

      B_3 = NormalMode (B_3, B_2, amount2);
      B_3 = NormalMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = NormalMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (Lumakey)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_2, xy);
   float4 Fgnd   = tex2D (Fg_2, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Chromakey  -----------------------------------------------------------------------//

DeclarePass (B3_3)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 2); }

DeclarePass (B2_3)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 2); }

DeclarePass (B1_3)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 2); }

DeclarePass (Fg_3)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_3)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_3, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_3, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_3, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 = NormalMode (B_3, _TransparentBlack, amount2 * BgLevels);

      B_3 = NormalMode (B_3, B_2, amount2);
      B_3 = NormalMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = NormalMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (Chromakey)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_3, xy);
   float4 Fgnd   = tex2D (Fg_3, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----------------------------------------------------------------------------------------//

//-----  Darken  --------------------------------------------------------------------------//

DeclarePass (B3_4)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_4)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_4)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_4)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_4)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_4, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_4, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_4, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = DarkenMode (B_3, B_2, amount2);
      B_3 = DarkenMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = DarkenMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (Darken)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_4, xy);
   float4 Fgnd   = tex2D (Fg_4, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Multiply  ------------------------------------------------------------------------//

DeclarePass (B3_5)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_5)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_5)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_5)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_5)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_5, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_5, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_5, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = MultiplyMode (B_3, B_2, amount2);
      B_3 = MultiplyMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = MultiplyMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (Multiply)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_5, xy);
   float4 Fgnd   = tex2D (Fg_5, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Colour Burn  ---------------------------------------------------------------------//

DeclarePass (B3_6)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_6)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_6)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_6)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_6)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_6, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_6, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_6, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = ColourBurnMode (B_3, B_2, amount2);
      B_3 = ColourBurnMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = ColourBurnMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (ColourBurn)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_6, xy);
   float4 Fgnd   = tex2D (Fg_6, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Linear Burn  ---------------------------------------------------------------------//

DeclarePass (B3_7)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_7)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_7)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_7)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_7)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_7, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_7, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_7, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = LinearBurnMode (B_3, B_2, amount2);
      B_3 = LinearBurnMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = LinearBurnMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (LinearBurn)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_7, xy);
   float4 Fgnd   = tex2D (Fg_7, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Darker Colour  ------------------------------------------------------------------//

DeclarePass (B3_8)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_8)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_8)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_8)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_8)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_8, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_8, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_8, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = DarkerColourMode (B_3, B_2, amount2);
      B_3 = DarkerColourMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = DarkerColourMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (DarkerColour)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_8, xy);
   float4 Fgnd   = tex2D (Fg_8, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----------------------------------------------------------------------------------------//

//-----  Lighten  -------------------------------------------------------------------------//

DeclarePass (B3_9)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_9)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_9)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_9)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_9)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_9, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_9, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_9, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = LightenMode (B_3, B_2, amount2);
      B_3 = LightenMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = LightenMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (Lighten)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_9, xy);
   float4 Fgnd   = tex2D (Fg_9, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Screen  --------------------------------------------------------------------------//

DeclarePass (B3_10)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_10)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_10)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_10)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_10)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_10, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_10, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_10, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = ScreenMode (B_3, B_2, amount2);
      B_3 = ScreenMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = ScreenMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (Screen)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_10, xy);
   float4 Fgnd   = tex2D (Fg_10, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Colour Dodge  --------------------------------------------------------------------//

DeclarePass (B3_11)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_11)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_11)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_11)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_11)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_11, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_11, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_11, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = ColourDodgeMode (B_3, B_2, amount2);
      B_3 = ColourDodgeMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = ColourDodgeMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (ColourDodge)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_11, xy);
   float4 Fgnd   = tex2D (Fg_11, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Add  -----------------------------------------------------------------------------//

DeclarePass (B3_12)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_12)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_12)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_12)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_12)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_12, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_12, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_12, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = AddMode (B_3, B_2, amount2);
      B_3 = AddMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = AddMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (Add)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_12, xy);
   float4 Fgnd   = tex2D (Fg_12, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Lighter Colour  ------------------------------------------------------------------//

DeclarePass (B3_13)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_13)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_13)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_13)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_13)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_13, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_13, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_13, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = LighterColourMode (B_3, B_2, amount2);
      B_3 = LighterColourMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = LighterColourMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (LighterColour)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_13, xy);
   float4 Fgnd   = tex2D (Fg_13, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----------------------------------------------------------------------------------------//

//-----  Overlay  -------------------------------------------------------------------------//

DeclarePass (B3_14)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_14)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_14)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_14)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_14)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_14, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_14, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_14, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = OverlayMode (B_3, B_2, amount2);
      B_3 = OverlayMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = OverlayMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (Overlay)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_14, xy);
   float4 Fgnd   = tex2D (Fg_14, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Soft Light  ---------------------------------------------------------------------//

DeclarePass (B3_15)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_15)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_15)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_15)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_15)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_15, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_15, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_15, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = SoftLightMode (B_3, B_2, amount2);
      B_3 = SoftLightMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = SoftLightMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (SoftLight)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_15, xy);
   float4 Fgnd   = tex2D (Fg_15, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Hard Light  ----------------------------------------------------------------------//

DeclarePass (B3_16)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_16)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_16)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_16)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_16)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_16, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_16, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_16, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = HardLightMode (B_3, B_2, amount2);
      B_3 = HardLightMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = HardLightMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (HardLight)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_16, xy);
   float4 Fgnd   = tex2D (Fg_16, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Vivid Light  ---------------------------------------------------------------------//

DeclarePass (B3_17)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_17)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_17)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_17)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_17)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_17, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_17, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_17, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = VividLightMode (B_3, B_2, amount2);
      B_3 = VividLightMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = VividLightMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (VividLight)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_17, xy);
   float4 Fgnd   = tex2D (Fg_17, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Linear Light  --------------------------------------------------------------------//

DeclarePass (B3_18)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_18)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_18)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_18)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_18)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_18, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_18, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_18, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = LinearLightMode (B_3, B_2, amount2);
      B_3 = LinearLightMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = LinearLightMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (LinearLight)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_18, xy);
   float4 Fgnd   = tex2D (Fg_18, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Pin Light  -----------------------------------------------------------------------//

DeclarePass (B3_19)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_19)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_19)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_19)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_19)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_19, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_19, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_19, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = PinLightMode (B_3, B_2, amount2);
      B_3 = PinLightMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = PinLightMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (PinLight)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_19, xy);
   float4 Fgnd   = tex2D (Fg_19, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

//-----  Hard Mix  ------------------------------------------------------------------------//

DeclarePass (B3_20)
{ return (Tracks > 0) || OpaqueOutput ? _TransparentBlack : TransformVid (B3, uv4, 3.0, 0); }

DeclarePass (B2_20)
{ return ((Tracks == 1) && OpaqueOutput) || (Tracks == 2) ? _TransparentBlack : TransformVid (B2, uv3, 2.0, 0); }

DeclarePass (B1_20)
{ return (Tracks == 2) && OpaqueOutput ? _TransparentBlack : TransformVid (B1, uv2, 1.0, 0); }

DeclarePass (Fg_20)
{ return FgVideo (Fg, uv1, FgBlendMode); }

DeclarePass (Bg_20)
{
   float4 B_1 = BlurB1 (B1, uv2, B1_20, uv5);
   float4 B_2 = BlurB2 (B2, uv3, B2_20, uv5);
   float4 B_3 = BlurB3 (B3, uv4, B3_20, uv5);

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) B_3 *= amount2 * BgLevels;

      B_3 = HardMixMode (B_3, B_2, amount2);
      B_3 = HardMixMode (B_3, B_1, amount1);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = HardMixMode (B_2, B_1, amount1);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (HardMix)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bg_20, xy);
   float4 Fgnd   = tex2D (Fg_20, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgBlendMode);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}

