// @Maintainer jwrl
// @Released 2025-10-24
// @Author jwrl
// @Created 2025-10-24

/**
 This is a more extreme version of Glitch.  Like that effect, to use it just apply it,
 select the colours to affect, then the spread and the amount of edge roughness that
 you need.  However, unlike Glitch this is a single input effect, and as such isn't
 designed for use with image keys or titles.  That's not to say that you can't use it
 that way, but you will need to use an external blend effect with it if you do.

   [*] Visibility:  Fades the glitched area in or out of the video.
   [*] Masking:  Switches whether the masking boundaries are affected by the glitch
       or not.
   [*] Glitch settings
       [*] Glitch channels:  Selects between red/cyan, green/magenta, blue/yellow
           or the full video input.
       [*] Glitch rate:  Sets the speed at which the glitch operates.
       [*] Glitch spacing:  Sets the spacing between glitches.  Effectively it
           changes the height of each glitch line.
       [*] Glitch width:  Sets the amount of horizontal spread in the glitch.
   [*] Video settings
       [*] Rotation:  The video displacement in the glitch can be rotated through
           360 degrees.
       [*] Offset:  This offsets the video inside the glitch.
       [*] Modulation:  Sets the amount of glitched shading applied.
       [*] Mod centre:  Adjusts the modulation centring.

 This effect is designed to be extreme.  If you need subtle glitching this is not going
 to be your best choice.  Use Glitch instead.  Also, when modulating mask boundaries it's
 a good idea to add a little softness to the mask.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SuperGlitch.fx
//
// Version history:
//
// Created 2025-10-24 by jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Super glitch", "Stylize", "Video artefacts", "Applies an extremely strong masked glitch to video.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Visibility,   "Visibility",      kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam   (SetTechnique, "Masking",         kNoFlags, 1, "Static edges|Modulated edges");

DeclareIntParam   (Channels,     "Glitch channels", "Glitch settings", 0, "Red - cyan|Green - magenta|Blue - yellow|Full video");
DeclareFloatParam (GlitchRate,   "Glitch rate",     "Glitch settings", kNoFlags, 1.0,  0.0, 1.0);
DeclareFloatParam (GlitchSpace,  "Glitch spacing",  "Glitch settings", kNoFlags, 0.0,  0.0, 1.0);
DeclareFloatParam (GlitchWidth,  "Glitch width",    "Glitch settings", kNoFlags, 0.1, -1.0, 1.0);

DeclareFloatParam (Rotation,     "Rotation",        "Video settings",  kNoFlags, 0.0, -180, 180);
DeclareFloatParam (VidOffset,    "Offset",          "Video settings",  kNoFlags, 0.5,  0.0, 1.0);
DeclareFloatParam (Modulation,   "Modulation",      "Video settings",  kNoFlags, 0.2,  0.0, 1.0);
DeclareFloatParam (ModCentre,    "Mod centre",      "Video settings",  kNoFlags, 0.2,  0.0, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_Length);
DeclareFloatParam (_LengthFrames);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SCALE             0.25
#define MODLN             2.0
#define EDGE              20.0

#define _TransparentBlack 0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 mirror2D (sampler S, float2 uv)
// Provides mirror addressing for media locked to sequence coords.
{
   float2 xy = 1.0.xx - abs (abs (uv) - 1.0.xx);

   return tex2D (S, xy);
}

float2 genGlitch (float2 uv, out float2 xy, out float glitchAmt)
{
   // This function generates noise modulated by the glitch settings.  The first part
   // combines the various glitch settings.

   float roughness = lerp (1.0, 0.25, saturate (GlitchSpace)) * _OutputHeight;
   float y = floor (uv.y * roughness) / _OutputHeight;
   float edge = _OutputWidth * _OutputAspectRatio;
   float rate = floor (_LengthFrames / _Length);

   edge  = floor ((edge * y) / ((GlitchSpace * EDGE) + 1.0)) / edge;
   rate -= (rate - 1.0) * ((GlitchRate * 0.2) + 0.8);
   rate *= floor ((_LengthFrames * _Progress) / rate) / _LengthFrames;

   // Now generate the noise and apply it to xy0

   float3 seed = frac (float3 (_Length, _LengthFrames, 1.0) * rate * 19.0);

   float n1 = 8192.0 * sin (dot (seed, float3 (17.0, 53.0, 7.0)));
   float n2 = 1024.0 * sin (((n1 / 1024.0) + edge) * 59.0);

   float2 xy0 = frac (float2 (abs (n1), n2) * 256.0);

   xy0.x *= xy0.y;

   // The noise in xy0 is used in conjunction with the Modulation setting to
   // generate the final modulation and with GlitchWidth to generate the scale.

   glitchAmt   = 1.0 - abs (dot (xy0 * abs (uv.x - ModCentre), 0.5.xx) * Modulation * MODLN);

   float scale = dot (xy0, GlitchWidth.xx) * SCALE;

   sincos (radians (Rotation), xy0.y, xy0.x);

   if (Channels < 3) xy0 /= 2.0;

   xy0.y += (saturate (VidOffset) - 0.5) * 0.5;
   xy0.y *= _OutputAspectRatio;
   xy0   *= scale;
   xy     = uv + xy0;

   return uv - xy0;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (SuperGlitch)
{
   float modulation;

   float2 xy1, xy2 = genGlitch (uv1, xy1, modulation);

   float4 video = ReadPixel (Inp, uv1);
   float4 ret_1 = mirror2D  (Inp, xy1) * modulation;
   float4 ret_2 = mirror2D  (Inp, xy2) * modulation;
   float4 glitch;

   glitch.r = Channels == 0 ? ret_2.r : ret_1.r;
   glitch.g = Channels == 1 ? ret_2.g : ret_1.g;
   glitch.b = Channels == 2 ? ret_2.b : ret_1.b;
   glitch.a = video.a;

   glitch = lerp (video, glitch, video.a * Visibility);

   return lerp (video, glitch, tex2D (Mask, uv1).x);
}

//-----------------------------------------------------------------------------------------//

DeclarePass (Fg)
{
   float4 Fgd = ReadPixel (Inp, uv1);

   return lerp (_TransparentBlack, Fgd, tex2D (Mask, uv1).x);
}

DeclareEntryPoint (SuperGlitchMask)
{
   float modulation;

   float2 xy1, xy2 = genGlitch (uv2, xy1, modulation);

   float4 video = ReadPixel (Inp, uv1);
   float4 ret_1 = mirror2D  (Fg, xy1) * modulation;
   float4 ret_2 = mirror2D  (Fg, xy2) * modulation;
   float4 glitch;

   glitch.r = Channels == 0 ? ret_2.r : ret_1.r;
   glitch.g = Channels == 1 ? ret_2.g : ret_1.g;
   glitch.b = Channels == 2 ? ret_2.b : ret_1.b;
   glitch.a = (ret_2.a + ret_1.a) / 2.0;

   return lerp (video, glitch, glitch.a * Visibility);
}



