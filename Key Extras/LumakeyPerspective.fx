// @Maintainer jwrl
// @Released 2024-05-16
// @Author jwrl
// @Created 2024-05-16

/**
 This keyer is similar to the Lightworks lumakey effect, but has a perspective
 ability as well.  In addition to the standard Invert switch to help set up the
 effect there are switches associated with keying, perspective and cropping.
 They are:

   1. Disable key.  Exactly what it says.
   2. Disable crop.  Disables cropping, showing the foreground full screen.
   3. Show perspective boundary.  Displays a border around the active sequence area.
   4. Disable perspective.  Allso exactly what it says.

 When the effect is applied you will notice a reduction in the size of the foreground
 video.  This is because the perspective settings by default are 5% inside the total
 screen area.  This has been done so that the corner pins can more easily be dragged.

 The key section behaves exactly like an analogue luminance keyer.  "Tolerance" is
 called "Clip" and "Invert" is "Invert key".  When the key clip is exceeded by the
 image luminance the key alpha channel is turned fully on, consistent with the way
 that an analogue keyer behaves.  Regardless of whether the key is inverted or not,
 the clip setting works from black at 0% to white at 100%.

 The alpha channel can either replace the foreground's existing alpha channel or can
 be gated with it.  It is then to key the foreground over the background.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LumakeyPerspective.fx
//
// The perspective component of this effect is based on Perspective copyright (C) 2011
// by Evan Wallace, forked by windsturm 2012-08-14.  That component requires that the
// following comment is included.  Note this absolutely does NOT include the chromakey
// component, which is copyright (c) LWKS Software Ltd.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify,
// merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be included in all copies
// or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
// OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// Version history:
//
// Built 2024-05-16 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Lumakey with perspective", "Key", "Key Extras", "A Lumakey effect with simplified perspective simulation", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (KeyMode, "Mode", "Key settings", 0, "Luminance key|Key plus foreground alpha");

DeclareFloatParam (KeyClip,  "Clip",     "Key settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Softness, "Softness", "Key settings", kNoFlags, 0.1, 0.0, 1.0);

DeclareBoolParam (InvertKey,    "Invert key",       kNoFlags, false);
DeclareBoolParam (HideCropping, "Disable cropping", kNoFlags, false);

DeclareFloatParam (Left,  "Left",    "Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Right,  "Right",  "Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Top,    "Top",    "Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Bottom, "Bottom", "Crop", kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (Bounds,          "Show perspective boundary", "Corner pins", false);
DeclareBoolParam (HidePerspective, "Disable perspective",       "Corner pins", false);

DeclareFloatParam (TLx, "Top left",     "Corner pins", "SpecifiesPointX", 0.05, 0.0, 1.0);
DeclareFloatParam (TLy, "Top left",     "Corner pins", "SpecifiesPointY", 0.95, 0.0, 1.0);

DeclareFloatParam (TRx, "Top right",    "Corner pins", "SpecifiesPointX", 0.95, 0.0, 1.0);
DeclareFloatParam (TRy, "Top right",    "Corner pins", "SpecifiesPointY", 0.95, 0.0, 1.0);

DeclareFloatParam (BLx, "Bottom left",  "Corner pins", "SpecifiesPointX", 0.05, 0.0, 1.0);
DeclareFloatParam (BLy, "Bottom left",  "Corner pins", "SpecifiesPointY", 0.05, 0.0, 1.0);

DeclareFloatParam (BRx, "Bottom right", "Corner pins", "SpecifiesPointX", 0.95, 0.0, 1.0);
DeclareFloatParam (BRy, "Bottom right", "Corner pins", "SpecifiesPointY", 0.05, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define R_LUMA 0.2989
#define G_LUMA 0.5866
#define B_LUMA 0.1145

#define LINE_WIDTH 0.00390625

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

//-----------------------------------------------------------------------------------------//
// Initialise foreground and background, mapping them to sequence coordinates.
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

//-----------------------------------------------------------------------------------------//
// Key generation
//
// Produces a standard analogue-style luminance key over transparent black.
//-----------------------------------------------------------------------------------------//

DeclarePass (FgKey)
{
   float4 Fgnd = tex2D (Fgd, uv3);

   float luma  = dot (Fgnd.rgb, float3 (R_LUMA, G_LUMA, B_LUMA));
   float edge  = max (0.00001, Softness);
   float clip  = (KeyClip * 1.0002) - (edge * 0.5) - 0.0001;
   float alpha = saturate ((luma - clip) / edge);

   if (InvertKey) alpha = 1.0 - alpha;

   Fgnd.a = KeyMode == 0 ? alpha : min (Fgnd.a, alpha);

   // Now we crop the foreground by setting the alpha to zero

   float2 xy1, xy2;

   if (!HideCropping) {
      xy1 = saturate (float2 (Left, Top));
      xy2 = 1.0.xx - saturate (float2 (Right, Bottom));

      if ((uv3.x < xy1.x) || (uv3.x > xy2.x) || (uv3.y < xy1.y) || (uv3.y > xy2.y))
         Fgnd = kTransparentBlack;
   }

   if (Bounds) {
      xy1 = float2 (1.0, _OutputAspectRatio) * LINE_WIDTH;
      xy2 = 1.0.xx - xy1;

      if ((xy1.x > uv3.x) || (xy2.x < uv3.x) || (xy1.y > uv3.y) || (xy2.y < uv3.y))
         Fgnd = 1.0.xxxx;
   }

   return Fgnd;
}

//-----------------------------------------------------------------------------------------//
// Compositing
//
// Blend the foreground with the background using the keyed component built in the pass
// above this.  During this process perspective is applied.  To help with setting up the
// key and keyed image can be previewed with and without perspective distortion.
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (LumakeyPerspective)
{
   float4 retval, Fgnd, Bgnd = tex2D (Bgd, uv3);

   if (HidePerspective) { Fgnd = tex2D (FgKey, uv3); }
   else {
      float2 xy1 = float2 (TRx - BLx, BLy - TRy);
      float2 xy2 = float2 (BRx - BLx, BLy - BRy);
      float2 xy3 = float2 (TLx - TRx, TRy - TLy);
      float2 xy0 = xy3 - xy2;
      float den = (xy1.x * xy2.y) - (xy2.x * xy1.y);
      float top = ((xy0.x * xy2.y) - (xy2.x * xy0.y)) / den;
      float bot = ((xy1.x * xy0.y) - (xy0.x * xy1.y)) / den;
      float bt1 = bot + 1.0;

      float3x3 coord3D = float3x3 (
         (top * TRx) - xy3.x, (top * (1.0 - TRy)) - xy3.y, top,
         (BRx * bt1) - TLx, TLy + bot - (BRy * bt1), bot,
         TLx, 1.0 - TLy, 1.0);

      float a = coord3D [0].x, b = coord3D [0].y, c = coord3D [0].z;
      float d = coord3D [1].x, e = coord3D [1].y, f = coord3D [1].z;
      float g = coord3D [2].x, h = coord3D [2].y, i = coord3D [2].z;
      float x = (e * i) - (f * h), y = (f * g) - (d * i), z = (d * h) - (e * g);

      den = (a * x) + (b * y) + (c * z);

      float3x3 v = float3x3 (x, (c * h) - (b * i), (b * f) - (c * e),
                             y, (a * i) - (c * g), (c * d) - (a * f),
                             z, (b * g) - (a * h), (a * e) - (b * d)) / den;
      float3x3 r = float3x3 (v [0].x - v [0].y, -v [0].y, v [0].z - (v [0].y * 2.0),
                             v [1].x - v [1].y, -v [1].y, v [1].z - (v [1].y * 2.0),
                             v [2].x - v [2].y, -v [2].y, v [2].z - (v [2].y * 2.0));
      float3 xyz = mul (float3 (uv3, 1.0), r);

      xy0 = xyz.xy / xyz.z;
      Fgnd = any (xy0 - frac (xy0)) ? kTransparentBlack : tex2D (FgKey, xy0);
   }

   Fgnd.a  *= saturate (Opacity) * tex2D (Mask, uv3).x;
   retval   = lerp (Bgnd, Fgnd, Fgnd.a);
   retval.a = max (Bgnd.a, Fgnd.a);

   return retval;
}

