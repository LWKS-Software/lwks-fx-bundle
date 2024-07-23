// @Maintainer jwrl
// @Released 2024-07-23
// @Author jwrl
// @Created 2024-07-23

/**
 Quad split with transform is designed as a single effect replacement for Lightworks'
 quad split template.  It has been enhanced to help in the creation of these often-
 used multiscreen images.

 First, a downstream transform effect similar to the Lightworks transform effect has
 been added. This means that all in the one effect you can build a quad split, then
 resize, position and mask it over a background layer. While very similar to the
 Lightworks transform, this section does not include cropping. It was felt that
 masking provided enough control of that type. Masking is tracked by the drop shadow,
 as cropping would be. It would be simplicity itself to add master cropping, but it
 was felt that the settings were complex enough without it.

 The individual quad split settings default to give a standard quad split when
 first applied.  They provide positioning, scaling and cropping.  The order of
 priority of the video layers in the quad is V1 is on top of everything else and
 defaults to the top left of screen.  Next is V2 at top right, then V3 at bottom
 left, and finally V4 at bottom right.  There is enough adjustment range to move
 any to whatever quadrant you need.  Edge softness can then be applied to the V
 images.

 Finally, the background can be zoomed.  Unfortunately it is not possible to match
 the on-screen zoom scaling and positioning of the Lightworks effect, so a switch
 has been provided to reduce the video levels outside the zoom and position bounds.
 In that mode the sense of the background position adjustments are correct, but
 when in working mode movement appears inverted.  That's because the grey boundary
 mask moves during setup to show the area that will occupy the screen.

 This mode also hides the quad split, and will affect the output of the effect.
 The same range of adjustment is available as the Lightworks zoom provides.  The
 Lightworks masking does not affect the zoomed background.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect QuadSplitTransform.fx
//
// Version history:
//
// Updated 2024-07-23 jwrl.
// Complete rewrite of the effect to add border softness and so that all scaling and
// positioning is calculated before importing the individual images.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Quad split with transform", "DVE", "Transform plus", "A quad split with master transform and background zoom", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (V1, Linear, Mirror);
DeclareInput (V2, Linear, Mirror);
DeclareInput (V3, Linear, Mirror);
DeclareInput (V4, Linear, Mirror);
DeclareInput (Bg, Linear);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Xpos, "Position", kNoGroup, "SpecifiesPointX|DisplayAsPercentage", 0.5, -1.0, 2.0);
DeclareFloatParam (Ypos, "Position", kNoGroup, "SpecifiesPointY|DisplayAsPercentage", 0.5, -1.0, 2.0);

DeclareFloatParam (MasterScale, "Master", "Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (XScale, "X Scale", "Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (YScale, "Y Scale", "Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);

DeclareFloatParam (ShadowOpacity, "Transparency", "Shadow", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (ShadeX, "X offset", "Shadow", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (ShadeY, "Y offset", "Shadow", kNoFlags, 0.0, -1.0, 1.0);

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (OpacityV1, "Opacity", "Video 1", kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Xpos1, "Position", "Video 1", "SpecifiesPointX", 0.25, 0.0, 1.0);
DeclareFloatParam (Ypos1, "Position", "Video 1", "SpecifiesPointY", 0.75, 0.0, 1.0);

DeclareFloatParam (FullScale1, "Master", "Video 1 > Scale", "DisplayAsPercentage", 0.5, 0.0, 10.0);
DeclareFloatParam (XScale1, "X scale", "Video 1 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (YScale1, "Y scale", "Video 1 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);

DeclareFloatParam (Tcrop1, "Top", "Video 1 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Lcrop1, "Left", "Video 1 > Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Rcrop1, "Right", "Video 1 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Bcrop1, "Bottom", "Video 1 > Crop", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (OpacityV2, "Opacity", "Video 2", kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Xpos2, "Position", "Video 2", "SpecifiesPointX", 0.75, 0.0, 1.0);
DeclareFloatParam (Ypos2, "Position", "Video 2", "SpecifiesPointY", 0.75, 0.0, 1.0);

DeclareFloatParam (FullScale2, "Master", "Video 2 > Scale", "DisplayAsPercentage", 0.5, 0.0, 10.0);
DeclareFloatParam (XScale2, "X scale", "Video 2 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (YScale2, "Y scale", "Video 2 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);

DeclareFloatParam (Tcrop2, "Top", "Video 2 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Lcrop2, "Left", "Video 2 > Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Rcrop2, "Right", "Video 2 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Bcrop2, "Bottom", "Video 2 > Crop", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (OpacityV3, "Opacity", "Video 3", kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Xpos3, "Position", "Video 3", "SpecifiesPointX", 0.25, 0.0, 1.0);
DeclareFloatParam (Ypos3, "Position", "Video 3", "SpecifiesPointY", 0.25, 0.0, 1.0);

DeclareFloatParam (FullScale3, "Master", "Video 3 > Scale", "DisplayAsPercentage", 0.5, 0.0, 10.0);
DeclareFloatParam (XScale3, "X scale", "Video 3 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (YScale3, "Y scale", "Video 3 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);

DeclareFloatParam (Tcrop3, "Top", "Video 3 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Lcrop3, "Left", "Video 3 > Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Rcrop3, "Right", "Video 3 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Bcrop3, "Bottom", "Video 3 > Crop", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (OpacityV4, "Opacity", "Video 4", kNoFlags, 1.0, 0.0, 1.0);

DeclareFloatParam (Xpos4, "Position", "Video 4", "SpecifiesPointX", 0.75, 0.0, 1.0);
DeclareFloatParam (Ypos4, "Position", "Video 4", "SpecifiesPointY", 0.25, 0.0, 1.0);

DeclareFloatParam (FullScale4, "Master", "Video 4 > Scale", "DisplayAsPercentage", 0.5, 0.0, 10.0);
DeclareFloatParam (XScale4, "X scale", "Video 4 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);
DeclareFloatParam (YScale4, "Y scale", "Video 4 > Scale", "DisplayAsPercentage", 1.0, 0.0, 10.0);

DeclareFloatParam (Tcrop4, "Top", "Video 4 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Lcrop4, "Left", "Video 4 > Crop", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (Rcrop4, "Right", "Video 4 > Crop", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Bcrop4, "Bottom", "Video 4 > Crop", kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (ShowBounds, "Show bounds", "Background", false);
DeclareFloatParam (BgZoom, "Zoom", "Background", kNoFlags, 1.0, 1.0, 10.0);
DeclareFloatParam (BgXpos, "Position", "Background", "SpecifiesPointX", 0.5, -5.0, 5.0);
DeclareFloatParam (BgYpos, "Position", "Background", "SpecifiesPointY", 0.5, -5.0, 5.0);

DeclareFloatParam (Soften, "Soften borders", kNoGroup, kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

float4 _TransparentBlack = 0.0.xxxx;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 posScale (float pX, float pY, float Sm, float Sx, float Sy, float2 sc, float2 xy)
{
   // This returns the master and individual scales as a composite value and calculates the
   // compound position of the video.  Position is returned in posScale.xy, individual scale
   // is in xy and full scale in posScale.zw.

   float2 xy1 = float2 (0.5 - pX, pY - 0.5);       // Individual position
   float2 xy2 = float2 (Sx, Sy) * Sm;              // Individual scale

   // Apply the individual X and Y scale factors

   xy2  = max (1.0e-6, xy2);
   xy1 /= xy2;
   xy1 += xy;
   xy2 *= sc;

   return float4 (xy1, xy2);
}

float4 getCrop (float Tcrop, float Lcrop, float Rcrop, float Bcrop)
{
   // This recovers the corrected and limited crop.  The order of the returned
   // values are wxyz = left, top, right, bottom.

   float l = saturate (Lcrop) - 0.5;               // Limit crop from -0.5 to 0.5
   float t = saturate (1.0 - Tcrop) - 0.5;         // Invert Y position direction
   float r = saturate (max (l, Rcrop)) - 0.5;
   float b = saturate (max (t, 1.0 - Bcrop)) - 0.5;

   // Correct for -0.5 offset and return

   return float4 (t, r, b, l) + 0.5.xxxx;
}

float4 ReadScaled (sampler Fg, float2 uv, float4 PosScale, float4 crop, out float amount)
{
   // We first map the foreground coordinates for each input to the sequence geometry,
   // adjusting the scaling, position and cropping if necessary.

   float4 retval;

   float2 soft  = float2 (1.0, _OutputAspectRatio) * Soften * 0.1;
   float2 minTL = crop.wx - soft;
   float2 maxTL = crop.wx + soft;
   float2 minBR = crop.yz - soft;
   float2 maxBR = crop.yz + soft;

   uv -= 0.5.xx;
   uv /= PosScale.zw;
   uv += PosScale.xy;
   uv += 0.5.xx;

   // Now we calculate the softness of the cropping

   if ((uv.x < minTL.x) || (uv.y < minTL.y) || (uv.x > maxBR.x) || (uv.y > maxBR.y)) {
      retval = _TransparentBlack;
      amount = 0.0;
   }
   else {
      retval = tex2D (Fg, uv);

      if ((uv.x < maxTL.x) || (uv.y < maxTL.y) || (uv.x > minBR.x) || (uv.y > minBR.y)) {
         float amtX_1 = smoothstep (minTL.x, maxTL.x, uv.x);
         float amtY_1 = smoothstep (minTL.y, maxTL.y, uv.y);
         float amtX_2 = smoothstep (maxBR.x, minBR.x, uv.x);
         float amtY_2 = smoothstep (maxBR.y, minBR.y, uv.y);

         amount = sqrt (min (min (amtX_1, amtY_1), min (amtX_2, amtY_2)));
      }
      else amount = 1.0;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Bgd)
{
   // First map the background coordinates to the sequence geometry and apply the zoom.

   float4 retval;

   float2 xy;

   if (ShowBounds) {
      xy = ((uv5 - 0.5.xx) * max (BgZoom, 1.0)) + float2 (1.0 - BgXpos, BgYpos);
      retval = ReadPixel (Bg, uv5);

      if (IsOutOfBounds (xy)) {
         retval.rgb *= 0.666667;
         retval.rgb += 0.166667.xxx;
      }
   }
   else {
      xy = ((uv5 - float2 (1.0 - BgXpos, BgYpos)) / max (BgZoom, 1.0)) + 0.5.xx;
      retval = ReadPixel (Bg, xy);
   }

   return retval;
}

DeclarePass (Fgd)
{
   // We now produce the foreground coordinates for each input and scale, crop and
   // position the xy coordinates to recover the composite of the four foregrounds.

   float2 xy    = float2 (0.5 - Xpos, Ypos - 0.5);          // Master position
   float2 scale = MasterScale * float2 (XScale, YScale);    // Master scale

   // Limit scale to prevent divide by zero errors when applying it.

   scale = max (1.0e-6, scale);

   float amt_1, amt_2, amt_3, amt_4;

   float4 pScale = posScale (Xpos1, Ypos1, FullScale1, XScale1, YScale1, scale, xy);
   float4 cropXY = getCrop (Tcrop1, Lcrop1, Rcrop1, Bcrop1);
   float4 Fgnd_1 = ReadScaled (V1, uv1, pScale, cropXY, amt_1);

   pScale = posScale (Xpos2, Ypos2, FullScale2, XScale2, YScale2, scale, xy);
   cropXY = getCrop (Tcrop2, Lcrop2, Rcrop2, Bcrop2);

   float4 Fgnd_2 = ReadScaled (V2, uv2, pScale, cropXY, amt_2);

   pScale = posScale (Xpos3, Ypos3, FullScale3, XScale3, YScale3, scale, xy);
   cropXY = getCrop (Tcrop3, Lcrop3, Rcrop3, Bcrop3);

   float4 Fgnd_3 = ReadScaled (V3, uv3, pScale, cropXY, amt_3);

   pScale = posScale (Xpos4, Ypos4, FullScale4, XScale4, YScale4, scale, xy);
   cropXY = getCrop (Tcrop4, Lcrop4, Rcrop4, Bcrop4);

   float4 Fgnd_4 = ReadScaled (V4, uv4, pScale, cropXY, amt_4);

   amt_1 *= OpacityV1;
   amt_2 *= OpacityV2;
   amt_3 *= OpacityV3;
   amt_4 *= OpacityV4;

   // Now combine the four video overlays.  V1 has highest priority and V4, lowest.

   float4 retval = lerp (_TransparentBlack, Fgnd_4, amt_4);

   retval = lerp (retval, Fgnd_3, amt_3);
   retval = lerp (retval, Fgnd_2, amt_2);

   return lerp (retval, Fgnd_1, amt_1);
}

DeclareEntryPoint (QuadSplitTransform)
{
   // Because we have mapped the foreground onto the sequence coordinates we no
   // longer need to correct for resolution and aspect ratio differences.  We
   // first recover the raw scale factors.

   float2 xyScale = float2 (XScale, YScale) * MasterScale;

   // Now we create the drop shadow offset and put that in xy1, correcting it
   // for the output aspect ratio.  The drop shadow coordinates are then found
   // using the xy1 offset and put in xy2.  Finally xy1 is scaled and used to
   // make the drop shadow mask offset in xy3.

   float2 xy1 = float2 (ShadeX / _OutputAspectRatio, -ShadeY);
   float2 xy2 = uv6 - xy1;
   float2 xy3 = uv6 - float2 (xy1.x * xyScale.x, xy1.y * xyScale.y);

   // Recover the background and foreground and calculate the drop shadow
   // amount.  Apply the mask and opacity to the foreground.

   float4 Fgnd = ReadPixel (Fgd, uv6);
   float4 Bgnd = ReadPixel (Bgd, uv6);

   float amount = ShowBounds ? 0.0 : Opacity;
   float shadow = ShadowOpacity * amount;

   amount *= tex2D (Mask, uv6).x * Fgnd.a;

   // Recover the drop shadow and mask it using the mask offset so that the
   // drop shadow will appear to be caused by the masked foreground.

   shadow *= ReadPixel (Fgd, xy2).a;
   shadow *= ReadPixel (Mask, xy3).x;

   float4 retval = lerp (Bgnd, _TransparentBlack, shadow);

   retval   = lerp (retval, Fgnd, amount);
   retval.a = max (amount, max (Bgnd.a, shadow));

   return retval;
}
