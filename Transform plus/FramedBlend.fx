// @Maintainer jwrl
// @Released 2025-02-03
// @Author jwrl
// @Created 2025-02-03

/**
 Framed blend is very similar to the Lightworks framing effect in operation.
 However unlike framing, this effect is designed with blending in mind.  The
 blend mode provided is the standard normal blend. Cropping has been enxpanded
 and can also be performed using masking.  This allows the exact shape needed
 for the blend to be built.

 The settings are:

   [*] Position X:  Adjusts the horizontal position of the foreground.
   [*] Position Y:  Adjusts the vertical position of the foreground.
   [*] Size:  Scales the foreground.  The range is the same as in framing.
   [*] Cropping
      [*] Upper crop X:  Crop the left side of the foreground.
      [*] Upper crop Y:  Crop the top of the foreground.
      [*] Lower crop X:  Crop the right side of the foreground.
      [*] Lower crop Y:  Crop the bottom of the foreground.
   [*] Softness
      [*] Master soften:  Soften all sides of the crop equally.
      [*] Upper left X:  Soften the left side of the crop.
      [*] Upper left Y:  Soften the top edge of the crop.
      [*] Lower right X:  Soften the right side of the crop.
      [*] Lower right Y:  Soften the bottom of the crop.
   [*] Tilt:  Rotates the foreground.  The range matches the framing effect.

 Master soften will soften all crop edges, but master and individual softness
 settings are not additive.  The highest master and individual value set is
 the value that will be used for a given crop.  For example if the master
 value is 25%, the left is 50% and the right 10%, left softness will override
 the master and have 50% softnes.  The right softness will be 25%, having been
 overridden by the master softness.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect FramedBlend.fx
//
// Version history:
//
// Built 2025-02-03 by jwrl.
//-----------------------------------------------------------------------------------------//

#include "_utils.fx"

DeclareLightworksEffect ("Framed blend", "DVE", "Transform plus", "Blending with framing adjustment and masking.", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

DeclareMask;

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

DeclareFloatParam (Xpos, "Position", kNoGroup, "SpecifiesPointX",     0.5, -0.5,  1.5);
DeclareFloatParam (Ypos, "Position", kNoGroup, "SpecifiesPointY",     0.5, -0.5,  1.5);
DeclareFloatParam (Size, "Size",     kNoGroup, "DisplayAsPercentage", 1.0,  0.25, 3.5);

DeclareFloatParam (XcropTL, "Upper crop", "Cropping", "SpecifiesPointX", 0.0, 0.0, 1.0);
DeclareFloatParam (YcropTL, "Upper crop", "Cropping", "SpecifiesPointY", 1.0, 0.0, 1.0);
DeclareFloatParam (XcropBR, "Lower crop", "Cropping", "SpecifiesPointX", 1.0, 0.0, 1.0);
DeclareFloatParam (YcropBR, "Lower crop", "Cropping", "SpecifiesPointY", 0.0, 0.0, 1.0);

DeclareFloatParam (Master , "Master soften", "Softness", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (XsoftTL, "Upper left X",  "Softness", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (YsoftTL, "Upper left Y",  "Softness", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (XsoftBR, "Lower right X", "Softness", kNoFlags, 0.0, 0.0, 1.0);
DeclareFloatParam (YsoftBR, "Lower right Y", "Softness", kNoFlags, 0.0, 0.0, 1.0);

DeclareFloatParam (Tilt, "Tilt", kNoGroup, "SpecifiesAngle",  0.0, -10.0, 10.0);

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

// Map the foreground, background and masking to the sequence geometry.  This ensures
// that we needn't correct for resolution and aspect ratio differences in the transform.

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Msk)
{ return ReadPixel (Mask, uv3); }

DeclarePass (Ovl)
{ 
   // Adjust the foreground position and centre it around the screen midpoint.

   float2 xy1 = uv4 - float2 (Xpos, 1.0 - Ypos);

   // We now perform the scaling of the foreground coordinates, allowing for the
   // aspect ratio.  Scaling is range limited to prevent divide by zero problems.
   // This protects against illegal manual size factor entries.

   xy1   /= max (0.0001, Size);
   xy1.x *= _OutputAspectRatio;

   // The tilt is now applied using standard matrix multiplication.

   float c, s;

   sincos (radians (Tilt), s, c);

   xy1 = mul (float2x2 (c, s, -s, c), xy1);

   // Aspect ratio adjustment and centering is now removed.

   xy1.x /= _OutputAspectRatio;
   xy1   += 0.5.xx;

   // Return the rotated, scaled and positioned foreground.

   return ReadPixel (Fgd, xy1);
}

DeclareEntryPoint (FramedOverlay)
{ 
   // Scale the softness parameters, correcting for aspect ratio.

   float aspect = 0.1 * _OutputAspectRatio;
   float softL  = max (Master, XsoftTL) * 0.1;
   float softT  = max (Master, YsoftTL) * aspect;
   float softR  = max (Master, XsoftBR) * 0.1;
   float softB  = max (Master, YsoftBR) * aspect;

   // Calculate the horizontal left and right crop values including softness range.

   float minL = XcropTL - softL;
   float maxL = XcropTL + softL;
   float minR = XcropBR - softR;
   float maxR = XcropBR + softR;

   // Calculate the vertical top and bottom crop values including the softness.

   float maxT = 1.0 - YcropTL;
   float maxB = 1.0 - YcropBR;
   float minT = maxT - softT; maxT += softT;
   float minB = maxB - softB; maxB += softB;

   // Now produce the crop mask, first horizontally then vertically.

   float crop = smoothstep (minL, maxL, uv4.x) * (1.0 - smoothstep (minR, maxR, uv4.x));

   crop *= smoothstep (minT, maxT, uv4.y);
   crop *= 1.0 - smoothstep (minB, maxB, uv4.y);

   float4 Fgnd = tex2D (Ovl, uv4);
   float4 Bgnd = tex2D (Bgd, uv4);

   Fgnd.a *= crop;

   float4 retval = lerp (Bgnd, Fgnd, Fgnd.a);

   return lerp (Bgnd, retval, tex2D (Msk, uv4).x);
}

