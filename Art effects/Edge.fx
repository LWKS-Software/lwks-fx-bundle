// @Maintainer jwrl
// @Released 2026-06-10
// @Author khaver
// @Created 2011-07-08

/**
 Edge (EdgeFx.fx) detects edges to give a similar result to the well known art program
 effect.  The edge detection is fully adjustable.  Invert and add a little blur over it
 to make the video look as if it's been sketched.

   [*]Threshold:  The level at which the edge is detected.   Similar in behaviour to
      a luminance key clip, it adjusts the level at which an edge will be detected.
      It and the kernel settings interact, so for best effect you may find that you
      need to go back and forth between them a little.
   [*]Kernel
      [*]Kernel 0:  The three kernel settings are used to derive the edges, using a
         convolution algorithm.  See the comment about threshold interaction, above.
      [*]Kernel 1:  See Kernel 0.
      [*]Kernel 2:  See Kernel 0.
   [*]Size X:  Adjusts the width of the edge lines produced.
   [*]Size Y:  Adjusts the height of the edge lines produced.
   [*]Invert:  Inverts the lines from black on white to white on black.
   [*]Edge to alpha:  Generates the edges as opaque over a transparent background,
      meaning that you can blend the edges over other video or over the same video
      processed by other effects.

 It also provides a checkbox to move the generated edge to the alpha channel to allow
 the effect to be overlaid over the video and only affect the edges.  This allows masking
 of the Gaussian Blur effect to blur overly sharpened edges, to give just one example of
 the flexibility that this technique provides.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Edge.fx
//
// Version history:
//
// Updated 2026-06-10 jwrl.
// Added expanded command descriptions to header text.
// Changed masking to full RGBA.
//
// Updated 2023-05-14 jwrl.
// Header reformatted.
//
// Conversion 2022-12-28 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Edge", "Stylize", "Art Effects", "Detects edges to give a similar result to the well known art program effect", "ScaleAware|HasMinOutputSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Input);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Threshold, "Threshold", kNoGroup, "DisplayAsPercentage", 0.5, 0.0, 2.0);

DeclareFloatParam (K00, "Kernel 0", "Kernel", kNoFlags, 2.0, -10.0, 10.0);
DeclareFloatParam (K01, "Kernel 1", "Kernel", kNoFlags, 2.0, -10.0, 10.0);
DeclareFloatParam (K02, "Kernel 2", "Kernel", kNoFlags, 1.0, -10.0, 10.0);

DeclareFloatParam (TextureSizeX, "Size X", kNoGroup, kNoFlags, 512.0, 1.0, 2048.0);
DeclareFloatParam (TextureSizeY, "Size Y", kNoGroup, kNoFlags, 512.0, 1.0, 2048.0);

DeclareBoolParam (Invert, "Invert", kNoGroup, false);
DeclareBoolParam (Alpha, "Edge to alpha", kNoGroup, false);

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Edge)
{
   float4 org = tex2D (Input, uv1);

   if (IsOutOfBounds (uv1) || (org.a <= 0.0)) return kTransparentBlack;

   float ThreshholdSq = Threshold * Threshold;

   float2 offX = float2 (1.0 / TextureSizeX, 0.0);
   float2 offY = float2 (0.0, 1.0 / TextureSizeY);

   // Sample texture - Top row

   float2 texCoord = uv1 - offY;

   float4 c00 = tex2D (Input, texCoord - offX);
   float4 c01 = tex2D (Input, texCoord);
   float4 c02 = tex2D (Input, texCoord + offX);

   // Middle row

   float4 c10 = tex2D (Input, uv1 - offX);
   float4 c12 = tex2D (Input, uv1 + offX);

   // Bottom row

   texCoord = uv1 + offY;

   float4 c20 = tex2D (Input, texCoord - offX);
   float4 c21 = tex2D (Input, texCoord);
   float4 c22 = tex2D (Input, texCoord + offX);

   // Convolution

   float4 sx = ((c00 - c20) * K00) + ((c01 - c21) * K01) + ((c02 - c22) * K02);
   float4 sy = ((c00 - c02) * K00) + ((c10 - c12) * K01) + ((c20 - c22) * K02);

   // Add and apply Threshold

   float4 s = sx * sx + sy * sy;
   float4 edge = float4 (s.r <= ThreshholdSq, s.g <= ThreshholdSq, s.b <= ThreshholdSq, org.a);

   if (!Invert) edge.rgb = 1.0.xxx - edge.rgb;

   if (Alpha) {
      float alpha = (edge.r + edge.g + edge.b) / 3.0;
      edge = float4 (org.rgb, alpha);
      }

   return lerp (org, edge, tex2D (Mask, uv1));
}
