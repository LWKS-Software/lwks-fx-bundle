// @Maintainer jwrl
// @Released 2024-02-02
// @Author jwrl
// @Created 2024-01-28

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
 any to whatever quadrant you need.

 NOTE:  This effect is only suitable for use with Lightworks version 2023 and higher.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect QuadSplitTransform.fx
//
// Version history:
//
// Updated 2024-01-29 jwrl.
// Added individual opacity settings to V1 - V4.
// Added mask tracking to the drop shadow.
//
// Updated 2024-02-02 jwrl.
// Removed pointless aspect ratio scaling adjustments and simplified the maths.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Quad split with transform", "DVE", "Transform plus", "A quad split with master transform", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (V1, V2, V3, V4, Bg);

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

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Fg1)
// We first map the foreground coordinates for each input to the sequence geometry and
// apply the crop if necessary.
{
   float4 retval = ReadPixel (V1, uv1);

   if ((uv1.y > 1.0 - Bcrop1) || (uv1.x < Lcrop1) || (uv1.x > Rcrop1) || (uv1.y < 1.0 - Tcrop1))
      retval = kTransparentBlack;

   retval.a *= OpacityV1;

   return retval;
}

DeclarePass (Fg2)
{
   float4 retval = ReadPixel (V2, uv2);

   if ((uv2.y > 1.0 - Bcrop2) || (uv2.x < Lcrop2) || (uv2.x > Rcrop2) || (uv2.y < 1.0 - Tcrop2))
      retval = kTransparentBlack;

   retval.a *= OpacityV2;

   return retval;
}

DeclarePass (Fg3)
{
   float4 retval = ReadPixel (V3, uv3);

   if ((uv3.y > 1.0 - Bcrop3) || (uv3.x < Lcrop3) || (uv3.x > Rcrop3) || (uv3.y < 1.0 - Tcrop3))
      retval = kTransparentBlack;

   retval.a *= OpacityV3;

   return retval;
}

DeclarePass (Fg4)
{
   float4 retval = ReadPixel (V4, uv4);

   if ((uv4.y > 1.0 - Bcrop4) || (uv4.x < Lcrop4) || (uv4.x > Rcrop4) || (uv4.y < 1.0 - Tcrop4))
      retval = kTransparentBlack;

   retval.a *= OpacityV4;

   return retval;
}

DeclarePass (Bgd)
// We now map the background coordinates to the sequence geometry.
{ return ReadPixel (Bg, uv5); }

DeclarePass (Fgd)
// We now perform the quad split ahead of anything else.  This gives us a composite source
// for the master transform.
{
   // First set up the coordiantes around zero the adjust the position.

   float2 xy1 = uv6 - float2 (Xpos1, 1.0 - Ypos1);
   float2 xy2 = uv6 - float2 (Xpos2, 1.0 - Ypos2);
   float2 xy3 = uv6 - float2 (Xpos3, 1.0 - Ypos3);
   float2 xy4 = uv6 - float2 (Xpos4, 1.0 - Ypos4);

   // Now we apply the scale factors -

   xy1 /= max (1.0e-6, FullScale1 * float2 (XScale1, YScale1));
   xy2 /= max (1.0e-6, FullScale2 * float2 (XScale2, YScale2));
   xy3 /= max (1.0e-6, FullScale3 * float2 (XScale3, YScale3));
   xy4 /= max (1.0e-6, FullScale4 * float2 (XScale4, YScale4));

   // and put the coordinates back where they belong.

   xy1 += 0.5.xx;
   xy2 += 0.5.xx;
   xy3 += 0.5.xx;
   xy4 += 0.5.xx;

   float4 retval = ReadPixel (Fg4, xy4);
   float4 topvid = ReadPixel (Fg3, xy3);

   retval = lerp (retval, topvid, topvid.a);
   topvid = ReadPixel (Fg2, xy2);
   retval = lerp (retval, topvid, topvid.a);
   topvid = ReadPixel (Fg1, xy1);

   return lerp (retval, topvid, topvid.a);
}

DeclareEntryPoint (QuadSplitTransform)
// Because we have mapped the foreground onto the sequence coordinates we no
// longer need to correct for resolution and aspect ratio differences.
{
   // First we recover the raw scale factors.

   float2 xyScale = max (1.0e-6.xx, MasterScale * float2 (XScale, YScale));

   // Now we create the drop shadow offset and put that in xy0.  It's the one
   // parameter that must be corrected for the output aspect ratio.  Then we
   // adjust the foreground position, scale it and from that calculate the
   // drop shadow coordinates using the xy0 offset and put that in xy2.
   // Finally xy0 is corrected for scaling then used to make the drop shadow
   // mask offset in xy3.

   float2 xy0 = float2 (ShadeX / _OutputAspectRatio, -ShadeY);
   float2 xy1 = ((uv6 - float2 (Xpos, 1.0 - Ypos)) / xyScale) + 0.5.xx;
   float2 xy2 = xy1 - xy0;
   float2 xy3 = uv6 - (xy0 * xyScale);

   // Recover the background and foreground and calculate the drop shadow
   // amount.  Apply the mask and opacity to the foreground.

   float4 Fgnd = ReadPixel (Fgd, xy1);
   float4 Bgnd = ReadPixel (Bgd, uv6);

   float amount = tex2D (Mask, uv6).x * Fgnd.a * Opacity;
   float shadow = ShadowOpacity * Opacity;

   // Recover the drop shadow and mask it using the mask offset so that the
   // drop shadow will appear to be caused by the masked foreground.

   shadow *= ReadPixel (Fgd, xy2).a;
   shadow *= ReadPixel (Mask, xy3).x;

   float4 retval = lerp (Bgnd, kTransparentBlack, shadow);

   retval   = lerp (retval, Fgnd, amount);
   retval.a = max (amount, max (Bgnd.a, shadow));

   return retval;
}
