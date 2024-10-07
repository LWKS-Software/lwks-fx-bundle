// @Maintainer jwrl
// @Released 2024-10-07
// @Author jwrl
// @Created 2024-10-07

/**
 While this effect is similar to "Extrusion blend", "Extruded edges" is optimised for
 use with text effects.  As the name suggests, it extrudes the edges of text either
 linearly or radially towards a centre point.  The extruded section can be shaded by
 the foreground image, colour shaded, or flat colour filled.  The edge shading can be
 inverted if desired.

 The settings are shown below.
   * Opacity:  Allows fading in or out of the foreground with the applied effect.
   * Key clip:  Adjusts the difference key clip.  If set to zero, it blends the Fg instead.
   * Show key:  Shows the unmodified foreground keyed over a checkerboard background.
   * Show blend:  Shows the foreground with blended edges over black.
   * Edge extrusion
     * Edge type:  Selects between radial or linear and shaded or flat extrusion.
     * Strength:  Fades the extruded edge in or out.
     * Ray length:  Sets the length of the extrusion.
     * Invert shade:  Switches shading between lightest nearest text to darkest.
     * Effect centre X:  Adjusts rhe direction of the extrusion horizontally.
     * Effect centre Y:  Adjusts rhe direction of the extrusion vertically.
     * Edge colour:  Self explanatory.

 In the linear modes the X and Y centering interact: they are really intended to give
 a simple on-screen method of adjusting the extrusion angle.  The length setting is
 intended to adjust the length, not the X-Y centering.

 Masking is applied to the foreground at separation, not, as is more usually the case,
 at the end of the effect.  This means that when show key or show blend are enabled
 masking (and opacity) will not affect the display.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ExtrudedEdges.fx
//
// Version history:
//
// Built 2024-10-07 by jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Extruded edges", "Text", "Text Effects", "Extrudes the edges of text either linearly or radially", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg, Linear, Mirror);
DeclareInput (Bg, Linear, Mirror);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (KeyClip, "Key clip", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (ShowKey,   "Show key",   kNoGroup, false);
DeclareBoolParam (ShowBlend, "Show blend", kNoGroup, false);

DeclareIntParam (Mode, "Edge type", "Edge extrusion", 0, "Linear|Linear colour shaded|Linear coloured|Radial|Radial colour shaded|Radial coloured");

DeclareFloatParam (Strength,  "Strength", "Edge extrusion", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (RayLength, "Ray length", "Edge extrusion", kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (InvertShade, "Invert shade", "Edge extrusion", false);

DeclareFloatParam (Xcentre, "Effect centre", "Edge extrusion", "SpecifiesPointX", 0.4, 0.0, 1.0);
DeclareFloatParam (Ycentre, "Effect centre", "Edge extrusion", "SpecifiesPointY", 0.4, 0.0, 1.0);

DeclareColourParam (Colour, "Edge colour", "Edge extrusion", kNoFlags, 0.38, 0.55, 1.0, 1.0));

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SAMPLE   80
#define HALFWAY  40
#define SAMPLES  81

#define DELTANG  25
#define ALIASFIX 50
#define ANGLE    0.125664

#define R_LUMA 0.2989
#define G_LUMA 0.5866
#define B_LUMA 0.1145

#define B_SCALE  0.0075
#define L_SCALE  0.05
#define R_SCALE  0.00125

#define LIN_OFFS 0.667333

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 checkerboard (float2 uv)
{
   float x = round (frac (uv.x * _OutputWidth  / 64.0));
   float y = round (frac (uv.y * _OutputHeight / 64.0));

   return float4 ((0.45 - clamp (abs (x - y), 0.2, 0.25)).xxx, 1.0);
}

float4 radialEdges (sampler2D F, sampler2D K, float2 uv)
{
   if (ShowKey) return kTransparentBlack;

   float4 Fgnd   = tex2D (F, uv);
   float4 retval = tex2D (K, uv);

   if (RayLength == 0.0) return retval;

   float scale, depth = RayLength * R_SCALE;

   float2 zoomCentre = float2 (Xcentre, 1.0 - Ycentre);
   float2 xy1 = uv;
   float2 xy2 = depth * (uv - zoomCentre);

   retval.rgb = 1.0.xxx - retval.rgb;

   for (int i = 0; i <= SAMPLE; i++) {
      xy1 = uv + (xy2 * i);
      retval += tex2D (K, xy1);
   }

   retval.a = saturate (retval.a);

   retval.rgb = ((retval.rgb / SAMPLES) * 0.75) + 0.125;

   if (InvertShade) retval.rgb = 1.0.xxx - retval.rgb;

   return lerp (retval, Fgnd, Fgnd.a);
}

float4 linearEdges (sampler2D F, sampler2D K, float2 uv)
{
   if (ShowKey) return kTransparentBlack;

   float4 Fgnd   = tex2D (F, uv);
   float4 retval = tex2D (K, uv);

   float2 offset, xy = uv;

   offset.x = Xcentre * LIN_OFFS;
   offset.y = (1.0 - Ycentre) * LIN_OFFS;

   if ((max (abs (offset.x), abs (offset.y)) == 0.0) || (RayLength == 0.0)) return retval;

   float depth = RayLength * L_SCALE;

   retval.rgb = 1.0.xxx - retval.rgb;
   offset *= 1.0 / sqrt ((offset.x * offset.x) + (offset.y * offset.y));
   offset *= depth * B_SCALE;

   for (int i = 0; i < SAMPLES; i++) {
      retval += tex2D (K, xy);
      xy += offset;
      }

   retval.a = saturate (retval.a);

   retval.rgb = ((retval.rgb / SAMPLES) * 0.75) + 0.125;

   if (InvertShade) retval.rgb = 1.0.xxx - retval.rgb;

   return lerp (retval, Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   float4 Fgnd = ReadPixel (Fg, uv1);

   // If key clip is zero it's assumed the foreground isn't blended, with valid alpha,
   // and is returned.  If not, alpha is built from the Fg and Bg using a difference key.
   // This is done using code borrowed from Lightworks' shader "difference.fx".

   if (KeyClip > 0.0) {
      float4 retval = abs (Fgnd - ReadPixel (Bg, uv2));

      if (((retval.r + retval.g + retval.b) * 10.0) <= KeyClip)
         Fgnd.a = 0.0;
   }

   if (!ShowKey && !ShowBlend) Fgnd.a *= ReadPixel (Mask, uv1).x;

   // If the alpha channel is zero we need to blank the Fg to get a clean extrusion.

   return Fgnd.a == 0.0 ? kTransparentBlack : Fgnd;
}

// If the foreground is already blended with the background that is what is returned.
// You can't guarantee clean separation when using a difference key to extract the
// foreground so returning the composite means that any holes will be filled.  If the
// foreground isn't blended with the background only the background is needed.

DeclarePass (Bgd)
{ return KeyClip > 0.0 ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclarePass (Raw)
{
   float4 retval = tex2D (Fgd, uv3);

   if ((Mode == 1) || (Mode == 4)) {
      retval.rgb = Colour.rgb * dot (retval.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   }

   if ((Mode == 2) || (Mode == 5)) {
      retval.rgb = Colour.rgb;
   }

   return retval;
}

DeclarePass (Edge)
{ return Mode < 3 ? linearEdges (Fgd, Raw, uv3) : radialEdges (Fgd, Raw, uv3); }

DeclareEntryPoint (ExtrudedEdge)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 retval;

   if (ShowKey) { retval = lerp (checkerboard (uv3), Fgnd, Fgnd.a); }
   else {
      retval = kTransparentBlack;

      float2 pixsize = float2 (1.0, _OutputAspectRatio) / _OutputWidth;
      float2 offset, scale;

      float angle = 0.0;

      for (int i = 0; i < DELTANG; i++) {
         sincos (angle, scale.x, scale.y);
         offset  = pixsize * scale;
         retval += tex2D (Edge, uv3 + offset);
         retval += tex2D (Edge, uv3 - offset);
         angle  += ANGLE;
      }

      retval  /= ALIASFIX;
      retval   = lerp (kTransparentBlack, retval, retval.a);
      retval   = lerp (retval, Fgnd, Fgnd.a);
      retval.a = max (Fgnd.a, retval.a * Strength);

      if (!ShowBlend) {
         Fgnd   = lerp (tex2D (Bgd, uv3), retval, retval.a);
         retval = lerp (ReadPixel (Bg, uv2), Fgnd, Opacity);
      }
   }

   return retval;
}

