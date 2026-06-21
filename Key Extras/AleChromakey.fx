// @Maintainer jwrl
// @Released 2026-06-21
// @Author baopao
// @Created 2013-06-07

/**
 This sophisticated chromakey has similar key control to what you would expect to find
 on expensive third party tools.  It existed previously with a different appearance, but
 this is really just that effect with a new coat of paint.  Most of the settings have
 been renamed to make their purposes more readily understood, but their functionality
 has in no way been changed.

 It's still particularly effective on fine detail.  Highly recommended.

   [*]Chromakey:  Chooses between green or blue to use as the key colour.
   [*]Red amount:  Mixes red back into the key colour to adjust the saturation.
   [*]Fg value:  Adjusts the foreground clip level and replacement mix.
   [*]Clip shadows:  Adjusts the shadow preservation in the key.
   [*]Fine tuning
      [*]Trim key:  Adjusts the foreground gamma to tighten or loosen the key.
         This will help preserve fine detail.
      [*]Shadows:  Varies the background gamma to darken or lighten the shadows
         produced by shaded key colour areas.
   [*]Spill removal
      [*]Spill fix:  Uses the key gamma to control spill removal.
      [*]Despill blur:  Blurs the key colour despill component.
      [*]Colour fill:  Sets the colour to be used as the despill replacement fill.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect AleChromakey.fx
//
// Created by baopao (http://www.alessandrodallafontana.com).
//
// Version history:
//
// Updated 2026-06-21 jwrl.
// Header now contains settings description.
// Mask now uses all four channels, not just R.
// Renamed "Bg val" to "Clip shadows".
// Created a new group, "Fine tuning".
// Renamed "Gamma fg" to "Trim key" and put it in the "Fine tuning" group.
// Renamed "Gamma bg" to "Shadows" and put it in the "Fine tuning" group.
// Created a new group, "Spill removal".
// Renamed "Gamma mix" to "Spill fix" and put it in the "Spill removal" group.
// Renamed "Despill blur" to "Blur spill" and put it in the "Spill removal" group.
// Renamed "Color replace" to "Colour fill" and put it in the "Spill removal" group.
//
// Updated 2023-08-04 jwrl.
// User parameters reformatted.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-26 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("ALE ChromaKey", "Key", "Key Extras", "A sophisticated chromakey that is particularly effective on fine detail", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (fg, bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (ChromaKey,       "Chromakey",    kNoGroup, 0, "Green|Blue");
DeclareFloatParam (RedAmount,     "Red amount",   kNoGroup,        kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (FgVal,         "Fg value",     kNoGroup,        kNoFlags, 0.45, 0.0, 1.0);
DeclareFloatParam (BgVal,         "Clip shadows", kNoGroup,        kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (GammaFG,       "Trim key",     "Fine tuning",   kNoFlags, 2.0, 0.0, 4.0);
DeclareFloatParam (GammaBG,       "Shadows",      "Fine tuning",   kNoFlags, 0.4, 0.0, 2.0);

DeclareFloatParam (GammaMix,      "Spill fix",    "Spill removal", kNoFlags, 2.0, 0.0, 5.0);
DeclareFloatParam (Despill,       "Blur spill",   "Spill removal", kNoFlags, 0.5, 0.0, 1.0);
DeclareColourParam (ColorReplace, "Colour fill",  "Spill removal", kNoFlags, 0.5, 0.5, 0.5, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (FG)
{ return ReadPixel (fg, uv1); }           // Color FG

DeclarePass (BG)
{ return ReadPixel (bg, uv2); }           // Color BG

DeclarePass (BlurSub)
{
   float4 retval = tex2D (BG, uv3);

   float2 offs = float2 (Despill / _OutputWidth, 0.0);
   float2 xy = uv3 + offs;

   retval += tex2D (BG, xy); xy += offs;
   retval += tex2D (BG, xy); xy += offs;
   retval += tex2D (BG, xy); xy += offs;
   retval += tex2D (BG, xy); xy += offs;
   retval += tex2D (BG, xy); xy += offs;
   retval += tex2D (BG, xy);

   xy = uv3 - offs;

   retval += tex2D (BG, xy); xy -= offs;
   retval += tex2D (BG, xy); xy -= offs;
   retval += tex2D (BG, xy); xy -= offs;
   retval += tex2D (BG, xy); xy -= offs;
   retval += tex2D (BG, xy); xy -= offs;
   retval += tex2D (BG, xy);

   return retval /= 13.0;
}

DeclarePass (Blur)
{
   float4 retval = tex2D (BlurSub, uv3);

   float2 offs = float2 (0.0, Despill / _OutputHeight);
   float2 xy = uv3 + offs;

   retval += tex2D (BlurSub, xy); xy += offs;
   retval += tex2D (BlurSub, xy); xy += offs;
   retval += tex2D (BlurSub, xy); xy += offs;
   retval += tex2D (BlurSub, xy); xy += offs;
   retval += tex2D (BlurSub, xy); xy += offs;
   retval += tex2D (BlurSub, xy);

   xy = uv3 - offs;

   retval += tex2D (BlurSub, xy); xy -= offs;
   retval += tex2D (BlurSub, xy); xy -= offs;
   retval += tex2D (BlurSub, xy); xy -= offs;
   retval += tex2D (BlurSub, xy); xy -= offs;
   retval += tex2D (BlurSub, xy); xy -= offs;
   retval += tex2D (BlurSub, xy);

   return retval /= 13.0;
}

DeclareEntryPoint (AleChromakey)
{
   float4 color = tex2D (FG, uv3);
   float4 colorBG = tex2D (BG, uv3);
   float4 colorBGblur = tex2D (Blur, uv3);

   if (IsOutOfBounds (uv1) || (color.a == 0.0)) { color = colorBG; }
   else {
      float4 colorBGblur = tex2D (Blur, uv3);

      float MixRB, KeyG;

      if (ChromaKey) {                              // Blue key
         MixRB = saturate (color.b - lerp (color.r, color.g, RedAmount));
         KeyG  = color.b - MixRB;
      }
      else {                                        // Green key
         MixRB = saturate (color.g - lerp (color.r, color.b, RedAmount));
         KeyG  = color.g - MixRB;
      }

      float MaskFG = saturate (1.0 - MixRB * FgVal / KeyG);
      float MaskBG = saturate (MixRB / BgVal);

      MaskFG = pow (MaskFG, 1.0 / GammaFG);
      MaskBG = pow (MaskBG, 1.0 / GammaBG);

      float OverMask = 1.0 - MaskFG - MaskBG;

      if (ChromaKey) { color.b = KeyG; }
      else color.g = KeyG;

      float4 retval = lerp (color, ColorReplace + colorBGblur, MixRB) * MaskFG;

      retval += colorBG * MaskBG;

      color = lerp (retval, pow (retval, 1.0 / GammaMix), OverMask);
   }

   return lerp (colorBG, color, tex2D (Mask, uv3).x);
}
