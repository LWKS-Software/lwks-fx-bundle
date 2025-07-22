// @Maintainer jwrl
// @Released 2024-04-13
// @Author jwrl
// @Created 2024-04-12

/**
 This effect is a customised version of the Lightworks Chromakey effect with a very
 much simplified perspective effect added to the foreground video.  The foreground
 image can be cropped prior to the key being generated. After the key has been
 generated perspective is applied, and finally the key is blended with the the
 background video.

 To help with setting up the effect, in addition to the two standard Invert and
 Reveal switches there are also switches associated with keying, perspective and
 cropping.  They are:

   1. Disable chromakey.  Disables the chromakey to help with effect setup.
   2. Disable crop.  Disables foreground cropping, showing the foreground full screen.
   3. Show perspective boundary.  Displays a border around the active sequence area.
   4. Disable perspective.  Turns foreground perspective off.

 When the effect is applied you will notice a reduction in the size of the foreground
 video.  This is because the perspective settings by default are 5% inside the total
 screen area.  This has been done so that the corner pins can more easily be clicked
 on for dragging.

 Cropping can also be set up using the mask parameters.  Since masking is applied
 after everything else in the effect it will not track the perspective settings.
 In practice this may not be a problem if you don't intend keyframing the perspective.

 The Chromakey section is based on the Chromakey effect included in Lightworks and is
 copyright (c) LWKS Software Ltd.  It has been modified to aid keying over transparent
 backgrounds and mismatched aspect ratio video sources.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ChromakeyPerspective.fx
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
// Modified 2024-04-13 jwrl.
// Corrected a bug caused by bad values returned by _OutputWidth and _OutputHeight.  It
// has been brought to the attention of Lightworks' developers.  It is highly likely
// that any changes in their code will require further modifcation of this code.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Chromakey with perspective", "Key", "Key Extras", "A chromakey effect with simplified perspective simulation", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareColourParam (KeyColour, "Key colour", "Chromakey", "SpecifiesColourRange", 150.0, 0.8, 0.8, -1.0);
DeclareColourParam (Tolerance, "Tolerance", "Chromakey", "SpecifiesColourRange|Hidden", 20.0, 0.2, 0.2, -1.0);
DeclareColourParam (ToleranceSoftness, "Tolerance softness", "Chromakey", "SpecifiesColourRange|Hidden", 10.0, 0.1, 0.1, -1.0);

DeclareFloatParam (KeySoftAmount, "Key softness", "Chromakey", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (RemoveSpill, "Remove spill", "Chromakey", kNoFlags, 0.5, 0.0, 1.0);

DeclareBoolParam (Invert, "Invert", "Chromakey", false);
DeclareBoolParam (Reveal, "Reveal", "Chromakey", false);

DeclareBoolParam (HideKey, "Disable chromakey", kNoGroup, false);

DeclareBoolParam (HideCropping, "Disable cropping", "Crop", false);

DeclareFloatParam (Left, "Left", "Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Right, "Right", "Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Top, "Top", "Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Bottom, "Bottom", "Crop", kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (Bounds, "Show perspective boundary", "Corner pins", false);
DeclareBoolParam (HidePerspective, "Disable perspective", "Corner pins", false);

DeclareFloatParam (TLx, "Top left", "Corner pins", "SpecifiesPointX", 0.05, 0.0, 1.0);
DeclareFloatParam (TLy, "Top left", "Corner pins", "SpecifiesPointY", 0.95, 0.0, 1.0);

DeclareFloatParam (TRx, "Top right", "Corner pins", "SpecifiesPointX", 0.95, 0.0, 1.0);
DeclareFloatParam (TRy, "Top right", "Corner pins", "SpecifiesPointY", 0.95, 0.0, 1.0);

DeclareFloatParam (BLx, "Bottom left", "Corner pins", "SpecifiesPointX", 0.05, 0.0, 1.0);
DeclareFloatParam (BLy, "Bottom left", "Corner pins", "SpecifiesPointY", 0.05, 0.0, 1.0);

DeclareFloatParam (BRx, "Bottom right", "Corner pins", "SpecifiesPointX", 0.95, 0.0, 1.0);
DeclareFloatParam (BRy, "Bottom right", "Corner pins", "SpecifiesPointY", 0.05, 0.0, 1.0);

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define HUE_IDX 0
#define SAT_IDX 1
#define VAL_IDX 2

#define H_BLUR     0.0015625
#define LINE_WIDTH 0.00390625

float _FallOff = 0.12;
float _oneSixth = 1.0 / 6.0;
float _minTolerance = 1.0 / 256.0;

float blur[] = { 20.0 / 64.0, 15.0 / 64.0, 6.0  / 64.0, 1.0  / 64.0 };  // Pascal's Triangle

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

bool allPositive (float4 pix)
{ return (pix.r > 0.0) && (pix.g > 0.0) && (pix.b > 0.0); }

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
// Convert the source to HSV and then compute its similarity to the specified key colour.
// Unlike the Lightworks version of this pass, this checks for the presence of valid
// video, and if there is none, quit.  As a result the original foreground sampler code
// has been removed.  A flag is only set in the z byte if the key is valid.
//-----------------------------------------------------------------------------------------//

DeclarePass (RawKey)
{
   if (HideKey) return kTransparentBlack;

   float keyVal = 1.0;
   float hueSimilarity = 1.0;

   // First recover the cropped image.

   float4 tolerance1 = Tolerance + _minTolerance;
   float4 tolerance2 = tolerance1 + ToleranceSoftness;
   float4 rgba = tex2D (Fgd, uv3);
   float4 hsva = 0.0.xxxx;

   // The float maxComponentVal has been set up here to save a redundant evalution
   // in the following conditional code.

   float maxComponentVal = max (max (rgba.r, rgba.g), rgba.b);

   // Check if rgba is zero and if it is we need do nothing.  This check is done
   // because up to now we have no way of knowing what the contents of rgba are.
   // This catches all null values in the original image.

   if (max (maxComponentVal, rgba.a) == 0.0) return rgba;

   // Now return to the Lightworks original, minus the rgba = tex2D() section and
   // the maxComponentVal initialisation for the HSV conversion.

   float minComponentVal = min (min (rgba.r, rgba.g), rgba.b);
   float componentRange  = maxComponentVal - minComponentVal;

   hsva [VAL_IDX] = maxComponentVal;
   hsva [SAT_IDX] = componentRange / maxComponentVal;

   if (hsva [SAT_IDX] == 0.0) { hsva [HUE_IDX] = 0.0; }      // undefined colour
   else {
      if (rgba.r == maxComponentVal) { hsva [HUE_IDX] = (rgba.g - rgba.b) / componentRange; }
      else if (rgba.g == maxComponentVal) { hsva [HUE_IDX] = 2.0 + ((rgba.b - rgba.r) / componentRange); }
      else { hsva [HUE_IDX] = 4.0 + ((rgba.r - rgba.g) / componentRange); }

      hsva [HUE_IDX] *= _oneSixth;
      if (hsva [HUE_IDX] < 0.0) hsva [HUE_IDX] += 1.0;
   }

   // Calculate the difference between the current pixel and the specified key-colour

   float4 diff = abs (hsva - KeyColour);

   if (diff [HUE_IDX] > 0.5) { diff [HUE_IDX] = 1.0 - diff [HUE_IDX]; }

   // Work out how transparent/opaque the corrected pixel will be

   if (allPositive (tolerance2 - diff)) {
      if (allPositive (tolerance1 - diff)) { keyVal = 0.0; }
      else {
         diff -= tolerance1;
         hueSimilarity = diff [HUE_IDX];
         diff /= ToleranceSoftness;
         keyVal = max (diff [HUE_IDX], max (diff [SAT_IDX], diff [VAL_IDX]));
         keyVal = pow (keyVal, 0.25);
      }
   }
   else {
      diff -= tolerance1;
      hueSimilarity = diff [HUE_IDX];
   }

   // New flag set in z to indicate that key generation actually took place

   return float4 (keyVal, keyVal, 1.0, 1.0 - hueSimilarity);
}

//-----------------------------------------------------------------------------------------//
// Blur X
//
// Does the horizontal component of a box blur.  There is a check for a valid key presence
// at the start of this pass using the flag in retval.z, and if not, bypass this.
//-----------------------------------------------------------------------------------------//

DeclarePass (Blur_X)
{
   float4 retval = tex2D (RawKey, uv3);

   // This next check will only be true if key generation has been bypassed.

   if (retval.z != 1.0) return retval;

   float2 onePixel    = float2 (H_BLUR, 0.0) * KeySoftAmount;
   float2 twoPixels   = onePixel + onePixel;
   float2 threePixels = onePixel + twoPixels;

   // Calculate return retval;

   retval.x *= blur [0];
   retval.x += tex2D (RawKey, uv3 + onePixel).x    * blur [1];
   retval.x += tex2D (RawKey, uv3 - onePixel).x    * blur [1];
   retval.x += tex2D (RawKey, uv3 + twoPixels).x   * blur [2];
   retval.x += tex2D (RawKey, uv3 - twoPixels).x   * blur [2];
   retval.x += tex2D (RawKey, uv3 + threePixels).x * blur [3];
   retval.x += tex2D (RawKey, uv3 - threePixels).x * blur [3];

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Blur Y
//
// Adds the vertical component of a box blur.  As with the horizontal blur, there is a
// check for a valid key presence at the start of the pass.
//-----------------------------------------------------------------------------------------//

DeclarePass (Blur_Y)
{
   float4 retval = tex2D (Blur_X, uv3);

   if (retval.z != 1.0) return retval;

   float2 onePixel    = float2 (0.0, H_BLUR) * KeySoftAmount * _OutputAspectRatio;
   float2 twoPixels   = onePixel + onePixel;
   float2 threePixels = onePixel + twoPixels;

   // Calculate return retval;

   retval.x *= blur [0];
   retval.x += tex2D (Blur_X, uv3 + onePixel).x    * blur [1];
   retval.x += tex2D (Blur_X, uv3 - onePixel).x    * blur [1];
   retval.x += tex2D (Blur_X, uv3 + twoPixels).x   * blur [2];
   retval.x += tex2D (Blur_X, uv3 - twoPixels).x   * blur [2];
   retval.x += tex2D (Blur_X, uv3 + threePixels).x * blur [3];
   retval.x += tex2D (Blur_X, uv3 - threePixels).x * blur [3];

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Foreground keyer
//
// This pass keys the foreground over transparent black using the key components that
// were built earlier. Spill suppression and cropping is also applied at this stage.
// Finally cropping and bounds display are enabled if necessary.
//-----------------------------------------------------------------------------------------//

DeclarePass (FgKey)
{
   float4 Fgnd = tex2D (Fgd, uv3);
   float4 Key  = tex2D (Blur_Y, uv3);

   // Key.w = spill removal amount
   // Key.x = blurred key
   // Key.y = raw, unblurred key
   // Key.z = valid key flag

   if (Key.z == 1.0) {
      // Using min (Key.x, Key.y) means that any softness around the key causes the
      // foreground to shrink in from the edges.  After we derive the mix amount we
      // invert the spill removal and the mix amount if necessary.

      float mixAmount  = saturate ((1.0 - min (Key.x, Key.y) * Fgnd.a) * 2.0);

      if (Invert) {
         mixAmount = 1.0 - mixAmount;
         Key.w = 1.0 - Key.w;
      }

      // Perform spill removal on the foreground if necessary

      if (Key.w > 0.8) {
         float4 FgdLum = float4 (((Fgnd.r + Fgnd.g + Fgnd.b) / 3.0).xxx, 1.0);

         Fgnd = lerp (Fgnd, FgdLum, ((Key.w - 0.8) * 5.0) * RemoveSpill);    // Remove spill.
      }

      Fgnd.a = Reveal ? mixAmount : 1.0 - mixAmount;
   }

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
// Blend the foreground with the background using the keyed foreground that was built
// above.  During this process perspective is applied to the key.  The key and the
// keyed image can both be previewed with and without perspective distortion.
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (ChromakeyPerspective)
{
   float4 retval = tex2D (FgKey, uv3);
   float4 Fgnd, Bgnd = tex2D (Bgd, uv3);

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

   Fgnd.a *= tex2D (Mask, uv3).x;

   if (Reveal && !HideKey) { retval = float4 (Fgnd.aaa, 1.0); }
   else {
      Fgnd.a  *= saturate (Opacity);
      retval   = lerp (Bgnd, Fgnd, Fgnd.a);
      retval.a = max (Bgnd.a, Fgnd.a);
   }

   return retval;
}
