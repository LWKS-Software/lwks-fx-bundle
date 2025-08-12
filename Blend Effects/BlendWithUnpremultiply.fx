// @Maintainer jwrl
// @Released 2025-08-12
// @Author baopao
// @Author jwrl
// @Created 2024-01-21

/**
 "Blend with unpremultiply" provides the functionality of the Lightworks blend effect with
 the option to unpremutliply or premultiply the foreground input.  Those two settings can
 either crispen the edges of the blend or remove the hard outline you can get with
 premultiplied images.

 The blend modes match the Lightworks blend effect, but the alpha channel / transparency is
 handled differently.  In the lightworks effect the alpha channel is turned fully on, while
 in this effect the foreground and background alphas are combined, allowing blend effects
 to be cascaded.

 Because I have matched the Lightworks blend effects several of the standard Photoshop
 blends have not been included.  Against my better judgment I have also included Average,
 which in my opinion is pointless, because it's identical to setting Fg Opacity to 50%
 when you use In Front as the blend mode.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BlendWithUnpremultiply.fx
//
// This effect is all original work and does NOT use any Lightworks code.
//
// Version history:
//
// Updated 2025-08-12 jwrl.
// Corrected Soft light, Colour, Luminosity and Dodge.  Did not fully match LW versions.
// Optimised the code - each blend mode now has the form initialise / body code / exit.
//
// Created 2024-01-21 jwrl.
// Combined code from baopao's Unpremultiply and jwrl's Enhanced blend.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Blend with unpremultiply", "Mix", "Blend Effects", "Can remove the hard outline you can get with premultiplied blend effects", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Unpremultiply, "Premultiply mode", kNoGroup, 0, "No Change|Unpremultiply|Premultiply");

DeclareIntParam (SetTechnique, "Blend mode", kNoGroup, 0, "In Front|Add|Subtract|Multiply|Screen|Overlay|Soft Light|Hard Light|Exclusion|Lighten|Darken|Average|Difference|Colour|Luminosity|Dodge|Burn");

DeclareFloatParam (Ammount, "Fg Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define LUMA float3(0.2991, 0.5868, 0.1141)

#define _TransparentBlack 0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float overlaySub (float B, float F)
{
   F = B <= 0.5 ? 2.0 * B * F : 1.0 - 2.0 * (1.0 - F) * (1.0 - B);

   return saturate (F);
}

float softLightSub (float B, float F)
{
   float retval = (1.0 - B) * (F * B) + (B * (1.0 - ((1.0 - B) * (1.0 - F))));

   return saturate (retval);
}

float hardLightSub (float B, float F)
{
   F = F < 0.5 ? 2.0 * B * F : 1.0 - 2.0 * (1.0 - B) * (1.0 - F);

   return saturate (F);
}

float3 ColourLumaSub (float3 V, float3 F)
{
   float Y  = dot (V, LUMA);
   float Cr = (0.439 * F.r) - (0.368 * F.g) - (0.071 * F.b) + 0.5;
   float Cb = (0.439 * F.b) - (0.291 * F.g) - (0.148 * F.r) + 0.5;

   float R = Y + (1.596 * (Cr - 0.5));
   float G = Y - (0.813 * (Cr - 0.5)) - (0.391 * (Cb - 0.5));
   float B = Y + (2.018 * (Cb - 0.5));

   return saturate (float3 (R, G, B));
}

float dodgeSub (float B, float F)
{
   float D = 1.0 - F;

   if (D == 0.0) D = 1.0e-9;

   return saturate (B / D);
}

float burnSub (float B, float F)
{
   if (F > 0.0) F = 1.0 - ((1.0 - B) / F);

   return saturate (F);
}

float4 initMedia (sampler F, float2 xy1, sampler B, float2 xy2, sampler M,
                  out float4 Bgd, inout float A)
{
   Bgd = ReadPixel (B, xy2);

   // Instead of using ReadPixel for foreground recovery we check for bounds overflow, and
   // quit if so.  Doing this after recovering the background ensures that no unnecessary
   // processing will take place, but a valid foreground and background will be returned.
   // The alpha channel, A, is initialised to zero externally so that it's also valid.

   if (IsOutOfBounds (xy1)) { return _TransparentBlack; }

   float4 Fgd = tex2D (F, xy1);

   if (Unpremultiply == 1) { Fgd.rgb /= Fgd.a; }
   else if (Unpremultiply == 2) Fgd.rgb *= Fgd.a;

   A = ReadPixel (M, xy1).x * Fgd.a * Ammount;

   return Fgd;
}

float4 exitVFX (float4 Bgd, float4 Fgd, float amt)
{
   return float4 (lerp (Bgd.rgb, Fgd.rgb, amt), max (Bgd.a, amt));
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (InFront)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (Add)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb);

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (Subtract)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.rgb = saturate (Fgnd.rgb - Bgnd.rgb);

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (Multiply)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.rgb *= Bgnd.rgb;

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (Screen)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb - (Fgnd.rgb * Bgnd.rgb));

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (Overlay)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.r = overlaySub (Bgnd.r, Fgnd.r);
   Fgnd.g = overlaySub (Bgnd.g, Fgnd.g);
   Fgnd.b = overlaySub (Bgnd.b, Fgnd.b);

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (SoftLight)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.r = softLightSub (Bgnd.r, Fgnd.r);
   Fgnd.g = softLightSub (Bgnd.g, Fgnd.g);
   Fgnd.b = softLightSub (Bgnd.b, Fgnd.b);

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (HardLight)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.r = hardLightSub (Bgnd.r, Fgnd.r);
   Fgnd.g = hardLightSub (Bgnd.g, Fgnd.g);
   Fgnd.b = hardLightSub (Bgnd.b, Fgnd.b);

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (Exclusion)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.rgb = saturate (Fgnd.rgb + Bgnd.rgb * (1.0.xxx - (2.0 * Fgnd.rgb)));

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (Lighten)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.rgb = max (Fgnd.rgb, Bgnd.rgb);

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (Darken)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.rgb = min (Fgnd.rgb, Bgnd.rgb);

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (Average)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.rgb = (Fgnd.rgb + Bgnd.rgb) / 2.0;

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (Difference)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.rgb = abs (Fgnd.rgb - Bgnd.rgb);

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (Colour)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.rgb = ColourLumaSub (Bgnd.rgb, Fgnd.rgb);

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (Luminosity)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.rgb = ColourLumaSub (Fgnd.rgb, Bgnd.rgb);

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (Dodge)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.r = dodgeSub (Bgnd.r, Fgnd.r);
   Fgnd.g = dodgeSub (Bgnd.g, Fgnd.g);
   Fgnd.b = dodgeSub (Bgnd.b, Fgnd.b);

   return exitVFX (Bgnd, Fgnd, alpha);
}

DeclareEntryPoint (Burn)
{
   float alpha = 0.0;

   float4 Bgnd, Fgnd = initMedia (Fg, uv1, Bg, uv2, Mask, Bgnd, alpha);

   Fgnd.r = burnSub (Bgnd.r, Fgnd.r);
   Fgnd.g = burnSub (Bgnd.g, Fgnd.g);
   Fgnd.b = burnSub (Bgnd.b, Fgnd.b);

   return exitVFX (Bgnd, Fgnd, alpha);
}
