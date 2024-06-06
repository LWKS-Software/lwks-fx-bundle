// @Maintainer jwrl
// @Released 2024-06-07
// @Author schrauber
// @Created 2024-06-07

/**
 This blur effect earns the name "Full Blur".  When the blur ammount is set to
 100% the entire frame is effectively averaged so that there is little visible
 difference between pixels.  It could be reagarded as having an infinite range.
 However to give the range of control that's required with such a wide range a
 very non-linear profile is used in the Amount adjustment.  That profile is easy
 to get used to - when I tested it I very quickly became completely unaware of
 any non-linearity.  It feels very similar to the Lightworks blur effect.

 Another thing that it provides is control over the way that image transparency
 is handled.  There are five transparency modes.  The default is to simply treat
 transparency as just another part of the video.  Called "Simple transparency",
 in that mode when blending the result with other video, softened transparency
 areas can appear darker than expected.  This happens because when blurred the
 non-tranparent video is combined with the black of the transparent areas.  This
 can be particularly noticeable when using input video with a different aspect
 ratio to the output video.

 To address this, "Processed transparency" has been provided.  It's slightly more
 complex in the way that it works, but is actually very like the way that the current
 Lightworks blur effect handles transparency.  The frame is blurred as with "Simple
 transparency", but the blur partially compensates for the darkening present with
 that setting.  As a result this mode can give a cleaner result with smoother spread
 when used with downstream blend or transform effects.

 The last three transparency mode settings are each different ways of dealing with
 input video that has a different aspect ratio to the output.  "Transparency pass
 through" processes the image in the same way as the default, but anywhere that the
 input is transparent before blurring the output will be too.  This results in hard
 edges wherever there is transparency.  Apart from that, the result can be blended
 using downstream effects in the same way as the two earlier modes can.

 "Blank, make opaque" blurs the input video, but anywhere that it is transparent will
 be blanked (output as black).  The entire output is then made opaque.

 What "Remove transparency" does should be obvious from the name.  The whole input
 frame will be blurred then made opaque, whether transparent or not.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Full_Bur.fx
//
// Version history:
//
// Built 2024-06-07 by schrauber.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Full Blur", "Stylize", "Blurs and sharpens", "Blur until all pixels are almost identical.", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs & Samplers
//-----------------------------------------------------------------------------------------//

DeclareInput (Input, Linear, Mirror);  // This mirror sampler setting only works in the first pass. For subsequent passes, a simple mirror code is used within the blur function.

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Size, "Amount", kNoGroup, kNoFlags, 0.2, 0.0, 1.0);
DeclareIntParam (Mode, "Transparency mode", kNoGroup, 0, "Simple transparency|Processed transparency|Transparency passthrough|Blank, make opaque|Remove transparency");

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// General Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI       3.14159
#define PI_HALF  1.5708
#define PI_TWO   6.28319

// ------ 5 x 6 Blur with Pre-Dithering --------

// Definitions specific to the 5 x 6 blur passes:
// Angle offset per pass in case of 5 passes & 6 samples in the blur circle (60° rotation per sample within each pass):
// 60° / 5 = 12° steps per pass + 9.3° (Offset determined experimentally) 

#define ANGLE_60           1.0472  // 60 degrees in radians 
#define ANGLE_OFFSET_A1    0.1647  // about 9.4 degrees in radians  
#define ANGLE_OFFSET_A2    0.3742  // about 21.4 
#define ANGLE_OFFSET_A3    0.5836  // about 33.4
#define ANGLE_OFFSET_A4    0.7930  // about 45.4
#define ANGLE_OFFSET_A5    1.0025  // about 57.4
//
// Blur-Radius-Faktor per pass in case of 5 passes & 6 samples in the blur circle (determined experimentally).
#define RADIUS_FACTOR_A1   0.25
#define RADIUS_FACTOR_A2   0.373
#define RADIUS_FACTOR_A3   0.536
#define RADIUS_FACTOR_A4   0.678
#define RADIUS_FACTOR_A5   0.95 // The value must remain below 1 so that the limits of the edge reflection are not exceeded.

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float fn_sizeBlur(float faktorPass)
{
   float size = Size * Size * Size * Size * Size * Size;  // Nonlinear adjustment curve
   size = lerp( Size, size, 0.9);    // Mixing of 10% linear and 90% nonlinear adjustment curve.
   return size *= faktorPass;
}

float2 fn_aspectRatio()
// Creates a two-component aspect ratio that guarantees that no component is larger than 1.
// For example, when this float2 aspect ratio is used as a blur radius multiplier, 
// aspect ratio changes do not increase the blur radius,
// keeping even extreme aspect ratios within potential limits of edge reflections.
{
   float2 aspectR;
   if (_OutputAspectRatio < 1.0) {
      aspectR.x = 1.0; 
      aspectR.y = _OutputAspectRatio;
   }else{
      aspectR.x = 1.0 / _OutputAspectRatio;
      aspectR.y = 1.0;
   }
   return aspectR;
}

float2 fn_noise (float2 progress, float2 xy)     // float2 texture noise (two different values per pixel and frame)
{
   float2 noise1 = frac (sin (1.0 + progress + (xy.x * 82.3)) * (xy.x + 854.5421));
   return frac (sin ((1.0 + noise1 + xy.y) * 92.7) * (noise1 + xy.y + 928.4837));
}

float2 fn_ditherCoord (float2 uv, float radius, float randomAngle, float randomRadius )
{
   // Random angles from 0 to 360° (circle) & radii with adjustable random range.
   // The generated dither coordinates require a sampler that supports multiple edge reflections.                    

   float2 coord;    

   float halfAspectRatio = ((_OutputAspectRatio - 1.0) / 2.0) +1.0;
   float2 radius2 = float2 (1.0 / halfAspectRatio, halfAspectRatio) * 5.0.xx * radius.xx; 
   radius2 = min( radius2, 1.225.xx); // Limits the radius, as values â€‹â€‹above this can lead to a deterioration in the blur quality of the effect.

   sincos (randomAngle * PI_TWO, coord.y, coord.x);

   radius2 *= pow(randomRadius, 1.5 - radius).xx;  // Dithering characteristic . (Quantity distribution of pixel shifts in the dither radius.)
                                                  // `1.5 - radius` changes the characteristics depending on the desired blur strength of the effect.
   return uv + (coord * radius2);
}

float4 fn_bigBlur_6 (float2 uv, sampler2D blurSampler, float rotationStep, float offset, float2 radius)
// 6+1 samples (6 on the blur circle + 1 sampler at original position)
{
   float2 coord, angle;
   float4 retval, sample;

   retval = tex2D (blurSampler, uv);
   angle = float2 (offset + PI_HALF, offset);

   for (int tap = 0; tap < 6; tap++) {
      coord = uv + ( sin (angle) * radius );
      coord = (1.0.xx - abs (1.0.xx - abs (coord)));    // Fast, one-time edge reflection.
      retval += tex2D( blurSampler, coord );
      angle += rotationStep.xx;
   }

   return retval / 7.0.xxxx;                                    
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// The shader passes call the Blur function with parameters in this order:
// - uv1 (texture coordinates),
// - sampler source texture,
// - Sampler rotation steps (angles in radians) within the loop of the respective pass.
// - Offset of sampler angles (radians).
// - Blur radius scaling base factor.

DeclarePass (T2_0)
{   
   float2 noiseBase = float2 (0.5, 0.8);             // Base values for semi-random calculation
   float2 noise = fn_noise (noiseBase, uv1);         // float2 texture noise

   float size = Size * Size * Size * Size * Size * Size;

   float2 ditherCoord = fn_ditherCoord (uv1, size, noise.x, noise.y);

   float4 fg = tex2D (Input, uv1);
   float4 dither = tex2D (Input, ditherCoord);

   if (Mode > 0 && Mode != 4)  {                   // Transparency Modes
      fg.rgb *= max( fg.aaa, 0.02.xxx);            // Darkening of partial transparency is lightened in the last pass.
      dither.rgb *= max( dither.aaa, 0.02.xxx);    // The value 0.02 must be identical to the value in the last pass.
   }

   if (Mode == 4) {    // Transparency Modes
      fg.a = 1.0;
      dither.a = 1.0;
   }

   return lerp( fg, dither, Size);   // Ensures that graininess is only added to subsequent blur passes when the blur strength is sufficient.
}

DeclarePass (T2_1)
{
   float2 radius = fn_sizeBlur(RADIUS_FACTOR_A1).xx * fn_aspectRatio();

   return fn_bigBlur_6 ( uv1, T2_0, ANGLE_60, ANGLE_OFFSET_A1, radius);
}

DeclarePass (T2_2)
{
   float2 radius = fn_sizeBlur(RADIUS_FACTOR_A2).xx * fn_aspectRatio();

   return fn_bigBlur_6 ( uv1, T2_1, ANGLE_60, ANGLE_OFFSET_A2, radius);
}

DeclarePass (T2_3)
{
   float2 radius = fn_sizeBlur(RADIUS_FACTOR_A3).xx * fn_aspectRatio();

   return fn_bigBlur_6 ( uv1, T2_2, ANGLE_60, ANGLE_OFFSET_A3, radius);
}

DeclarePass (T2_4)
{
   float2 radius = fn_sizeBlur(RADIUS_FACTOR_A4).xx * fn_aspectRatio();

   return fn_bigBlur_6 ( uv1, T2_3, ANGLE_60, ANGLE_OFFSET_A4, radius);
}

DeclareEntryPoint (samples5x6_Dither)
{
   float4 fg = ReadPixel( Input, uv1 );

   float2 radius = fn_sizeBlur(RADIUS_FACTOR_A5).xx * fn_aspectRatio();
   float4 blur = fn_bigBlur_6 ( uv1, T2_4, ANGLE_60, ANGLE_OFFSET_A5, radius);

   // Transparency Modes:

   if (Mode > 0 && Mode != 4 ) blur.rgb /= max (blur.aaa, 0.02.xxx);  // Compensates for brightness loss caused by mixing with transparent black.
                                                       // Note that in the first pass (in this mode) Alpha 0 in the input texture also changes the RGB value to black.
                                                      // The value 0.02 reduces artifacts caused by excessive compensation and prevents division by 0.

   if (Mode > 1 && Mode != 4) {          // No blurring of alpha 0 areas
      if (fg.a == 0.0) blur = fg;
      if (fg.a == 1.0) blur.a /= max (blur.a, 0.02);
      if (fg.a < 1.0) blur.a = fg.a;
   }

   if (Mode == 1 && blur.a == 0.0) blur = fg;

   float4 retval = lerp( fg, blur, tex2D( Mask, uv1 ) );   // Mask

   if (Mode > 2) retval.a = 1.0;                           // Transparency Modes

   return retval;
}

