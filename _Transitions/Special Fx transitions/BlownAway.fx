// @Maintainer jwrl
// @Released 2024-09-05
// @Author schrauber
// @Author jwrl
// @Created 2024-08-30

/**
 This effect is a variation of "Gone with the wind" that has been optimised for use
 as a transition.  It drifts the image off as if it was made up of dust particles
 being blown away.  It's a very nice effect.  The parameters are:

   Amount:  What it says.  Ramps the effect off over the transition duration.
   Grain size:  Adjusts the size of the grain sampling.
   Decay Rate:  At 100%, the largest amount is blown away at the beginning.
   Revolutions:  Wind direction (has an adjustment range of 3 rotations).
   Spread angle:  This parameter could also be called range.  See below.
   Blend mode:  Mixes between Normal blending (0%) and Screen mode blending (100%).
   Fade to blend mode:  Fades from normal to the blend setting over the first 20%
     of the transition.

 With the spread angle set to 0° all grains are blown in the same direction giving
 a streaky effect.  At 360° the grains spread evenly in all directions.  With the
 default 40° there is a spread of +- 20° from the direction set with "Rotation".

 Adjusting the amount curve in the VFX graph display can do some really interesting
 things too.  That's definitely worth playing with.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect BlownAway.fx
//
// Version history:
//
// Modified 2024-09-05 by jwrl.
// Added schrauber's grain size adjustment, with a different noise generator to provide
// the edge breakup.
//
// Built 2024-08-30 by schrauber with input from jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Blown away", "Mix", "Special Fx transitions", "The outgoing video blows away like dust particles", "CanSize");

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 0.2, 0.0, 1.0);

DeclareFloatParam (GrainSize, "Grain size", kNoGroup, kNoFlags, 1.0, 1.0, 5.0);
DeclareFloatParam (DecayRate, "Decay Rate", kNoGroup, kNoFlags, 0.7, 0.0, 1.0);

DeclareFloatParam (Revolutions, "Revolutions",  "Wind direction", kNoFlags,  0.4, 0.0,   3.0);
DeclareFloatParam (SpreadAngle, "Spread angle", "Wind direction", kNoFlags, 40.0, 0.0, 360.0);

DeclareFloatParam (BlendMode, "Blend mode", "Fg blend modes: 0% is Normal, 100% is Screen blend mode", kNoFlags, 0.0, 0.0, 1.0);

DeclareBoolParam (FadeToBlend, "Fade to blend mode", "Fg blend modes: 0% is Normal, 100% is Screen blend mode", true);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI       3.14159
#define PI_HALF  1.5708
#define PI_TWO   6.28319

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float hash (float n)
{
   return frac (cos (n) * 114514.1919);
}

float2 noise_sub (float2 progress, float2 xy)
{
   float2 uv = progress + xy;

   float a = xy.x + xy.y * 10.0;
   float b = hash (uv.x);
   float c = hash (uv.y);

   return float2 (lerp (hash (a), hash (a + 1.0), b),
                  lerp (hash (a + 10.0), hash (a + 11.0), c));
}

float2 fn_noise (float2 progress, float2 xy)
// float2 texture noise (two different values per pixel)
{
   float gScale = pow (max (1.0, GrainSize), 2.0);

  // Grain edge roughness:

   float2 GrainRoughness = (noise_sub (progress, xy) - 0.5.xx) * gScale * 0.0005;
   float2 xyScale = round (float2 (_OutputWidth, _OutputHeight) / gScale);

   xy = round ((xy + GrainRoughness) * xyScale) / xyScale;

   float2 noise1 = frac (sin (1.0 + progress + (xy.x * 82.3)) * (xy.x + 854.5421));

   return frac (sin ((1.0 + noise1 + xy.y) * 92.7) * (noise1 + xy.y + 928.4837));
}

float2 fn_ditherCoord (float2 uv, float radius, float randomAngle, float randomRadius )
// Angle dependent dither radius
{
   randomAngle *= PI;

   float angle = Revolutions * PI_TWO;
   float openingAngle = SpreadAngle / 180.0;
   float halfAspectRatio = ((_OutputAspectRatio - 1.0) / 2.0) +1.0;

   float2 radius2 = float2 (1.0 / halfAspectRatio, halfAspectRatio) * radius.xx; // For a round blur circle and consistent visual strength when changing the output aspect ratio.
   float2 coord;

   angle += randomAngle * openingAngle;
   angle -= openingAngle * PI_HALF;             // Causes a symmetrical change in the opening angle.
   sincos (angle, coord.y, coord.x);

   radius2 *= randomRadius;

   return uv + (coord * radius2);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclarePass (Fgd)
{ return ReadPixel (Fg, uv1); }

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (Main)
{
   float2 noiseBase = float2 (0.5, 0.8);              // Base values for semi-random calculation
   float2 noise     = fn_noise (noiseBase, uv3);      // float2 texture noise

   // ... Destruction characteristic ...

   float destruction = 1.0 - DecayRate;               // Changes the DecayRate range from 0...1 to 1...0
   destruction *=  (1.0 - Amount);                    // Ensures that the maximum destruction is achieved when Amount==1.  Warning, it can be negative!
   destruction =  max (destruction * 20.0, 0.01);     // Preparation for the subsequent pow function.
   float randomRadius = pow (noise.y, destruction);   // Destruction characteristic

   float2 ditherCoord = fn_ditherCoord (uv3, Amount * Amount * 10.0, noise.x, randomRadius); // Angle dependent dither radius

  // Foreground texture ...

   float4 fgDith = ReadPixel (Fgd, ditherCoord);      // Dithered foreground

  // Fade out the dithered foreground ...

   float fade = saturate ((Amount - 0.95) * 20.0);    // "fade" range 0 ... 1 if the "Amount" range <= 0.95 ...1

   fgDith.a *= 1.0 - fade;                            // Fade out pixels remaining in the texture (in the amount range of 0.95 ...1)

  // Merge both foreground samples ...

   float alphaSum = max (1e-9, fgDith.a);             // For example, important for the behavior in the event of mask softness.

   float4 fgMix = fgDith;

   fgMix.a = min (1.0, alphaSum);

   // Merge foreground with background ...

   float4 bg = ReadPixel (Bgd, uv3);

   // Fade the background if needed and set up for the blend fade to be done later

   float blend = BlendMode;                              // Start with normal blend mode setting.

   if (FadeToBlend) {
      bg = lerp (fgMix, bg, saturate (Amount * 2.0));    // The background fade is half the total transition duration.
      blend *= saturate (Amount * 5.0);                  // This makes the blend mode fade-in take 20% of the total amount.
   }

   float4 fgMix2  = 1.0 - ((1.0 - bg) * (1.0 - fgMix));  // "Screen" blending mode (foreground transparency from darkness)
   float4 fgDith2 = 1.0 - ((1.0 - bg) * (1.0 - fgDith));

   float4 mix1 = lerp (bg, fgMix,  fgMix.a);             // Alpha foreground transparency used.
   float4 mix2 = lerp (bg, fgMix2, fgMix.a);             // "Screen" + Alpha foreground transparency used.

   // Ramps into the blend setting over the first 20% of the transition if needed.

   float4 ret = lerp (mix1, mix2, blend);                // Choosing or mixing foreground transparent modes.

   ret.a = 1.0;

   return ret;
}
