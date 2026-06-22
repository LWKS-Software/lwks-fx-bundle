// @Maintainer jwrl
// @Released 2026-06-26
// @Author khaver
// @Created 2011-05-24

/**
 Flare is an original effect by khaver which creates an adjustable lens flare effect.
 The origin of the flare can be positioned by adjusting the X and Y sliders or by
 dragging the on-viewer icon with the mouse.

   [*]Origin X:  Sets the flare origin's horizontal position.
   [*]Origin Y:  Sets the flare origin's vertical position.
   [*]Strength:  Sets the flare intensity.
   [*]Stretch:  Sets the range covered by the flare.
   [*]Adjust:  Sets the flare transparency.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Flare.fx
//
// Version history:
//
// Updated 2026-06-22 jwrl.
// Rewrote header to include settings details.
// Changed masking to full RGBA.
//
// Updated 2024-05-24 jwrl.
// Replaced kTransparentBlack with 0.0.xxxx for Linux fix.
//
// Updated 2023-05-16 jwrl.
// Header reformatted.
//
// Conversion 2023-01-24 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Flare", "Stylize", "Filters", "Creates an adjustable lens flare effect", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (CentreX, "Origin", kNoGroup, "SpecifiesPointX", 0.5, 0.0, 1.0);
DeclareFloatParam (CentreY, "Origin", kNoGroup, "SpecifiesPointY", 0.5, 0.0, 1.0);

DeclareFloatParam (Strength, "Strength", kNoGroup, kNoFlags, 0.1, 0.0, 1.0);
DeclareFloatParam (Stretch, "Stretch", kNoGroup, kNoFlags, 5.0, 0.0, 100.0);
DeclareFloatParam (adjust, "Adjust", kNoGroup, kNoFlags, 0.25, 0.0, 1.0);

DeclareFloatParam (_OutputWidth);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Adjusted)
{
   float4 Color = ReadPixel (Input, uv1);

   if (Color.r < 1.0 - adjust) Color.r = 0.0;
   if (Color.g < 1.0 - adjust) Color.g = 0.0;
   if (Color.b < 1.0 - adjust) Color.b = 0.0;

   return Color;
}

DeclareEntryPoint (Flare)
{
   float2 centre = float2 (CentreX, 1.0 - CentreY);
   float2 amount = float2 (1.0, _OutputAspectRatio) * Stretch / _OutputWidth;
   float2 adj = amount;
   float2 xy = uv2 - centre;

   float scale = 0.0;
   
   float4 source = ReadPixel (Input, uv1);
   float4 negative = tex2D (Adjusted, uv2);
   float4 ret = tex2D (Adjusted, (xy * adj) + centre);

   for (int count = 1; count < 13; count++) {
      scale += Strength;
      adj += amount;
      ret += tex2D (Adjusted, (xy * adj) + centre) * scale;
   }

   ret /= 15.0;
   ret.a = 0.0;

   ret = lerp (0.0.xxxx, saturate (ret + source), source.a);

   return lerp (source, ret, tex2D (Mask, uv1));
}
