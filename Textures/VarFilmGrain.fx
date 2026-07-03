// @Maintainer jwrl
// @Released 2026-07-03
// @Author khaver
// @Created 2011-05-12

/**
 Author's note:  This effect is based on my earlier Grain (Variable) effect.  This effect
 rolls-off the strength of the grain as the luma values in the image approach 0 and 1,
 much like real film.

 The settings are:

   [*]Strength:  Controls the amount of grain added.
   [*]Size:  Controls the size of the grain.
   [*]Distribution:  Controls the space between grains.
   [*]Roll-off bias:  Contols the roll-off curve between pure white and pure black.
   [*]Grain blur:  Adds blur to the grain.
   [*]Show grain:  Lets you see just the grain.
   [*]Alpha
      [*]Alpha grain only:  Replaces the source alpha channel with the grain passing the
         RGB channels through from the source image untouched.
      [*]Alpha trim:  Tweaks the alpha channel grain.

 NOTE:  This effect breaks resolution independence.  It is only suitable for use with
 Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect VarFilmGrain.fx
//
// Version history:
//
// Updated 2026-07-03 jwrl.
// Renamed "Alpha adjustment" to "Alpha trim".
// Added settings description to header text.
//
// Updated 2023-07-13 jwrl.
// Corrected creation date.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-12 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Variable Film Grain", "Stylize", "Textures", "This effect reduces the grain as the luminance values approach their limits", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Strength, "Strength",         kNoGroup, kNoFlags, 0.0, 0.0, 100.0);
DeclareFloatParam (Size,     "Size",             kNoGroup, kNoFlags, 1.0, 1.0, 10.0);
DeclareFloatParam (Shape,    "Distribution",     kNoGroup, kNoFlags, 0.9, 0.0, 1.0);
DeclareFloatParam (Bias,     "Roll-off bias",    kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (blur,     "Grain blur",       kNoGroup, kNoFlags, 0.5, 0.0, 1.0);
DeclareBoolParam (show,      "Show grain",       kNoGroup, false);

DeclareBoolParam (agrain,    "Alpha grain only", "Alpha",  false);
DeclareFloatParam (aadjust,  "Alpha trim",       "Alpha",  kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);
DeclareFloatParam (_OutputWidth);

DeclareFloatParam (_Progress);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define HALF_PI 1.5707963268

float2 _TexelKernel[13] = { { -6.0, 0.0 }, { -5.0, 0.0 }, { -4.0, 0.0 }, { -3.0, 0.0 },
                            { -2.0, 0.0 }, { -1.0, 0.0 }, {  0.0, 0.0 }, {  1.0, 0.0 },
                            {  2.0, 0.0 }, {  3.0, 0.0 }, {  4.0, 0.0 }, {  5.0, 0.0 },
                            {  6.0, 0.0 } };

float _BlurWeights[13] = { 0.002216, 0.008764, 0.026995, 0.064759, 0.120985,  0.176033,
                           0.199471, 0.176033, 0.120985, 0.064759, 0.026995, 0.008764,
                           0.002216 };

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float _rand (float2 co, float seed)
{
   return frac ((dot (co.xy, float2 (co.x + 123.0, co.y + 13.0))) * seed + _Progress);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Samp1)
{
   float2 xy = saturate (uv0 + float2 (0.00013, 0.00123));

   float x = sin (xy.x) + cos (xy.y) + _rand (xy, ((xy.x + 1.123) * (xy.x + xy.y))) * 1000.0;
   float grain = frac (fmod(x, 13.0) * fmod (x, 123.0));

   if (grain > Shape || grain < (1.0 - Shape)) grain = 0.5;

   return (((grain - 0.5) * (Strength * 5.0)) + 0.5).xxxx;
}

DeclarePass (Samp2)
{
   float2 xy = ((uv2 - 0.5.xx) / Size) + 0.5.xx;

   float blurpix = blur / _OutputWidth;

   float4 Color = 0.0.xxxx;

   for (int i = 0; i < 13; i++) {    
      Color += tex2D (Samp1, xy + (_TexelKernel [i].yx * blurpix)) * _BlurWeights [i];
   }

   return Color;
}

DeclarePass (Samp3)
{
   float2 xy = ((uv2 - 0.5.xx) / Size) + 0.5.xx;

   float blurpix = _OutputAspectRatio * blur / _OutputWidth;

   float4 Color = 0.0.xxxx;

   for (int i = 0; i < 13; i++) {    
      Color += tex2D (Samp2, xy + (_TexelKernel [i] * blurpix)) * _BlurWeights [i];
   }

   return Color;
}

DeclareEntryPoint (VariableFilmGrain)
{
   float4 source = ReadPixel (Input, uv1);

   float lum = (source.r + source.g + source.b) / 3.0;

   lum = lum > Bias ? sin ((1.0 - lum) * HALF_PI / (1.0 - Bias))
       : lum < Bias ? sin (lum * HALF_PI / Bias) : 1.0;

   float4 grainblur = (tex2D (Samp3, uv2) - 0.5.xxxx) * lum;

   if (show) return grainblur + 0.5.xxxx;

   return agrain ? float4 (source.rgb, (grainblur.a * 2.0) + aadjust) : source + grainblur;
}
