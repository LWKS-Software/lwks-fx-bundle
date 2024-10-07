// @Maintainer jwrl
// @Released 2024-10-07
// @Author jwrl
// @Created 2024-10-07

/**
 This provides a means of adding colour just inside the edges of text.  The individual
 left, right, top and bottom edges can be individually coloured, and the thickness of
 the colour can also be independently adjusted.  Each edge has its own opacity setting.

 Master opacity, scale and insert softness are adjustable, and the line boundaries can
 be inverted.  The settings and what they do are:

   *  Opacity:  Fades the text and coloured edge composite in or out.
   *  Key separation:  Adjusts the difference key clip.  If 0, does a standard blend.
   *  Show key:  Shows the unmodified foreground keyed over a checkerboard background.
   *  Show blend:  Shows the foreground with blended edges over black.
   *  All edges
     *  Opacity:  Adjusts the opacity of all four edge overlays.
     *  Scale:  Adjusts the thickness of all four edge overlays.
     *  Softness:  Softens the edge of all four coloured edge overlays.
   *  Left edge
     *  Opacity:  Adjusts the opacity of the left edge overlay.
     *  Width:  Adjusts the width of the left edge overlay.
     *  Colour:  Sets the colour to be used for the left edge overlay.
   *  Right edge - as for left edge.
   *  Top edge - as for left edge.
   *  Bottom edge - as for left edge.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect EdgeColour.fx
//
// Version history:
//
// Built 2024-10-07 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Edge colour", "Text", "Text Effects", "Colours the inside edges of text and other blends", CanSize);

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

DeclareFloatParam (OpacityA, "Opacity",  "All edges", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Scale,    "Scale",    "All edges", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Softness, "Softness", "All edges", kNoFlags, 0.3, 0.0, 1.0);

DeclareFloatParam (OpacityL,  "Opacity", "Left edge",   kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Width_L,   "Width",   "Left edge",   kNoFlags, 0.5, 0.0, 1.0);

DeclareColourParam (Colour_L, "Colour",  "Left edge",   kNoFlags, 0.09, 0.20, 0.78, 1.0);

DeclareFloatParam (OpacityR,  "Opacity", "Right edge",  kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Width_R,   "Width",   "Right edge",  kNoFlags, 0.5, 0.0, 1.0);

DeclareColourParam (Colour_R, "Colour",  "Right edge",  kNoFlags, 0.28, 0.93, 1.00, 1.0);

DeclareFloatParam (OpacityT,  "Opacity", "Top edge",    kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Width_T,   "Height",  "Top edge",    kNoFlags, 0.5, 0.0, 1.0);

DeclareColourParam (Colour_T, "Colour",  "Top edge",    kNoFlags, 0.22, 0.69, 0.93, 1.0);

DeclareFloatParam (OpacityB,  "Opacity", "Bottom edge", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Width_B,   "Height",  "Bottom edge", kNoFlags, 0.5, 0.0, 1.0);

DeclareColourParam (Colour_B, "Colour",  "Bottom edge", kNoFlags, 0.15, 0.44, 0.52, 1.0);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define OFFSET 10.0

#define LOOP   12

#define RADIUS 2.0
#define ANGLE  0.2617993878

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 checkerboard (float2 uv)
{
   float x = round (frac (uv.x * _OutputWidth  / 64.0));
   float y = round (frac (uv.y * _OutputHeight / 64.0));

   return float4 ((0.45 - clamp (abs (x - y), 0.2, 0.25)).xxx, 1.0);
}

float4 makeBlur (sampler2D S, float2 uv, float2 xy)
{
   float4 retval = tex2D (S, uv);

   float2 xy1 = uv + xy;
   float2 xy2 = uv - xy;

   retval += tex2D (S, xy1); xy1 += xy;
   retval += tex2D (S, xy1); xy1 += xy;
   retval += tex2D (S, xy1); xy1 += xy;
   retval += tex2D (S, xy1); xy1 += xy;
   retval += tex2D (S, xy1); xy1 += xy;
   retval += tex2D (S, xy1);

   retval += tex2D (S, xy2); xy2 -= xy;
   retval += tex2D (S, xy2); xy2 -= xy;
   retval += tex2D (S, xy2); xy2 -= xy;
   retval += tex2D (S, xy2); xy2 -= xy;
   retval += tex2D (S, xy2); xy2 -= xy;
   retval += tex2D (S, xy2);

   retval /= 13.0;

   return retval;
}

float4 ShapeSub (sampler Txt, float2 uv, float2 pp, float4 Colour, float Opct)
{
   // This gets the raw shape to use for the gloss.  First we calculate the sample radius
   // and displacement.  These are based on the scaled output size so that subjectively
   // they appear consistent, regardless of the actual size.

   float2 radius  = RADIUS / float2 (_OutputWidth, _OutputHeight);
   float2 xy, xy1 = uv - (pp * Scale * radius * OFFSET);

   // Now set up for the initial alpha loop state.

   float4 rawV = tex2D (Txt, xy1);

   float angle = 0.0;

   // This loop produces the raw edge shape, the thickness of which is set by the offset
   // value.  Multiplication is used because this tends to protect against adjacent text
   // affecting the shape of the thickened edges.  The downside is that it will produce
   // inverted edges.  That's not really a big deal as long as we remember to correct it.

   for (int i = 0; i < LOOP; i++) {
      angle += ANGLE;
      sincos (angle, xy.x, xy.y);
      xy *= radius;
      rawV *= tex2D (Txt, xy1 + xy);
   }

   // A new alpha channel is now created, inverted and masked by the original text's alpha.

   float alpha = max (rawV.r, max (rawV.g, rawV.b));

   alpha  = 1.0 - saturate (alpha * 10.0);
   alpha *= tex2D (Txt, uv).a;

   // Finally the coloured edge is returned to the calling shader.

   return Colour * alpha * Opct * OpacityA;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

// The foreground is split from the blended background by difference key.

DeclarePass (Fgd)
{
   float4 Fgnd = ReadPixel (Fg, uv1);

   // If key clip is zero it's assumed the foreground isn't blended, with valid alpha.  If
   // not alpha is built from the Fg/Bg difference.  This is done with code from Lightworks'
   // shader "difference.fx" because it's more efficient than the one that I wrote myself.

   if (KeyClip > 0.0) {
      float4 retval = abs (Fgnd - ReadPixel (Bg, uv2));

      if (((retval.r + retval.g + retval.b) * 10.0) <= KeyClip)
         Fgnd.a = 0.0;
   }

   // If the alpha channel is zero we need to blank the Fg.

   if (Fgnd.a == 0.0) { Fgnd = kTransparentBlack; }

   return ShowKey ? lerp (checkerboard (uv3), Fgnd, Fgnd.a) : Fgnd;
}

// If the foreground is already blended with the background that is what is returned.
// You can't guarantee clean separation when using a difference key to extract the
// foreground so returning the composite means that any holes will be filled.  If the
// foreground isn't blended with the background only the background is needed.

DeclarePass (Bgd)
{ return KeyClip > 0.0 ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclarePass (Shape)
{
   if (ShowKey) return kTransparentBlack;

   float4 edge_L = ShapeSub (Fgd, uv3, float2 (Width_L, 0.0),  Colour_L, OpacityL);
   float4 edge_T = ShapeSub (Fgd, uv3, float2 (0.0, -Width_T), Colour_T, OpacityT);
   float4 edge_R = ShapeSub (Fgd, uv3, float2 (-Width_R, 0.0), Colour_R, OpacityR);
   float4 edge_B = ShapeSub (Fgd, uv3, float2 (0.0, Width_B),  Colour_B, OpacityB);

   float4 edge_1 = lerp (edge_T, edge_L, edge_L.a);
   float4 edge_2 = lerp (edge_B, edge_R, edge_R.a);

   return lerp (edge_2, edge_1, edge_1.a);
}

DeclarePass (Blur)
{
   return ShowKey ? kTransparentBlack
                  : makeBlur (Shape, uv3, float2 (2.0 * Softness / _OutputWidth, 0.0));
}

DeclareEntryPoint (TextEdges)
{
   float4 retval = tex2D (Fgd,  uv3);

   if (!ShowKey) {
      float4 Edge = makeBlur (Blur, uv3, float2 (0.0, 2.0 * Softness / _OutputHeight));

      if (ShowBlend) { retval = lerp (retval, Edge, Edge.a); }
      else {
         float4 Bgnd = tex2D (Bgd,  uv3);
         float4 Fgnd = lerp (lerp (Bgnd, retval, retval.a), Edge, Edge.a);

         retval = lerp (ReadPixel (Bg, uv2), Fgnd, tex2D (Mask, uv3).x * Opacity);
      }
   }

   return retval;
}

