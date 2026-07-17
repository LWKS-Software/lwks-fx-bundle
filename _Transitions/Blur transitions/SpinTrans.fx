// @Maintainer jwrl
// @Released 2026-07-17
// @Author rakusan
// @Author jwrl
// @Created 2016-02-15

/**
 The effect applies a rotary blur to transition into and out of aan image, and is
 based on original shader code by rakusan (http://kuramo.ch/webgl/videoeffects/).
 The direction, aspect ratio, centring and strength of the blur can all be adjusted.
 It can also be used with titles and other blended images.

   [*]Amount:  The normal keyframed transition progress.
   [*]Spin settings
      [*]Spin direction:  Sets the spin to be anticlockwise or clockwise.
      [*]Arc length:  Because this is a spin blur, the blur length is set in
         degrees of rotation.
      [*]Aspect 1:x:  Sets the aspect ratio.  Adjusting it will make the spin
         more or less ellipsoid.
      [*]Centre X:  Sets the horizontal centre point of the spin.
      [*]Centre Y:  Sets the vertical centre point of the spin.
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
// Lightworks user effect SpinTrans.fx
//
// Version history:
//
// Updated 2026-07-17 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Updated 2023-08-02 jwrl.
// Reworded source selection for 2023.2 settings.
//
// Updated 2023-06-08 jwrl.
// Added keyed foreground viewing to help set up delta key.
// Added delta key swap to correct routing problems.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Spin transition", "Mix", "Blur transitions", "Dissolves the images through a blurred spin", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",         kNoGroup,         kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam   (CW_CCW,         "Spin direction", "Spin settings",  1, "Anticlockwise|Clockwise");
DeclareFloatParam (blurLen,        "Arc length",     "Spin settings",  kNoFlags, 90.0, 0.0, 180.0);
DeclareFloatParam (aspectRatio,    "Aspect 1:x",     "Spin settings",  kNoFlags, 1.0, 0.01, 10.0);
DeclareFloatParam (CentreX,        "Centre",         "Spin settings",  "SpecifiesPointX", 0.5, -0.5, 1.5);
DeclareFloatParam (CentreY,        "Centre",         "Spin settings",  "SpecifiesPointY", 0.5, -0.5, 1.5);

DeclareBoolParam  (Blended,        "Enable blend transitions",         kNoGroup, false);

DeclareIntParam   (Source,         "Source",         "Blend settings", 0, "Extracted foreground|Image key or title (disconnect input)");
DeclareBoolParam  (SwapDir,        "Transition into blend",            "Blend settings", true);
DeclareFloatParam (KeyGain,        "Fine tune",      "Blend settings", kNoFlags, 0.25, 0.0, 1.0);
DeclareBoolParam  (ShowKey,        "Show foreground key",              "Blend settings", false);
DeclareBoolParam  (SwapSource,     "Swap sources",   "Blend settings", false);

DeclareFloatParam (_OutputAspectRatio);
DeclareFloatParam (_LengthFrames);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define RANGE_1    24
#define RANGE_2    48
#define RANGE_3    72
#define RANGE_4    96
#define RANGE_5    120

#define SAMPLES    120
#define INC_OFFSET 1.0 / SAMPLES
#define RETSCALE   (SAMPLES + 1) / 2.0

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_FgBlur (sampler F, float2 uv, int base)
{
   int range = base + RANGE_1;

   float blurAngle, Tcos, Tsin;
   float spinAmt  = (radians (blurLen * saturate (Amount + 0.04))) / SAMPLES;
   float spinOffs = 1.0 - (INC_OFFSET * base);

   float2 blurAspect  = float2 (1.0, aspectRatio * _OutputAspectRatio);
   float2 centreXY    = float2 (CentreX, 1.0 - CentreY);
   float2 angleXY, xy = (uv - centreXY) / blurAspect;

   float4 retval = tex2D (F, uv);
   float4 image  = retval;

   spinAmt = (CW_CCW == 0) ? spinAmt * 2.0 : spinAmt * -2.0;
   blurAngle = spinAmt * base;

   for (int i = base; i < range; i++) {
      sincos (blurAngle, Tsin, Tcos);
      angleXY = (float2 ((xy.x * Tcos - xy.y * Tsin), (xy.x * Tsin + xy.y * Tcos)) * blurAspect) + centreXY;

      retval += (tex2D (F, angleXY) * spinOffs);

      blurAngle += spinAmt;
      spinOffs -= INC_OFFSET;
   }

   return retval /= RETSCALE;
}

float4 fn_BgBlur (sampler B, float2 uv, int base)
{
   int range = base - RANGE_1;

   float blurAngle, Tcos, Tsin;
   float spinAmt  = (radians (blurLen * saturate (0.96 - Amount))) / SAMPLES;
   float spinOffs = 1.0 - (INC_OFFSET * base);

   float2 blurAspect  = float2 (1.0, aspectRatio * _OutputAspectRatio);
   float2 centreXY    = float2 (CentreX, 1.0 - CentreY);
   float2 angleXY, xy = (uv - centreXY) / blurAspect;

   float4 retval = tex2D (B, uv);
   float4 image  = retval;

   spinAmt = (CW_CCW == 0) ? spinAmt * 2.0 : spinAmt * -2.0;
   blurAngle = spinAmt * (1 - base);

   for (int i = base; i > range; i--) {
      sincos (blurAngle, Tsin, Tcos);
      angleXY = (float2 ((xy.x * Tcos - xy.y * Tsin), (xy.x * Tsin + xy.y * Tcos)) * blurAspect) + centreXY;

      retval += (tex2D (B, angleXY) * spinOffs);

      blurAngle += spinAmt;
      spinOffs -= INC_OFFSET;
   }

   return retval /= RETSCALE;
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

   return Fgnd.a == 0.0 ? kTransparentBlack : Fgnd;
}

DeclarePass (Bgd)
{
   float4 Bgnd = (Blended && SwapSource) ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2);

   if (!Blended) { Bgnd.a = 1.0; }

   return Bgnd;
}

DeclarePass (Rot_1)
{ return Blended && SwapDir ? fn_BgBlur (Fgd, uv3, RANGE_5) : fn_FgBlur (Fgd, uv3, 0); }

DeclarePass (Rot_2)
{ return Blended && SwapDir ? fn_BgBlur (Fgd, uv3, RANGE_4) : fn_FgBlur (Fgd, uv3, RANGE_1); }

DeclarePass (Rot_3)
{ return Blended && SwapDir ? fn_BgBlur (Fgd, uv3, RANGE_3) : fn_FgBlur (Fgd, uv3, RANGE_2); }

DeclarePass (Rot_4)
{ return Blended && SwapDir ? fn_BgBlur (Fgd, uv3, RANGE_2) : fn_FgBlur (Fgd, uv3, RANGE_3); }

DeclarePass (Fblur)
{ return Blended && SwapDir ? fn_BgBlur (Fgd, uv3, RANGE_1) : fn_FgBlur (Fgd, uv3, RANGE_4); }

DeclarePass (Spin1)
{ return Blended ? tex2D (Bgd, uv3) : fn_BgBlur (Bgd, uv3, RANGE_5); }

DeclarePass (Spin2)
{ return Blended ? tex2D (Bgd, uv3) : fn_BgBlur (Bgd, uv3, RANGE_4); }

DeclarePass (Spin3)
{ return Blended ? tex2D (Bgd, uv3) : fn_BgBlur (Bgd, uv3, RANGE_3); }

DeclarePass (Spin4)
{ return Blended ? tex2D (Bgd, uv3) : fn_BgBlur (Bgd, uv3, RANGE_2); }

DeclarePass (Bblur)
{ return Blended ? tex2D (Bgd, uv3) : fn_BgBlur (Bgd, uv3, RANGE_1); }

DeclareEntryPoint (SpinTrans)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Bgnd = tex2D (Bgd, uv3);
   float4 Fg_vid = tex2D (Fblur, uv3);
   float4 retval;

   Fg_vid += tex2D (Rot_1, uv3) + tex2D (Rot_2, uv3);
   Fg_vid += tex2D (Rot_3, uv3) + tex2D (Rot_4, uv3);

   if (Blended) {
      if (ShowKey) { retval = Fgnd; }
      else {
         float amount = SwapDir ? Amount * _LengthFrames / (_LengthFrames - 1.0) : 1.0 - Amount;

         Fg_vid *= 1.4585;
         retval = lerp (Fgnd, Fg_vid, saturate ((1.0 - amount) * 8.0));
         retval = lerp (Bgnd, retval, retval.a * amount);
      }
   }
   else {
      retval  = tex2D (Bblur, uv3);
      retval += tex2D (Spin1, uv3) + tex2D (Spin2, uv3);
      retval += tex2D (Spin3, uv3) + tex2D (Spin4, uv3);
      retval  = lerp (Bgnd, retval, saturate ((1.0 - Amount) * 8.0));
      Fg_vid  = lerp (Fgnd, Fg_vid, saturate (Amount * 8.0));

      float mix = (Amount - 0.5) * 2.0;

      mix = (1.0 + (abs (mix) * mix)) / 2.0;
      retval = lerp (Fg_vid, retval, mix);
   }

   return retval;
}
