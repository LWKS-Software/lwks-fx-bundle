// @Maintainer jwrl
// @Released 2025-07-24
// @Author idealsceneprod (Val Gameiro)
// @Created 2014-12-24

/**
 Four tone is a posterization effect that extends the existing Lightworks Two Tone and
 Tri-Tone effects.  It reduces the input video to four tonal values.  Input blending,
 threshold and colour values are all adjustable.  The settings are the same as the
 Lightworks two tone and tri-tone effects, there's just more of them.

   * Threshold One:  The lowest threshold.  Video under this will get the dark colour.
   * Threshold Two:  Mid level.  Video under this will be assigned the mid dark colour,
     above will get the mid light colour.
   * Threshold Three:  Level below peak white.  Video above it gets the light colour.
   * Blend Tones:  Blends the four tones with the input video.
   * Dark Colour:  Self explanatory.  The darkest of the colours that will be assigned.
   * Mid Dark Colour:  Self explanatory.
   * Mid Light Colour:  Self explanatory.
   * Light Colour:  Self explanatory.

 The colours used for the tonal values are set to grey scale levels by default, but can
 in fact be any colour that you wish.  They do not have to be in luminance order.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FourTone.fx
//
// The original versions of this effect were clearly built on Lightworks' threshold.fx
// and tritone.fx, both of which are copyright (c) LWKS Software Ltd, all rights reserved.
//
// The only differences between this effect and those originals are the added parameters
// to support the extra tones and blending.  No acknowledgement was made of that fact in
// earlier versions - jwrl.
//
// Version history:
//
// Updated 2025-07-24 jwrl.
// Removed redundant alpha channel assignment in DeclareEntryPoint().
// Added blending to provide mixing of the posterised effect with the input video.
//
// Updated 2023-05-14 jwrl.
// Header reformatted.
//
// Conversion 2023-01-23 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Four tone", "Colour", "Art Effects", "Extends the existing Lightworks Two Tone and Tri-Tone effects to provide four tonal values", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Threshold1, "Threshold One",   kNoGroup, kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Threshold2, "Threshold Two",   kNoGroup, kNoFlags, 0.5,  0.0, 1.0);
DeclareFloatParam (Threshold3, "Threshold Three", kNoGroup, kNoFlags, 0.75, 0.0, 1.0);
DeclareFloatParam (BlendTones, "Blend Tones",     kNoGroup, kNoFlags, 1.0,  0.0, 1.0);

DeclareColourParam (DarkColour,  "Dark Colour",      kNoGroup, kNoFlags, 0.0, 0.0, 0.0, 1.0);
DeclareColourParam (MidColour,   "Mid Dark Colour",  kNoGroup, kNoFlags, 0.3, 0.3, 0.3, 1.0);
DeclareColourParam (MidColour2,  "Mid Light Colour", kNoGroup, kNoFlags, 0.7, 0.7, 0.7, 1.0);
DeclareColourParam (LightColour, "Light Colour",     kNoGroup, kNoFlags, 1.0, 1.0, 1.0, 1.0);

DeclareFloatParam (_OutputHeight);
DeclareFloatParam (_OutputWidth);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

float blur[] = { 20.0 / 64.0, 15.0 / 64.0, 6.0 / 64.0, 1.0 / 64.0 };  // Pascals Triangle

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Threshold)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   float4 src1 = ReadPixel (Input, uv1);

   float srcLum = ((src1.r * 0.3) + (src1.g * 0.59) + (src1.b * 0.11));

   if (srcLum < Threshold1) src1.rgb = DarkColour.rgb;
   else if ( srcLum < Threshold2 ) src1.rgb = MidColour.rgb;
   else if ( srcLum < Threshold3 ) src1.rgb = MidColour2.rgb;
   else src1.rgb = LightColour.rgb;

   return src1;
}

DeclarePass (Blur)
{
   if (IsOutOfBounds (uv2)) return kTransparentBlack;

   // Explicitly query BETWEEN pixels to get extra averaging

   float2 onePixAcross   = float2 (0.5 / _OutputWidth, 0.0);
   float2 twoPixAcross   = float2 (1.5 / _OutputWidth, 0.0);
   float2 threePixAcross = float2 (2.5 / _OutputWidth, 0.0);

   float4 keyPix = tex2D (Threshold, uv2);
   float4 result = keyPix * blur [0];

   result += tex2D (Threshold, uv2 + onePixAcross)   * blur [1];
   result += tex2D (Threshold, uv2 - onePixAcross)   * blur [1];
   result += tex2D (Threshold, uv2 + twoPixAcross)   * blur [2];
   result += tex2D (Threshold, uv2 - twoPixAcross)   * blur [2];
   result += tex2D (Threshold, uv2 + threePixAcross) * blur [3];
   result += tex2D (Threshold, uv2 - threePixAcross) * blur [3];
   result.a = keyPix.a;

   return result;
}

DeclareEntryPoint (FourTone)
{
   if (IsOutOfBounds (uv1)) return kTransparentBlack;

   // Explicitly query BETWEEN pixels to get extra averaging

   float2 onePixDown   = float2 (0.0, 0.5 / _OutputHeight);
   float2 twoPixDown   = float2 (0.0, 1.5 / _OutputHeight);
   float2 threePixDown = float2 (0.0, 2.5 / _OutputHeight);

   float4 source = tex2D (Input, uv1);
   float4 keyPix = tex2D (Blur, uv2);
   float4 result = keyPix * blur [0];

   result += tex2D (Blur, uv2 + onePixDown)   * blur [1];
   result += tex2D (Blur, uv2 - onePixDown)   * blur [1];
   result += tex2D (Blur, uv2 + twoPixDown)   * blur [2];
   result += tex2D (Blur, uv2 - twoPixDown)   * blur [2];
   result += tex2D (Blur, uv2 + threePixDown) * blur [3];
   result += tex2D (Blur, uv2 - threePixDown) * blur [3];
   result.a = source.a;

   result = lerp (source, result, result.a * BlendTones);

   return lerp (source, result, tex2D (Mask, uv1).x);
}
