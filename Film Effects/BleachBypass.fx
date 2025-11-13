// @Maintainer jwrl
// @Released 2025-11-13
// @Author msi
// @Created 2011-05-27

/**
 This effect emulates the altered contrast and saturation obtained by skipping the bleach
 step in classical colour film processing.  The settings are:

   [*] Luminosity
      [*] Red Channel:  Adjusts the red luminosity - unless you really need this it's
          better to leave it on the default settings.
      [*] Green Channel:  Adjusts the green luminosity.
      [*] Blue Channel:  Adjusts the blue luminosity.
   [*] Overlay
      [*] Blend Opacity:  Varies the visibility of the bleach bypass.
   [*] Mask:  Lightworks masking

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BleachBypass.fx
//
// Based on Bleach bypass routine by NVidia.
// https://developer.download.nvidia.com/shaderlibrary/webpages/hlsl_shaders.html#post_bleach_bypass
// Licensed Creative Commons [BY-NC-SA].
//
// Version history:
//
// Updated 2025-11-13 jwrl.
// Added descriptive text of parameters in header.
// Slight rewrite to increase blend opacity range.
// Added resolution independence.
//
// Updated 2023-08-24 jwrl.
// Optimised the code to resolve a Linux/Mac compatibility issue.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-02-17 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Bleach bypass", "Colour", "Film Effects", "Emulates the altered contrast and saturation obtained by skipping the bleach step in classical colour film processing", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Red, "Red Channel", "Luminosity", kNoFlags, 0.25, 0.0, 1.0);
DeclareFloatParam (Green, "Green Channel", "Luminosity", kNoFlags, 0.64, 0.0, 1.0);
DeclareFloatParam (Blue, "Blue Channel", "Luminosity", kNoFlags, 0.11, 0.0, 1.0);

DeclareFloatParam (BlendOpacity, "Blend Opacity", "Overlay", kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (BleachBypass)
{
   float4 Inp = ReadPixel (Input, uv1);

   float lum = dot (float3 (Red, Green, Blue), Inp.rgb);

   float4 retval = float4 (saturate (lum.xxx + Inp.rgb - (lum.xxx * Inp.rgb)), Inp.a);

   return lerp (Inp, retval, BlendOpacity * tex2D (Mask, uv1).x);
}
