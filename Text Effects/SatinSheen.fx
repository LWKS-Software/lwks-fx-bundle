// @Maintainer jwrl
// @Released 2024-10-07
// @Author jwrl
// @Author schrauber
// @Created 2024-10-07

/**
 This effect produces a satin sheen on text by blurring the edges and using that blur as
 an alpha channel to key the main and edge colours over the original text colour.  The
 text can either be extreacted from the background using a difference key, or can be
 used directly and blended over the background before the sheen effect is applied.  The
 settings are:

   * Opacity : Fades Fg along with the sheen effect in or out.
   * Key clip : When zero treats Fg as unblended otherwise produces a difference key.
   * Show key : Displays Fg over a transparent checkerboard background.
   * Show blend : Displays the composite effect over black without Opacity or masking.
   * Satin
      * Width : Adjusts the width of the edge colour.
      * Edge opacity : Mixes in the amount of edge colour used.
      * Edge colour : Self explanatory.
      * Main opacity : Mixes in the amount of main colour used.
      * Main colour : Self explanatory

 The default colours have been chosen for best impact over white text.  If the text has
 shading already it would be advisable to reduce the main opacity.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect SatinSheen.fx
//
// The blur engine used here may look similar to Lightworks' BigBlur2.fx.  It should do.
// In their blur effect Lightworks uses code developed by schrauber and myself based on
// earlier code developed by schrauber and khaver.  This effect uses one of the variants
// of the blur engine that was not actually used by Lightworks.  After much thought I
// have decided not to credit khaver because sadly there is none of his code used here.
//
// Version history:
//
// Built 2024-10-07 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Satin sheen", "Text", "Text Effects", "Adds a satin-like sheen to text", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg, Linear, Mirror);
DeclareInput (Bg, Linear, Mirror);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity",  kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (KeyClip, "Key clip", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (ShowKey,   "Show key",   kNoGroup, false);
DeclareBoolParam (ShowBlend, "Show blend", kNoGroup, false);

DeclareFloatParam (Width, "Width", "Satin", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (EdgeOpacity, "Edge opacity", "Satin", kNoFlags, 1.0, 0.0, 1.0);
DeclareColourParam (EdgeColour, "Edge colour",  "Satin", kNoFlags, 0.26, 0.45, 0.84, 1.0);

DeclareFloatParam (MainOpacity, "Main opacity", "Satin", kNoFlags, 1.0, 0.0, 1.0);
DeclareColourParam (MainColour, "Main colour",  "Satin", kNoFlags, 0.67, 0.78, 0.99, 1.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI_HALF      1.5708  // 90 degrees in radians
#define PI_SIXTH     0.5236  // 30 degrees in radians

#define OFFSET_1     0.1309  // 7.5 degrees in radians
#define OFFSET_2     0.2618  // 15
#define OFFSET_3     1.9635  // 112.5 (22.5 + 90)
#define OFFSET_4     0.3927  // 22.5

#define SCALE_WIDTH  0.01

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 checkerboard (float2 uv)
{
   float x = round (frac (uv.x * _OutputWidth  / 64.0));
   float y = round (frac (uv.y * _OutputHeight / 64.0));

   return float4 ((0.45 - clamp (abs (x - y), 0.2, 0.25)).xxx, 1.0);
}

float makeEdge (sampler2D S, float2 uv, float offset)
{
   float4 retval = tex2D (S, uv);

   // What follows is a sampling of the input video, radially offset in 30 degree
   // intervals through 360 degrees (in radians).  Where this should have the X
   // coordinates offset by a cosine of the angle and the Y by the sine of that
   // same angle this is achieved by making sines of X and Y simultaneously, with
   // the X angle offset by 90 degrees.  The Y offset is also adjusted by the
   // output aspect ratio to ensure sampling circularity.

   float2 radius = float2 (1.0, _OutputAspectRatio) * Width * SCALE_WIDTH;
   float2 angle  = float2 (offset + PI_HALF, offset);
   float2 coord;

   for (int tap = 0; tap < 12; tap++) {
      coord   = uv + (sin (angle) * radius);
      retval += tex2D (S, coord);
      angle  += PI_SIXTH;
   }

   return retval / 13.0;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{
   float4 Fgnd = ReadPixel (Fg, uv1);

   // If KeyClip is zero it's assumed that the foreground has a valid alpha channel.  If
   // not alpha is created from the difference between the Fg/Bg composite and clean Bg.

   if (KeyClip > 0.0) {
      float4 retval = abs (Fgnd - ReadPixel (Bg, uv2));

      if (((retval.r + retval.g + retval.b) * 10.0) <= KeyClip)
         Fgnd.a = 0.0;
   }

   // If the alpha channel is zero we need to blank the Fg.

   if (Fgnd.a == 0.0) { Fgnd = kTransparentBlack; }

   return ShowKey ? lerp (checkerboard (uv3), Fgnd, Fgnd.a) : Fgnd;
}

// If the foreground isn't blended with the background only the background is needed.
// If the foreground is blended, because you can't guarantee clean separation when
// using a difference key the composite is returned to fill any separation holes.

DeclarePass (Bgd)
{ return KeyClip > 0.0 ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

// Initially a faux alpha channel is created based on the Fg luminance.

DeclarePass (Init)
{
   if (ShowKey) return kTransparentBlack;

   float4 bounds = tex2D (Fgd, uv3);

   return saturate (max (bounds.r, max (bounds.g, bounds.b)) * 10.0).xxxx;
}

DeclarePass (Edge_1)
{ return ShowKey ? kTransparentBlack : makeEdge (Init, uv3, 0.0); }

DeclarePass (Edge_2)
{ return ShowKey ? kTransparentBlack : makeEdge (Edge_1, uv3, OFFSET_1); }

DeclarePass (Sheen)
{ return ShowKey ? kTransparentBlack : makeEdge (Edge_2, uv3, OFFSET_2); }

DeclareEntryPoint (SatinSheen)
{
   float4 retval = tex2D (Fgd,  uv3);

   if (!ShowKey) {
      float alpha = tex2D (Sheen, uv3).a;

      float2 radius = float2 (1.0, _OutputAspectRatio) * Width * SCALE_WIDTH;
      float2 angle  = float2 (OFFSET_3, OFFSET_4);
      float2 coord;

      for (int tap = 0; tap < 12; tap++) {
         coord  = uv3 + (sin (angle) * radius);
         alpha += tex2D (Sheen, coord).a;
         angle += PI_SIXTH;
      }

      alpha /= 6.5;

      float aMask = tex2D (Init, uv3).a;
      float aMain = saturate (alpha - 1.0) * MainOpacity * aMask;
      float aEdge = saturate (2.0 - alpha) * EdgeColour.a * EdgeOpacity * aMask;

      float4 Edge = lerp (lerp (retval, MainColour, aMain), EdgeColour, aEdge);

      Edge.a = retval.a;

      if (ShowBlend) { retval = lerp (float4 (0.0.xxx, 1.0), Edge, Edge.a); }
      else {
         float4 Fgnd = lerp (tex2D (Bgd,  uv3), Edge, Edge.a);

         retval = lerp (ReadPixel (Bg, uv2), Fgnd, tex2D (Mask, uv3).x * Opacity);
      }
   }

   return retval;
}

