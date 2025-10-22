// @Maintainer jwrl
// @Released 2025-10-22
// @Author jwrl
// @Created 2025-09-21

/**
 This effect is designed to apply a mini transform effect to the background source.
 It can blur, scale, crop and position the background and fade it out.  The foreground
 can be blended with the processed background using normal blend mode or Lighten, Screen,
 Add, Lighter Colour, Overlay or Soft Light blends.  It can can be masked as well.

   [*] Foreground:  Adjusts the mix of the foreground over the transformed background.
   [*] Blend mode:  Selects from Normal, Lighten, Screen, Add, Lighter Colour, Overlay
       or Soft Light blend modes.
   [*] Background
      [*] Opacity:  Adjusts the background opacity.
      [*] Softness:  Softens the background slightly.  It's not intended to produce
          really strong blurs because this would destroy multi layer versions of the effect.
      [*] Scale:  Scales the background.  This has the same reduction range of the
          background, but can only double enlargement size.
      [*] Position X:  Adjusts the horizontal position of the background.
      [*] Position Y:  Adjusts the vertical position of the background.
   [*] Crop
      [*] Left:  Crops the left side of the background.
      [*] Top:  Crops the top edge of the background.
      [*] Right:  Crops the right side of the background.
      [*] Bottom:  Crops the bottom edge of the background.

 The intention is to use multiple versions of this effect with a series of delayed
 video sources to create the classic video feedback effect.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VideoFeedback.fx
//
// Updated 2025-10-22 jwrl.
// Changed the category from "DVE" to "Stylize".
// Changed the subcategory from "Transform plus" to "Video artefacts".
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Video feedback", "Stylize", "Video artefacts", "Produces the classic video feedback effect", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Amount,     "Foreground", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam (SetTechnique, "Blend mode", kNoGroup, 0, "Normal|Lighten|Screen|Add|Lighter Colour|Overlay|Soft Light");

DeclareFloatParam (Opacity,  "Opacity",  "Background", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Softness, "Softness", "Background", kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (Scale,    "Scale",    "Background", "DisplayAsPercentage", 1.0, 0.5, 2.0);
DeclareFloatParam (Pos_X,    "Position", "Background", "SpecifiesPointX|DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (Pos_Y,    "Position", "Background", "SpecifiesPointY|DisplayAsPercentage", 0.5, -1.0, 2.0);

DeclareFloatParam (CropLeft,   "Left",   "Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (CropTop,    "Top",    "Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (CropRight,  "Right",  "Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (CropBottom, "Bottom", "Crop", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LUMA  float4(0.2989, 0.5866, 0.1145, 0.0)

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

float4 TransformSub (sampler S, float2 uv)
{
   // This is a mini transform which scales, offsets and fades the video referenced
   // by sampler B, returning it as the function output.

   float2 xy = uv + float2 (0.5 - Pos_X, Pos_Y - 0.5);   // Set the X-Y position

   xy = ((xy - 0.5.xx) / Scale) + 0.5.xx;                // Set the scale

   float CropR = 1.0 - CropRight;                        // Invert the right crop value
   float CropB = 1.0 - CropBottom;                       // and the bottom crop value

   // Now crop the video.  We do this by returning transparent black if xy coordinates
   // fall outside any of the crop boundaries.

   if ((xy.x < CropLeft) || (xy.x > CropR) || (xy.y < CropTop) || (xy.y > CropB)) {
      return _TransparentBlack;
   }

   float4 retval = ReadPixel (S, xy);                    // Recover the video

   // Quit, mixing retval over transparent black while honouring the alpha channel.

   return lerp (_TransparentBlack, retval, Opacity * retval.a);
}

float4 initMedia (sampler F, float2 xy1, sampler B, float2 xy2, out float4 retval)
{
   // This blurs the background video referenced by sampler B, returning it
   // in retval.  It then recovers the foreground referenced by sampler F and
   // returns it as the function output.

   retval = mirror2D (B, xy2);

   float2 radius = float2 (1.0, _OutputAspectRatio) * Softness * 0.00666667;
   float2 xy;

   float angle = 0.0;

   for (int i = 0; i < 23; i++) {
      sincos (angle, xy.x, xy.y);
      xy     *= radius;
      xy     += xy2;
      retval += mirror2D (B, xy);
      angle  += 0.27318197;
   }

   retval /= 24;

   return ReadPixel (F, xy1);
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

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

//-----  Normal  --------------------------------------------------------------------------//

DeclarePass (DVE_0)
{ return TransformSub (Bg, uv2); }

DeclareEntryPoint (Normal)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, DVE_0, uv3, Bgnd);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

//-----  Lighten  -------------------------------------------------------------------------//

DeclarePass (DVE_1)
{ return TransformSub (Bg, uv2); }

DeclareEntryPoint (Lighten)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, DVE_1, uv3, Bgnd);

   Fgnd.rgb = max (Fgnd.rgb, Bgnd.rgb);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

//-----  Screen  --------------------------------------------------------------------------//

DeclarePass (DVE_2)
{ return TransformSub (Bg, uv2); }

DeclareEntryPoint (Screen)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, DVE_2, uv3, Bgnd);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb));

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

//-----  Add  -----------------------------------------------------------------------------//

DeclarePass (DVE_3)
{ return TransformSub (Bg, uv2); }

DeclareEntryPoint (Add)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, DVE_3, uv3, Bgnd);

   Fgnd.r = min (1.0, Bgnd.r + Fgnd.r);
   Fgnd.g = min (1.0, Bgnd.g + Fgnd.g);
   Fgnd.b = min (1.0, Bgnd.b + Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

//-----  Lighter Colour  ------------------------------------------------------------------//

DeclarePass (DVE_4)
{ return TransformSub (Bg, uv2); }

DeclareEntryPoint (LighterColour)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, DVE_4, uv3, Bgnd);

   float B_luma = dot (Bgnd, LUMA);
   float F_luma = dot (Fgnd, LUMA);

   Fgnd.rgb = B_luma > F_luma ? Bgnd.rgb : Fgnd.rgb;

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

//-----  Overlay  -------------------------------------------------------------------------//

DeclarePass (DVE_5)
{ return TransformSub (Bg, uv2); }

DeclareEntryPoint (Overlay)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, DVE_5, uv3, Bgnd);

   Fgnd.r = OverlaySub (Bgnd.r, Fgnd.r);
   Fgnd.g = OverlaySub (Bgnd.g, Fgnd.g);
   Fgnd.b = OverlaySub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}

//-----  Soft Light  ----------------------------------------------------------------------//

DeclarePass (DVE_6)
{ return TransformSub (Bg, uv2); }

DeclareEntryPoint (SoftLight)
{
   float4 Bgnd, Fgnd = initMedia (Fg, uv1, DVE_6, uv3, Bgnd);

   Fgnd.r = SoftLightSub (Bgnd.r, Fgnd.r);
   Fgnd.g = SoftLightSub (Bgnd.g, Fgnd.g);
   Fgnd.b = SoftLightSub (Bgnd.b, Fgnd.b);

   float4 retval = float4 (lerp (Bgnd.rgb, Fgnd.rgb, Fgnd.a), max (Bgnd.a, Fgnd.a));

   return lerp (Bgnd, retval, tex2D (Mask, uv1).x * Amount);
}


