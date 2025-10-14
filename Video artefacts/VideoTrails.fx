// @Maintainer jwrl
// @Released 2025-10-14
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
// Modified 2025-10-14 jwrl.
// Removed SetTechnique, which in turn enabled the removal of a heap of functions.  The
// end result is very much faster compile times with very little impact on execution.
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
DeclareIntParam   (FgTechnique,  "Fg blend mode", kNoGroup,      0, "Normal|Lumakey|Chromakey|Darken|Multiply|Colour Burn|Linear burn|Darker colour|Lighten|Screen|Colour Dodge|Add|Lighter colour|Overlay|Soft light|Hard light|Vivid light|Linear Light|Pin Light|Hard Mix");

DeclareIntParam   (BgTechnique,  "Bg blend mode", "Backgrounds", 0, "Same as Foreground|Normal|Lumakey|Chromakey|Darken|Multiply|Colour Burn|Linear burn|Darker colour|Lighten|Screen|Colour Dodge|Add|Lighter colour|Overlay|Soft light|Hard light|Vivid light|Linear Light|Pin Light|Hard Mix");
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

#define LUM  float3(0.2989, 0.5866, 0.1145)
#define LUMA float4(0.2989, 0.5866, 0.1145, 0.0)

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

   // Normally with a loop size of 13 we would divide by 14, viz, loop size plus one.
   // Here the divisor is 27 because sampling has been doubled in each loop pass.

   retval /= 27;

   return retval;
}

//--------------------------------------  Bg loader  --------------------------------------//

float4 getBg (sampler B, float2 uv, float d, bool sw)
{
   float4 retval;

   if (sw) { retval = _TransparentBlack; }   // If sw is on return transparent black.
   else {
      // Check if the background is using FgTechnique.  If not use BgTechnique minus
      // one so that the indexing matches BlendMode indexing.

      int BlendChoice = BgTechnique == 0 ? FgTechnique :  BgTechnique - 1;

      retval = TransformVid (B, uv, d, BlendChoice);
   }

   return retval;
}

//--------------------------------  Blend mode selection  ---------------------------------//

float4 BlendMode (float4 X, float4 Y, float amount, int Method)
{
   // This function is necessary because we are not using SetTechnique.  Even if we
   // were it would still be needed to independently set the blend modes for Bg and Fg.

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

DeclarePass (Fgd)
{
   float4 retval = ReadPixel (Fg, uv1);

   return float4 (retval.rgb, MakeKey (retval, FgTechnique));
}

DeclarePass (Bg1)
{ return getBg (B1, uv2, 1.0, (Tracks == 2) && OpaqueOutput); }

DeclarePass (Bg2)
{ return getBg (B2, uv3, 2.0, ((Tracks == 1) && OpaqueOutput) || (Tracks == 2)); }

DeclarePass (Bg3)
{ return getBg (B3, uv4, 3.0, (Tracks > 0) || OpaqueOutput); }

DeclarePass (Bgd)
{
   float4 B_1 = (Tracks == 2) && OpaqueOutput ? ReadPixel (B1, uv2) : BlurVid (Bg1, uv5, 1.0);
   float4 B_2 = (Tracks == 1) && OpaqueOutput ? ReadPixel (B2, uv3) : BlurVid (Bg2, uv5, 2.0);
   float4 B_3 = (Tracks == 0) && OpaqueOutput ? ReadPixel (B3, uv4) : BlurVid (Bg3, uv5, 3.0);

   int BlendTechnique = BgTechnique == 0 ? FgTechnique :  BgTechnique - 1;

   float amount1 = BgLevels;
   float amount2 = amount1 * BgLevels;

   if (Tracks == 0) {
      if (!OpaqueOutput) {
          float amount3 = amount2 * BgLevels;

         if ((BlendTechnique == 1) || (BlendTechnique == 2)) {
            B_3 = BlendMode (B_3, _TransparentBlack, amount3, BlendTechnique);
         }
         else B_3 *= amount3;
      }

      B_3 = BlendMode (B_3, B_2, amount2, BlendTechnique);
      B_3 = BlendMode (B_3, B_1, amount1, BlendTechnique);
   }
   else if (Tracks == 1) {
      if (!OpaqueOutput) B_2 *= amount2;

      B_3 = BlendMode (B_2, B_1, amount1, BlendTechnique);
   }
   else {
      if (OpaqueOutput) { B_3 = B_1; }
      else B_3 = B_1 * amount1;
   }

   return B_3;
}

DeclareEntryPoint (VideoTrails)
{
   float2 xy = scaleXY (uv5, ZoomSize, Zpos_X, Zpos_Y, 1.0);

   float4 Bgnd   = tex2D (Bgd, xy);
   float4 Fgnd   = tex2D (Fgd, xy);
   float4 retval = lerp (_TransparentBlack, Fgnd, tex2D (Mask, uv5).x);

   retval = BlendMode (Bgnd, Fgnd, FgOpacity, FgTechnique);

   return OpaqueOutput ? float4 (retval.rgb, 1.0) : retval;
}
