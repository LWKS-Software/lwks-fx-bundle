// @Maintainer jwrl
// @Released 2024-09-03
// @Author schrauber
// @Created 2024-05-02

/**
 This effect drifts the image off as if it was made up of dust particles being blown
 away.  It's a very nice effect.  The parameters and what they do are:

   Amount: What it says.  Ramps the effect off over the keyframed section.
   Grain size:  Self explanatory.
   Decay Rate: At 100%, the largest amount is blown away at the beginning.
   Revolutions: Wind direction (has an adjustment range of 3 rotations).
   Spread angle: This parameter could also be called range.  See below.
   Blend:  Mixes between Normal blending (0%) and Screen mode blending (100%).
   Mask mode:  Only functions when a mask or masks is enabled.

     Only masked area decays:  Only the foreground will be visible at the outset.
       As the "Amount" increases the foreground area selected by the mask erodes,
        blowing away over the masked area as the background becomes visible.

     Fg masked before decay:  The masked foreground is initially visible over the
       background.  As the "Amount" increases the foreground area selected by the
       mask erodes and is blown away, overflowing the mask boundaries.  Ultimately
       only the background will be visible.

     Classic masking:  As for "Fg decays over Bg" except that the grains do not
       overflow the mask boundaries as they blow away.

 With the spread angle set to 0° all grains are blown in the same direction giving
 a streaky effect.  At 360° the grains spread evenly in all directions.  With the
 default 40° there is a spread of +- 20° from the direction set with "Rotation".

 Adjusting the amount curve in the VFX graph display can do some really interesting
 things too.  Definitely worth playing with.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Gone with the Wind 20240502.fx
//
// Version history:
//
// Modified 2024-09-03 jwrl.
// Added grain size adjuastment.
//
// Built 2024-05-02 by schrauber.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect( "Gone with the Wind", "Stylize", "Special Effects", "Random grainy pixel shifts in "Wind direction".", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput( Fg, Linear);
DeclareInput( Bg, Linear);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam(Amount, "Amount", kNoGroup, kNoFlags, 0.2, 0.0, 1.0);

DeclareFloatParam (GrainSize, "Grain size", kNoGroup, kNoFlags, 1.0, 1.0, 5.0);
DeclareFloatParam (DecayRate,"Decay rate", kNoGroup, kNoFlags, 0.7, 0.0, 1.0);

DeclareFloatParam (Revolutions, "Revolutions",  "Wind direction", kNoFlags,  0.4, 0.0,   3.0);
DeclareFloatParam (SpreadAngle, "Spread angle", "Wind direction", kNoFlags, 40.0, 0.0, 360.0);

DeclareFloatParam (BlendMode, "Blend", "Fg blend modes: 0% is Normal, 100% is Screen", kNoFlags, 0.0, 0.0, 1.0);

DeclareIntParam (Mask_Mode, "Mask mode", kNoGroup, 1, "Only masked area decays|Fg masked before decay|Classic masking");

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (_OutputAspectRatio);

#define PI       3.14159
#define PI_HALF  1.5708
#define PI_TWO   6.28319

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float2 fn_noise_sub (float2 progress, float2 xy)     // float2 texture noise (two different values per pixel)
{
   float2 noise1 = frac (sin (1.0 + progress + (xy.x * 82.3)) * (xy.x + 854.5421));
   return frac (sin ((1.0 + noise1 + xy.y) * 92.7) * (noise1 + xy.y + 928.4837));
}

float2 fn_noise (float2 progress, float2 xy)     // float2 texture noise (two different values per pixel)
{
   float gScale = pow (max (1.0, GrainSize), 2.0);

  // Grain edge roughness:

   float2 GrainRoughness = (fn_noise_sub (progress, xy) - 0.5) * gScale * 0.0005;
   float2 xyScale = round (float2 (1280 , 1280 / _OutputAspectRatio) / max (GrainSize, 0.01));  // 1280 is used to calculate the standard grain size corresponding to 1 pixel in 720p format.

   xy = round ( (xy + GrainRoughness) * xyScale) / xyScale;

   return fn_noise_sub (progress, xy);
}

float2 fn_ditherCoord (float2 uv, float radius, float randomAngle, float randomRadius )
{  // Angle dependent dither radius
   randomAngle *= PI;                       
   float angle = Revolutions * PI_TWO;
   float openingAngle = SpreadAngle / 180.0;
   float2 coord;    

   float halfAspectRatio = ((_OutputAspectRatio - 1.0) / 2.0) +1.0;
   float2 radius2 = float2 (1.0 / halfAspectRatio, halfAspectRatio) * radius.xx;  // For a round blur circle and consistent visual strength when changing the output aspect ratio.

   angle += randomAngle * openingAngle;
   angle -= openingAngle * PI_HALF;           // Causes a symmetrical change in the opening angle.
   sincos (angle, coord.y, coord.x);

   radius2 *= randomRadius;
   return uv + (coord * radius2);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

DeclareEntryPoint (Main)
{
   float2 noiseBase = float2 (0.5, 0.8);             // Base values for semi-random calculation
   float2 noise = fn_noise (noiseBase, uv1);         // float2 texture noise

   // ... Destruction characteristic ...
   float destruction = 1.0 - DecayRate;             // Changes the DecayRate range from 0...1 to 1...0
   destruction *=  (1.0 - Amount);                  // Ensures that the maximum destruction is achieved when Amount==1.  Warning, it can be negative!
   destruction =  max (destruction * 20.0, 0.01);   // Preparation for the subsequent pow function.
   float randomRadius = pow(noise.y, destruction);  // Destruction characteristic

   float2 ditherCoord = fn_ditherCoord (uv1, Amount * Amount * 10.0, noise.x, randomRadius); // Angle dependent dither radius

   // Mask ...
   float fgMaskDith = tex2D( Mask, ditherCoord).r;  // Mask for dither source selection (inside the mask == 1, outside == 0)
   float fgMask     = tex2D( Mask, uv1).r;          // Mask related to the original texture

  // Foreground texture ...
   float4 fgDith = ReadPixel (Fg, ditherCoord);    // Dithered foreground
   float4 fg = ReadPixel (Fg, uv1);                // At this point still normal foreground
   if (Mask_Mode == 1) fg = kTransparentBlack;

  // Fade out the dithered foreground ...
   float fade = saturate ((Amount - 0.95) * 20.0); // Â´fadeÂ´ range 0 ... 1 if the Â´AmountÂ´ range <= 0.95 ...1
   fgDith.a *= 1.0 - fade;                         // Fade out pixels remaining in the texture (in the amount range of 0.95 ...1)

  // Mask-dependent foreground transparencies ...
   fgDith.a *= fgMaskDith;                         // Replaces areas outside the mask with transparent black.
   fg.a *= 1.0 - fgMask;                           // Areas that correspond to the areas outside the mask become transparent.

  // Merge both foreground samples ...
   float alphaSum = max( 1e-9, fg.a + fgDith.a);   // For example, important for the behavior in the event of mask softness.
   float4 fgMix = (fg * (fg.a / alphaSum))  + (fgDith * (fgDith.a / alphaSum)) ; 
   fgMix.a = min (1.0, alphaSum);  

   // Merge foreground with background ...

   float4 bg = ReadPixel( Bg, uv2 );

   float4 fgMix2 = 1.0 - (( 1.0 - bg ) * ( 1.0 - fgMix ));   // "Screen" blending mode (foreground transparency from darkness)
   float4 fgDith2 = 1.0 - (( 1.0 - bg ) * ( 1.0 - fgDith ));

   float4 mix1;        // Alpha foreground transparency and mask transparency used.   
   if (Mask_Mode == 2) {
      mix1 = lerp(bg, fgDith, min( fgMask,fgDith.a));
   }else{
      mix1 = lerp(bg, fgMix, fgMix.a);
   }

   float4 mix2;        // "Screen" + Alpha foreground transparency and mask transparency used.   
   if (Mask_Mode == 2) {
      mix2 = lerp(bg, fgDith2, min( fgMask,fgDith.a));
   }else{
      mix2 = lerp(bg, fgMix2, fgMix.a);
   }

   float4 ret = lerp(mix1, mix2, BlendMode);  // Choosing or mixing foreground transparent modes.

   ret.a = 1.0;

   return ret;
}
