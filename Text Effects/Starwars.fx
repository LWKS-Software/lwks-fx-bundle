// @Maintainer jwrl
// @Released 2025-09-01
// @Author jwrl
// @Created 2025-09-01

/**
 This rotates a title or image key so that it scrolls up the screen to a vanishing
 point in the same way as the Star Wars opening title effect.  The vanishing point
 fade out range can be adjusted and the softness progress during the fade out can
 be adjusted as needed.  The settings are:

   [*] Opacity:  Fades the effect in and out.
   [*] Motion
      [*] Rotation:  The angle at which the text will move.
      [*] End point:  Position at which the title ends.
      [*] Fall off:  Position where the fade out starts.
      [*] Softness:  The amount of softness applied during the fade out.
      [*] Blur range:  The maximum softness that will applied during the fade.
   [*] Geometry
      [*] Scale:  Adjusts the scaling of the effect.
      [*] Y size:  Adjusts the vertical size of the effect.
      [*] Y offset:  Controls the vertical position the text.
   [*] Progress:  Moves the text from the bottom of frame to the end point.

 Although the effect has been designed with the ability to move the text by keyframing
 the progress, you can also use it with a credit roll.  Simply make sure that progress
 keyframing is turned off.  It will default to a 50% setting which will centre a credit
 roll in the frame.  The credit roll will then provide the text motion while using all
 of the effect's remaining adjustments.  An image key effect with Position Y keyframed
 can also be used to achieve the roll.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Starwars.fx
//
// Version history:
//
// Built 2025-09-01 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Starwars effect", "DVE", "Text Effects", "Produces the Starwars title effect", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Txt);
DeclareInput (Bg);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParam (Opacity, "Opacity", kNoGroup, kNoFlags, 1.0,  0.0, 1.0);

DeclareFloatParam (Rotation,  "Rotation",   "Motion", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (EndPoint,  "End point",  "Motion", kNoFlags, 1.0, 0.0, 1.0);
DeclareFloatParam (FallOff,   "Fall off",   "Motion", kNoFlags, 0.8, 0.0, 1.0);
DeclareFloatParam (Softness,  "Softness",   "Motion", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (BlurRange, "Blur range", "Motion", kNoFlags, 0.5, 0.0, 1.0);

DeclareFloatParam (Scale,    "Scale",    "Geometry", "DisplayAsPercentage", 1.0, 0.25, 4.0);
DeclareFloatParam (Ysize,    "Y size",   "Geometry", "DisplayAsPercentage", 1.0, 0.25, 4.0);
DeclareFloatParam (Y_offset, "Y offset", "Geometry", "DisplayAsPercentage", 0.5, -0.5, 1.5);

DeclareFloatParamAnimated (Progress, "Progress", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI       3.141592654
#define TWO_PI   6.283185307
#define HALF_PI  1.570796327

#define FALL_OFF 0.35

#define SOFT_1   0.01
#define INIT_1   0.0
#define LOOP_1   29
#define ANGLE_1  0.216661562

#define SOFT_2   0.006666667
#define INIT_2   0.136590985
#define LOOP_2   23
#define ANGLE_2  0.273181970

float4 _TransparentBlack = 0.0.xxxx;

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 mirror2D (sampler video, float2 uv)
{
   float2 xy = 1.0.xx - abs (abs (uv) - 1.0.xx);

   return tex2D (video, xy);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Inp)
{
   float2 xy = (uv1 - 0.5.xx) * 1.25;  // Scale the title to 80% size

   xy += float2 (0.5, lerp (-0.75, 1.75, Progress));

   return ReadPixel (Txt, xy);
}

DeclarePass (Bgd)
{ return ReadPixel (Bg, uv2); }

DeclarePass (Tilt)
{
   float angle = (1.0 + Rotation) * 0.5;
   float B = (cos (angle * PI) + 1.0) * 0.5;
   float T = 1.0 - B;

   float X = sin (angle * PI) * 0.3;
   float Y = sin (angle * TWO_PI) * 0.15;
   float Z = 1.0 - (tan ((0.5 - abs (angle - 0.5)) * HALF_PI) * 0.3);

   if (angle > 0.5) {
      B = 1.0 - B;
      T = 1.0 - T;
      X = -X;
   }

   float2 Ltop = float2 (-X, T);
   float2 Rtop = float2 (1.0 + X, T);
   float2 Lbot = float2 (X, B);
   float2 Rbot = float2 (1.0 - X, B);

   float2 c1 = Rtop - Lbot;
   float2 c2 = Rbot - Lbot;
   float2 c3 = Ltop - Rbot - c1;

   float d = (c1.x * c2.y) - (c2.x * c1.y);
   float a = ((c3.x * c2.y) - (c2.x * c3.y)) / d;
   float b = ((c1.x * c3.y) - (c3.x * c1.y)) / d;

   c1 += Lbot - Ltop + (a * Rtop);
   c2 += Lbot - Ltop + (b * Rbot);
   d   = (c1.x * (c2.y - (b * Ltop.y))) - (c1.y * (c2.x + (b * Ltop.x)))
       + (a * ((c2.x * Ltop.y) - (c2.y * Ltop.x)));

   float3x3 m = float3x3 (c2.y - (b * Ltop.y), (a * Ltop.y) - c1.y, (c1.y * b) - (a * c2.y),
                          (b * Ltop.x) - c2.x, c1.x - (a * Ltop.x), (a * c2.x) - (c1.x * b),
                          (c2.x * Ltop.y) - (c2.y * Ltop.x), (c1.y * Ltop.x) - (c1.x * Ltop.y),
                          (c1.x * c2.y)  - (c1.y * c2.x)) / d;

   float2 xy = float2 (((uv3.x - 0.5) * Z) + 0.5, uv3.y + Y);

   float3 xyz = mul (float3 (xy, 1.0), mul (m, float3x3 (1.0, 0.0.xx, -1.0.xx, -2.0, 0.0.xx, 1.0)));

   xy = xyz.xy / xyz.z;

   return (any (xy < 0.0) || any (xy > 1.0)) ? _TransparentBlack : tex2D (Inp, xy);
}

DeclarePass (Blur)
{
   float boundary = lerp (0.65, 0.3, EndPoint);

   float4 retval = _TransparentBlack;

   if (uv3.y > boundary) {
      float fullvis = saturate ((uv3.y - boundary) / ((1.0 - boundary) * FallOff * FALL_OFF));
      float blurvis = saturate ((uv3.y - boundary) / ((1.0 - boundary) * FallOff * BlurRange * FALL_OFF));
      float soften  = (1.0 - blurvis) * Softness * SOFT_1;

      if (soften > 0.0) {
         float2 xy, radius = (soften).xx;

         float angle = INIT_1;

         for (int i = 0; i < LOOP_1; i++) {
            sincos (angle, xy.x, xy.y);

            xy *= radius;
            xy += uv3;

            retval += mirror2D (Tilt, xy);
            angle  += ANGLE_1;
         }

         retval /= LOOP_1;
      }
      else retval = tex2D (Tilt, uv3);

      retval = lerp (_TransparentBlack, retval, sqrt (fullvis));
   }

   return retval;
}

DeclarePass (Fgd)
{
   float boundary = lerp (0.65, 0.3, EndPoint);

   float4 retval = _TransparentBlack;

   if (uv3.y > boundary) {
      float soften = 1.0 - saturate ((uv3.y - boundary) / ((1.0 - boundary) * FallOff * BlurRange * FALL_OFF));

      soften *= Softness * SOFT_2;

      if (soften > 0.0) {
         float2 xy, radius = (soften).xx;

         float angle = INIT_2;

         for (int i = 0; i < LOOP_2; i++) {
            sincos (angle, xy.x, xy.y);

            xy *= radius;
            xy += uv3;

            retval += mirror2D (Blur, xy);
            angle  += ANGLE_2;
         }

         retval /= LOOP_2;
      }
      else retval = tex2D (Blur, uv3);
   }

   return retval;
}

DeclareEntryPoint (Starwars)
{
   float2 xy = (uv3 - 0.5.xx) / Scale;

   xy.y /= Ysize;
   xy   += float2 (0.5, Y_offset);

   float4 retval = ReadPixel (Fgd, xy);

   return lerp (tex2D (Bgd, uv3), retval, retval.a * Opacity * tex2D (Mask, uv3).x);
}

