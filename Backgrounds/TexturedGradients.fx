// @Maintainer jwrl
// @Released 2025-02-12
// @Author jwrl
// @Created 2025-02-12

/**
 This produces a choice of gradients, ramping from the selected colour to a modified
 version of that colour and back out again.  Additionally, a layer of colour particles
 can be overlaid.  The colour of the particles is also based on a modified version of
 the master colour.  The settings are:

   [*] Centre shape:  The gradient shape can be vertical, horizontal, rectangular or
       ellipsoid.
   [*] Shape size:  Adjusts the size of the on-screen area of the centre shape.
   [*] Shape softness:  Sets the softness of the blend between the background (outer)
       and foreground (inner) colours.
   [*] Colour:  Sets the background outer colour.  This is used as the basis of both
       the centre and particle colours as well.
   [*] Centre colour
       [*] Gain:  Adjusts the gain of the central colour.
       [*] Hue:  Adjusts the central hue.
       [*] Saturation: Adjusts the central saturation.
   [*] Particle geometry
       [*] Pattern:  Changes the particle pattern.  Zero makes the pattern round and
           evenly spaced.
       [*] Density:  Adjusts the particle density.
       [*] Size:  Adjusts the particle size.
       [*] Aspect:  Adjusts the particle aspect ratio.
       [*] Softness:  Adjusts the softness of the particles.
   [*] Particle colour
       [*] Gain:  Particle gain.
       [*] Hue:  Particle hue.
       [*] Saturation:  Particle saturation.
       [*] Opacity:  Mixes the particles over the gradient.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TexturedGradients.fx
//
// Version history:
//
// Created 2025-02-12 by jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Textured gradients", "Mattes", "Backgrounds", "Colour gradients with a textured overlay", kNoFlags);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

DeclareMask;

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareIntParam (Shape, "Centre shape", kNoGroup, 3, "Vertical|Horizontal|Rectangle|Ellipse");

DeclareFloatParam (sSize, "Shape size",     kNoGroup, kNoFlags, 0.4, 0.0, 1.0);
DeclareFloatParam (sSoft, "Shape softness", kNoGroup, kNoFlags, 0.5, 0.0, 1.0);

DeclareColourParam (Colour, "Colour", kNoGroup, kNoFlags, 0.631, 0.831, 0.894, 1.0);

DeclareFloatParam (gGain, "Gain",       "Centre colour",  kNoFlags,  0.05,  -1.0, 1.0);
DeclareFloatParam (gHue,  "Hue",        "Centre colour",  kNoFlags,  0.615,  0.0, 1.0);
DeclareFloatParam (gSatn, "Saturation", "Centre colour",  kNoFlags, -0.58,  -1.0, 1.0);

DeclareFloatParam (pSeed,   "Pattern",  "Particle geometry", kNoFlags, 0.5,  0.0, 1.0);
DeclareFloatParam (pDens,   "Density",  "Particle geometry", kNoFlags, 0.75, 0.0, 1.0);
DeclareFloatParam (pSize,   "Size",     "Particle geometry", kNoFlags, 0.5,  0.0, 1.0);
DeclareFloatParam (pAspect, "Aspect",   "Particle geometry", kNoFlags, 0.0, -1.0, 1.0);
DeclareFloatParam (pSoft,   "Softness", "Particle geometry", kNoFlags, 0.5,  0.0, 1.0);

DeclareFloatParam (pGain, "Gain",       "Particle colour", kNoFlags, 0.0,  -1.0, 1.0);
DeclareFloatParam (pHue,  "Hue",        "Particle colour", kNoFlags, 0.0,   0.0, 1.0);
DeclareFloatParam (pSatn, "Saturation", "Particle colour", kNoFlags, 0.5,  -1.0, 1.0);
DeclareFloatParam (pMix,  "Opacity",    "Particle colour", kNoFlags, 0.185, 0.0, 1.0);

DeclareFloatParam (_OutputAspectRatio);

DeclareFloatParam (_OutputWidth);
DeclareFloatParam (_OutputHeight);

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI 3.1415926536

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 rgb2hsv (float4 rgb)
{
   float Cmin  = min (rgb.r, min (rgb.g, rgb.b));
   float Cmax  = max (rgb.r, max (rgb.g, rgb.b));
   float delta = Cmax - Cmin;

   float4 hsv  = float3 (0.0, Cmax, rgb.a).xxyz;

   if (Cmax != 0.0) {
      hsv.x = (rgb.r == Cmax) ? (rgb.g - rgb.b) / delta
            : (rgb.g == Cmax) ? 2.0 + (rgb.b - rgb.r) / delta
                              : 4.0 + (rgb.r - rgb.g) / delta;
      hsv.x = frac (hsv.x / 6.0);
      hsv.y = 1.0 - (Cmin / Cmax);
   }

   return hsv;
}

float4 hsv2rgb (float4 hsv)
{
   if (hsv.y == 0.0) return hsv.zzzw;

   hsv.x *= 6.0;

   int i = (int) floor (hsv.x);

   float f = hsv.x - (float) i;
   float p = hsv.z * (1.0 - hsv.y);
   float q = hsv.z * (1.0 - hsv.y * f);
   float r = hsv.z * (1.0 - hsv.y * (1.0 - f));

   if (i == 0) return float4 (hsv.z, r, p, hsv.w);
   if (i == 1) return float4 (q, hsv.z, p, hsv.w);
   if (i == 2) return float4 (p, hsv.z, r, hsv.w);
   if (i == 3) return float4 (p, q, hsv.zw);
   if (i == 4) return float4 (r, p, hsv.zw);

   return float4 (hsv.z, p, q, hsv.w);
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

DeclarePass (Noise)
{
   float r, n, d;

   float2 xy;

   if (pSeed >= 0.01) {
      xy = frac (lerp (float2 (0.00013, 0.00123), float2 (0.00017, 0.0016), pSeed) + uv1);

      r = frac (sin (dot (xy, float2 (12.9898, 78.233)) + xy.x + xy.y) * (43758.5453));
      n = sin (xy.x) + cos (xy.y) + r * 1000.0;
      d = saturate (frac (fmod (n, 17.0) * fmod (n, 94.0)) * 3.0);
   }
   else {
      xy = abs ((frac (float2 (_OutputAspectRatio, 1.0) * uv1 * 576.0) - 0.5.xx) * 2.0);

      r = dot (xy, xy);
      d = sqrt (r);
   }

   return d.xxxx;
}

DeclarePass (PreBlur)
{
   float scale  = (0.35 * pSize) + 0.4;
   float aspect = 3.0 * pAspect;

   float2 density = lerp (0.25, 0.05, pDens).xx;

   if (pAspect < 0.0) { density.x /= 1.0 - aspect; }
   else { density.y /= 1.0 + aspect; }

   float2 xy = (uv2 - 0.5.xx) * density;

   float4 g = tex2D (Noise, xy + 0.5.xx);

   return float4 ((g.g > scale ? 0.0 : 1.0).xxx, 1.0);
}

DeclarePass (Blur_X)
{
   float2 pix = float2 (pSoft * 2.0 / _OutputWidth, 0.0);
   float2 xy1 = uv2 + pix;

   float4 retval = tex2D (PreBlur, uv2);

   retval += tex2D (PreBlur, xy1); xy1 += pix;
   retval += tex2D (PreBlur, xy1); xy1 += pix;
   retval += tex2D (PreBlur, xy1); xy1 += pix;
   retval += tex2D (PreBlur, xy1); xy1 += pix;
   retval += tex2D (PreBlur, xy1); xy1 += pix;
   retval += tex2D (PreBlur, xy1);
   xy1 = uv2 - pix;
   retval += tex2D (PreBlur, xy1); xy1 -= pix;
   retval += tex2D (PreBlur, xy1); xy1 -= pix;
   retval += tex2D (PreBlur, xy1); xy1 -= pix;
   retval += tex2D (PreBlur, xy1); xy1 -= pix;
   retval += tex2D (PreBlur, xy1); xy1 -= pix;
   retval += tex2D (PreBlur, xy1);

   return retval / 13;
}

DeclarePass (Grain)
{
   float2 pix = float2 (0.0, pSoft * 2.0 / _OutputHeight);
   float2 xy1 = uv2 + pix;

   float4 retval = tex2D (Blur_X, uv2);

   retval += tex2D (Blur_X, xy1); xy1 += pix;
   retval += tex2D (Blur_X, xy1); xy1 += pix;
   retval += tex2D (Blur_X, xy1); xy1 += pix;
   retval += tex2D (Blur_X, xy1); xy1 += pix;
   retval += tex2D (Blur_X, xy1); xy1 += pix;
   retval += tex2D (Blur_X, xy1);
   xy1 = uv2 - pix;
   retval += tex2D (Blur_X, xy1); xy1 -= pix;
   retval += tex2D (Blur_X, xy1); xy1 -= pix;
   retval += tex2D (Blur_X, xy1); xy1 -= pix;
   retval += tex2D (Blur_X, xy1); xy1 -= pix;
   retval += tex2D (Blur_X, xy1); xy1 -= pix;
   retval += tex2D (Blur_X, xy1);

   return retval / 13;
}

DeclareEntryPoint (TextureGradient)
{
   float2 g_sv = float2 (gSatn, gGain) + 1.0.xx;
   float2 p_sv = float2 (pSatn, pGain) + 1.0.xx;

   float4 granules = tex2D (Grain, uv2);
   float4 g_hsv    = rgb2hsv (Colour);
   float4 p_hsv    = g_hsv;

   g_hsv.x  += gHue;
   g_hsv.yz *= g_sv;
   p_hsv.x  += pHue;
   p_hsv.yz *= p_sv;

   if (g_hsv.x > 1.0) g_hsv.x -= 1.0;
   if (p_hsv.x > 1.0) p_hsv.x -= 1.0;

   float4 g_Colour = hsv2rgb (g_hsv);
   float4 p_Colour = hsv2rgb (p_hsv);

   float size      = lerp (0.2, 1.0, sSize);
   float soft      = 2.0 * sSize;
   float min_shape = size - soft;
   float max_shape = size + soft;
   float shading;

   float2 uv = abs (uv2 - 0.5) * 2.0;
   float2 xy = smoothstep (min_shape, max_shape, uv);

   if (Shape == 0) { shading = xy.x; }                      // Vertical strip
   else if (Shape == 1) { shading = xy.y; }                 // Horizontal strip
   else if (Shape == 2) { shading = max (xy.x, xy.y); }     // Rectangle
   else {                                                   // Ellipse
      shading = distance (uv, 0.0.xx);
      min_shape *= 1.2732; max_shape *= 1.2732;
      shading = smoothstep (min_shape, max_shape, shading);
   }

   shading = (cos (shading * PI) + 1.0) / 2.0;

   float4 Fgd    = lerp (Colour, g_Colour, shading);
   float4 Bgd    = ReadPixel (Inp, uv1);
   float4 retval = lerp (Fgd, p_Colour, granules.x * pMix);

   return lerp (Bgd, retval, tex2D (Mask, uv1).x);
}

