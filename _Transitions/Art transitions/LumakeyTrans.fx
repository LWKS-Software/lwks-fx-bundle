// @Maintainer jwrl
// @Released 2025-09-14
// @Author jwrl
// @Created 2025-09-14

/**
 This effect is a combination transition, using either dissolves or wipes to pass
 from the outgoing video to the incoming.  The dissolve can range from the full
 transition duration to a small 2% section in the centre of the effect.  Over the
 dissolve are the same borders used by the wipe mode.

 That same dissolve can be used as the input to the lumakey as can the outgoing or
 the incoming video.  The lumakey produces a two-colour border pattern using a key
 clip that ramps from absolute black to peak white during the progress of the
 transition.  The colour border thickness is dynamically generated, and varies over
 the effect duration reaches its maximum at the midpoint of the transition.

   [*] Progress:  The progress of the transition.
   [*] Blending
      [*] Choose mode:  Switch between dissolve (default) and wipe mode.
      [*] Choose source:  Select between the outgoing video, the incoming or a mix
          of both inputs as the source of the blend key.
      [*] Mix range:  Varies the range over which the underlying mix takes place.
      [*] Key soften:  Varies the softness of the lumakey input.
      [*] Invert key:  Reverses the key clip transition from white to black areas
          of the frame rather than black to white.
   [*] Borders
      [*] Colour spread:  Adjusts the spread of the colour pattern over the video.
      [*] Colour 1:  Outer colour border.
      [*] Colour 2:  Inner colour border.
   [*] Luminance
      [*] Show luminance:  Aids setup by displaying the luminance used by the key.
      [*] Black level:  Adjusts black level.
      [*] White level:  Adjusts white level.
      [*] Mid ranges:  Expands or compresses the mid levels.

 The wipe mode is similar to, but not the same as the Lightworks Luma Wipe effect.
 As described above, the most obvious difference is that the border generation can
 use an outgoing/incoming mix for the lumakey input which the Lightworks effect
 cannot.  Wipe mode also uses an entirely different border generation technique to
 the Lightworks version, resulting in constant border size rather than dynamic.

 Another difference is the ability to adjust the luminance levels, which the LW
 effect cannot do.  Being able to do this provides control over the linearity of
 the transition.  Nor is it possible to soften the luminance prior to the key
 being generated.  While this does not contribute much to the softness of the key
 it has a profound effect on the smoothness of the borders generated.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect LumakeyTrans.fx
//
// The blur component is based on the blur from my effect Ghostly blur (GhostlyBlur.fx),
// slightly reworked to reduce the number of passes.
//
// Version history:
//
// Created 2025-09-14 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Lumakey transition", "Mix", "Art transitions", "Overlays a luminance key generated border over a variable length mix.", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg);
DeclareInput (Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Progress, "Progress", kNoGroup,   kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam   (TransMode, "Choose mode",    "Blending",  0, "Dissolve|Wipe");
DeclareIntParam   (Source,    "Choose source",  "Blending",  2, "Outgoing|Incoming|Mix both inputs");
DeclareFloatParam (MixRange,  "Mix range",      "Blending",  kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (Softness,  "Key softness",   "Blending",  kNoFlags, 0.5, 0.0, 1.0);
DeclareBoolParam  (Invert,    "Invert key",     "Blending",  false);

DeclareFloatParam  (Spread,   "Colour spread",  "Borders",   kNoFlags, 0.0, 0.0, 1.0);
DeclareColourParam (Colour_1, "Colour 1",       "Borders",   kNoFlags, 0.4, 0.8, 0.96);
DeclareColourParam (Colour_2, "Colour 2",       "Borders",   kNoFlags, 0.4, 0.3, 0.92);

DeclareBoolParam  (Setup,     "Show luminance", "Luminance", false);
DeclareFloatParam (Blacks,    "Black level",    "Luminance", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Whites,    "White level",    "Luminance", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Mids,      "Mid ranges",     "Luminance", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);
DeclareFloatParam (_LengthFrames);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define SOFTEN    2.0e-3
#define MIN_LIMIT 1.0e-4
#define MAX_LIMIT (1.0 - MIN_LIMIT)

#define HALF_PI   1.57079633     // 90 degrees in radians
#define OFFSET    0.41887902.xx  // 24 degree offset for blur effect

#define BLUR_1    0.13962634     // 8 degrees
#define BLUR_2    0.27925268     // 16 degrees

#define LUMA_VAL  float4(0.33, 0.34, 0.33, 0.0)    // Doing this means we can convert rgba.

#define minProg   0.5/_LengthFrames

#define _TransparentBlack 0.0.xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// Allows mirroring to be used despite the fact that cross-platform mirror addressing
// isn't supported when used with multipass operations

float4 mirror2D (sampler M, float2 xy)
{
   float2 uv = 1.0.xx - abs (abs (xy) - 1.0.xx);

   return tex2D (M, uv);
}

// A radial blur with 24 degree sampling, based on ghostly blur (GhostlyBlur.fx).

float4 rBlur (sampler S, float2 uv, float startAngle)
{
   float2 amount = float2 (1.0, _OutputAspectRatio) * Softness * Softness * 0.01;
   float2 xy, angle = float2 (HALF_PI, 0.0) + startAngle.xx;

   float4 retval = mirror2D (S, uv);

   for (int i = 0; i < 15; i++) {
      xy = uv + (sin (angle) * amount);
      retval += mirror2D (S, xy);
      angle  += OFFSET;
   }

   return retval / 16;
}

// Performs a linear interpolation from 0.0 to 1.0 when c is between a and b.

float linearstep (float a, float b, float c)
{ return saturate ((c - a) / (b - a)); }

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Trans)
{
   float4 Fgd = ReadPixel (Fg, uv1);
   float4 Bgd = ReadPixel (Bg, uv2);

   // The dissolve between foreground and background can range from the full transition
   // duration to a roughly 2% central section of the duration.

   float dslv_min = lerp (0.495, 0.0, saturate (MixRange));
   float dslv_max = lerp (0.505, 1.0, saturate (MixRange));
   float dissolve = linearstep (dslv_min, dslv_max, saturate (Progress));

   // Return the dissolve between outgoing and incoming video for use by the video
   // output and as the blended source for the coloured borders.

   return lerp (Fgd, Bgd, dissolve);
}

DeclarePass (keySrc)
{
   float4 Fgnd   = ReadPixel (Fg, uv1);
   float4 Bgnd   = ReadPixel (Bg, uv2);
   float4 FBmix  = tex2D (Trans, uv3);
   float4 keyval = Source == 0 ? Fgnd : Source == 1 ? Bgnd : FBmix;

   // First sum the rgb channels and normalise them to produce the luminance input for
   // the key.

   float luma = dot (keyval, LUMA_VAL);

   // Now adjust the white and black levels.

   luma += Blacks - 0.5;
   luma  = (saturate (luma * Whites * 2.0) * 2.0) - 1.0;

   // This next expands or compresses the mid range luminance values.

   float luma_0 = saturate (-luma);          // Inverted lower half of luma
   float luma_1 = saturate (luma);           // Upper half of luminance
   float curve  = Mids < 0.5 ? Mids + 0.5 : Mids * 2.0;  // Curve runs from 0.5 to 2.0.

   curve  = pow (curve, 1.585);              // Curve now ranges from 0.3333 to 3.0.
   luma_0 = 0.5 - pow (luma_0, curve) / 2.0; // Corrected lower half of the luma.
   luma_1 = pow (luma_1, curve) / 2.0;       // Corrected upper half.

   // Adding both halves gives the final adjusted luminance

   return float4 ((luma_0 + luma_1).xxx, keyval.a);
}

DeclarePass (Blur1)
{ return Setup ? _TransparentBlack : rBlur (keySrc, uv3, 0.0); }

DeclarePass (Blur2)
{ return Setup ? _TransparentBlack : rBlur (Blur1, uv3, BLUR_1); }

DeclareEntryPoint (LumakeyTrans)
{
   if (Setup) return tex2D (keySrc, uv3);             // Just show the luminance

   float4 keyval = rBlur (Blur2, uv3, BLUR_2);        // This is the blurred luma

   float luma  = Invert ? 1.0 - keyval.x : keyval.x;  // Recover the key input
   float curve = lerp (1.1, 2.0, saturate (Spread));  // Set the curve power

   // These operations ensure that neither amount setting is ever zero, and that
   // they have opposite curvatures as they transition.  This ensures that there
   // will always be a gap between them.

   float progress = lerp (minProg, 1.0, Progress);    // Progress is never zero
   float Amount_0 = pow (progress, curve) * MAX_LIMIT;   // Set the lower and
   float Amount_1 = pow (progress, 1.0 / curve);      // upper clip levels.

   Amount_1 *= MAX_LIMIT;
   Amount_1 += MIN_LIMIT;

   // There is always a gap between Amount_1 and Amount_2, so linearstep() will
   // always return a discreet value.

   float Amount = (1.0 - linearstep (Amount_0, Amount_1, luma)) * 3.0;

   // We need Amount_0 to run from 0 to 1 over the first third of the transition,
   // Amount to do that over the next third and Amount_1 to end the last third.

   Amount_0 = saturate (Amount);                      // Dissolve into colours
   Amount_1 = saturate (Amount - 2.0);                // Dissolve out of colours
   Amount   = saturate (Amount - 1.0);                // Dissolve between colours

   float4 colour1 = float4 (Colour_1.rgb, 1.0);       // Colours must be opaque
   float4 colour2 = float4 (Colour_2.rgb, 1.0);       // regardless of alpha.
   float4 inval, outval;

   // Set wipe when TransMode = 1 or default to dissolve mode.

   if (TransMode == 1) {
      outval = ReadPixel (Fg, uv1);
      inval  = ReadPixel (Bg, uv2);
   }
   else {
      outval = tex2D (Trans, uv3);                    // The underlying dissolve effect
      inval  = outval;
   }

   float4 colval = lerp (colour1, colour2, Amount);   // Dissolve between colours
   float4 mixval = lerp (outval, colval, Amount_0);   // Dissolve into first colour

   return lerp (mixval, inval, Amount_1);             // Dissolve out of the colours
}

