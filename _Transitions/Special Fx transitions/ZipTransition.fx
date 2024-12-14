// @Maintainer jwrl
// @Released 2024-12-14
// @Author jwrl
// @Author khaver
// @Author Eduardo Castineyra
// @Created 2024-12-14

/**
 This effect is based on khaver's "Page Roll transition".  It zips the outgoing video open
 to reveal the incoming video, or zips the incoming video closed to hide the outgoing.  The
 zip moves in either the horizontal or vertical direction.  The settings are:

   * Amount:  Self explanatory.
   * Zip settings
      * Direction:  Sets the zip to top to bottom, bottom to top, left to right or
        right to left.
      * Curl width:  Adjusts the width of the zip curl.
      * Curl shading:  Adjusts the shading density on the curve
      * Translucency:  Adjusts the visibility of the unzipped zip curl.
      * Open or shut:  Opens or closes the zip.

 Shading in the page roll effect was fixed and could not be adjusted.  In this effect it's
 variable, and the value that is used as the default matches the original fixed setting.
 Since a small amount of shading is needed to give a realistic curvature effect the minimum
 setting does not turn the shading completely off.

 Another difference between the page roll effect and this one is in the way that the fold
 translucency (Image on backside) is handled.  In the original it could only be turned on
 or off.  This effect allows for it to be adjusted over a wide range.  The default is
 similar to the original preset value, while the full range is roughly double that.  The
 minimum setting is identical to disabling translucency in the original effect.

 One final note:  khaver's "Page Roll transition", was developed from a shadertoy effect
 by Eduardo Castineyra (casty).  The original effect when used as it is here displayed
 nonlinearities which I have done my best to address.  The result is not perfect.  Some
 setting combinations will give transitions that start a few frames later than expected
 and/or end a few frames early.  I have not been able to solve that.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect ZipTransition.fx
//
//-----------------------------------------------------------------------------------------//
// Original Shadertoy author:
// Eduardo Castineyra (casty) (2015-08-30) https://www.shadertoy.com/view/MtBSzR
//
// Creative Commons Attribution 4.0 International License
//
// The basic effect on which this was based was adapted for Lightworks by user khaver
// 1 June 2018 from original code by the above author taken from the Shadertoy website:
// https://www.shadertoy.com/view/MtBSzR
//
// This adaption retains the same Creative Commons license shown above.  It cannot be
// used to develop effects code for commercial purposes.
//
// Note: most code comments are from the original authors, casty and khaver.
//-----------------------------------------------------------------------------------------//
//
// Version history:
//
// Built 2024-12-14 by jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Zip transition", "Mix", "Special Fx transitions", "Unzip the outgoing or zip the incoming video", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInputs (Fg, Bg);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam   (SetTechnique, "Direction",    "Zip settings", 0, "Top to bottom|Bottom to top|Left to right|Right to left");

DeclareFloatParam (CurlWidth,    "Curl width",   "Zip settings", kNoFlags, 0.2, 0.0, 1.0);
DeclareFloatParam (Shading,      "Curl shading", "Zip settings", kNoFlags, 0.5, 0.0, 1.0);
DeclareFloatParam (Translucency, "Translucency", "Zip settings", kNoFlags, 0.5, 0.0, 1.0);

DeclareIntParam   (OpenShut,     "Open or shut", "Zip settings", 0, "Open zip|Close zip");

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define PI  3.141592
#define PX  5.712389  // PI * 1.5 + 1
#define R90 1.570796

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

// 1D function x: _cylFun (t); y: normal at that point.

float4 ZipPass (sampler F, sampler B, float2 xy)
{
   float radius = saturate (CurlWidth) + 0.08;
   float start  = radius * 0.5;
   float radX2  = 2.0 * radius;

   float r1 = saturate (radX2);
   float r2 = saturate (radX2 - 1.0);
   float maximum, minimum, prog;

   if (OpenShut) {
      maximum = lerp (lerp (0.0,  0.29, r1), 0.17, r2);
      minimum = lerp (lerp (0.92, 0.95, r1), 1.0, r2);
   }
   else {
      maximum = lerp (lerp (1.0, 0.95, r1), 0.92, r2);
      minimum = lerp (lerp (0.17, 0.29, r1), 0.0, r2);
   }

   prog = lerp (minimum, maximum, saturate (Amount));
   prog = min (1.0, prog + ((1.0 - prog) * start));

   float2 xy1 = (1.0 - prog).xx;

   float d = length (xy1 * (1.0 + (4.0 * radius))) - radX2;

   float3 curl = float3 (normalize (xy1), d);

   d = dot (xy, curl.xy);

   float2 end = abs ((1.0.xx - xy) / curl.xy);

   float maxt = d + min (end.x, end.y);

   // The following new code replaces a function call in the original effect.  It means some logic re-ordering
   // but allows for the replacement of a static float (_cyl) with a variable (curl) - jwrl.

   float2 cf = float2 (d, 1.0);

   if (d >= curl.z - radius) {                         // Before the curl
      if (d > curl.z + radius) cf = -1.0.xx;           // After the curl
      else {                                           // Inside the curl
         float a  = asin ((d - curl.z) / radius);
         float ca = PI - a;
         float c  = cos (ca);                          // New variable shading starts here - jwrl.
         float cc = sin (c * R90);                     // Minimum shading value - jwrl;

         float shade = Shading * 2.0;                  // Double the shading range - jwrl.

         cf.x = curl.z + ca * radius;
         cf.y = lerp (cc, c, shade);                   // Variable shading appied - jwrl.

         if (cf.x >= maxt) {                           // We see the back face
            if (d < curl.z) cf = float2 (d, 1.0);      // Front face before the curve starts
            else {
               cf.x = curl.z + (a * radius);

               if (cf.x >= maxt) cf = -1.0.xx;         // Front face curve
               else {
                  c    = cos (a);                      // Shading adjustment part two - jwrl.
                  cc   = sin (c * R90);                // Minimum shading value - jwrl;
                  cf.y = lerp (cc, c, shade);          // Apply variable shading - jwrl.
               }
            }
         }
      }
   }

   // End of function call replacement - jwrl.

   float2 uv = xy + curl.xy * (cf.x - d);

   float shadow = 1.0 - smoothstep (0.0, radX2, curl.z - d);

   shadow *= smoothstep (-radius, radius, (maxt - (cf.x + (PX * radius))));

   float4 Fgd = ReadPixel (F, uv);
   float4 Bgd = ReadPixel (B, xy);
   float4 retval;

   // Adjustable translucency added to original effect - jwrl.

   Fgd = cf.y > 0.0  ? Fgd * cf.y  * (1.0 - shadow)
        : (((Fgd + 1.0) * Translucency * 0.4) - 1.0) * cf.y;

   shadow = smoothstep (0.0, radX2, d - curl.z);
   retval = prog == 1.0 ? Bgd : cf.x > 0.0 ? Fgd : Bgd * shadow;
   retval.a = 1.0;

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

//----------  Top to bottom  --------------------------------------------------------------//

DeclarePass (Fg_0)
{ return OpenShut ? ReadPixel (Bg, uv2) : ReadPixel (Fg, uv1); }

DeclarePass (Bg_0)
{ return OpenShut ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclarePass (F1_0)
{
   float2 xy = OpenShut ? float2 (uv3.x / 2.0, uv3.y) : float2 (uv3.x / 2.0, 1.0 - uv3.y);

   return ReadPixel (Fg_0, xy);
}

DeclarePass (B1_0)
{
   float2 xy = OpenShut ? float2 (uv3.x / 2.0, uv3.y) : float2 (uv3.x / 2.0, 1.0 - uv3.y);

   return ReadPixel (Bg_0, xy);
}

DeclarePass (Zleft_0)
{ return ZipPass (F1_0, B1_0, float2 (uv3.x * 2.0, 1.0 - uv3.y)); }

DeclarePass (F2_0)
{
   float2 xy = OpenShut ? float2 (1.0 - (uv3.x / 2.0), uv3.y) : 1.0.xx - float2 (uv3.x / 2.0, uv3.y);

   return ReadPixel (Fg_0, xy);
}

DeclarePass (B2_0)
{
   float2 xy = OpenShut ? float2 (1.0 - (uv3.x / 2.0), uv3.y) : 1.0.xx - float2 (uv3.x / 2.0, uv3.y);

   return ReadPixel (Bg_0, xy);
}

DeclarePass (Zright_0)
{ return ZipPass (F2_0, B2_0, 1.0.xx - float2 (uv3.x * 2.0, uv3.y)); }

DeclareEntryPoint (Zipper_0)
{
   float2 xy1, xy2;

   if (OpenShut) {
      xy1 = float2 (uv3.x, 1.0 - uv3.y);
      xy2 = float2 (xy1.x - 0.5, xy1.y);
   }
   else {
      xy1 = uv3;
      xy2 = float2 (uv3.x - 0.5, uv3.y);
   }

   return uv3.x <= 0.5 ? ReadPixel (Zleft_0, xy1) : ReadPixel (Zright_0, xy2);
}

//--------  Bottom to top  ----------------------------------------------------------------//

DeclarePass (Fg_1)
{ return OpenShut ? ReadPixel (Bg, uv2) : ReadPixel (Fg, uv1); }

DeclarePass (Bg_1)
{ return OpenShut ? ReadPixel (Fg, uv1) : ReadPixel (Bg, uv2); }

DeclarePass (F1_1)
{
   float2 xy = !OpenShut ? float2 (uv3.x / 2.0, uv3.y) : float2 (uv3.x / 2.0, 1.0 - uv3.y);

   return ReadPixel (Fg_1, xy);
}

DeclarePass (B1_1)
{
   float2 xy = !OpenShut ? float2 (uv3.x / 2.0, uv3.y) : float2 (uv3.x / 2.0, 1.0 - uv3.y);

   return ReadPixel (Bg_1, xy);
}

DeclarePass (Zleft_1)
{ return ZipPass (F1_1, B1_1, float2 (uv3.x * 2.0, 1.0 - uv3.y)); }

DeclarePass (F2_1)
{
   float2 xy = !OpenShut ? float2 (1.0 - (uv3.x / 2.0), uv3.y) : 1.0.xx - float2 (uv3.x / 2.0, uv3.y);

   return ReadPixel (Fg_1, xy);
}

DeclarePass (B2_1)
{
   float2 xy = !OpenShut ? float2 (1.0 - (uv3.x / 2.0), uv3.y) : 1.0.xx - float2 (uv3.x / 2.0, uv3.y);

   return ReadPixel (Bg_1, xy);
}

DeclarePass (Zright_1)
{ return ZipPass (F2_1, B2_1, 1.0.xx - float2 (uv3.x * 2.0, uv3.y)); }

DeclareEntryPoint (Zipper_1)
{
   float2 xy1, xy2;

   if (OpenShut) {
      xy1 = uv3;
      xy2 = float2 (uv3.x - 0.5, uv3.y);
   }
   else {
      xy1 = float2 (uv3.x, 1.0 - uv3.y);
      xy2 = float2 (xy1.x - 0.5, xy1.y);
   }

   return uv3.x <= 0.5 ? ReadPixel (Zleft_1, xy1) : ReadPixel (Zright_1, xy2);
}

//--------  Left to right  ----------------------------------------------------------------//

DeclarePass (Fg_2)
{ return OpenShut ? ReadPixel (Bg, uv2.yx) : ReadPixel (Fg, uv1.yx); }

DeclarePass (Bg_2)
{ return OpenShut ? ReadPixel (Fg, uv1.yx) : ReadPixel (Bg, uv2.yx); }

DeclarePass (F1_2)
{
   float2 xy = !OpenShut ? float2 (uv3.x / 2.0, 1.0 - uv3.y) : float2 (uv3.x / 2.0, uv3.y);

   return ReadPixel (Fg_2, xy);
}

DeclarePass (B1_2)
{
   float2 xy = !OpenShut ? float2 (uv3.x / 2.0, 1.0 - uv3.y) : float2 (uv3.x / 2.0, uv3.y);

   return ReadPixel (Bg_2, xy);
}

DeclarePass (Ztop_2)
{ return ZipPass (F1_2, B1_2, float2 (uv3.x * 2.0, 1.0 - uv3.y)); }

DeclarePass (F2_2)
{
   float2 xy = !OpenShut ? 1.0.xx - float2 (uv3.x / 2.0, uv3.y) : float2 (1.0 - (uv3.x / 2.0), uv3.y);

   return ReadPixel (Fg_2, xy);
}

DeclarePass (B2_2)
{
   float2 xy = !OpenShut ? 1.0.xx - float2 (uv3.x / 2.0, uv3.y) : float2 (1.0 - (uv3.x / 2.0), uv3.y);

   return ReadPixel (Bg_2, xy);
}

DeclarePass (Zbot_2)
{ return ZipPass (F2_2, B2_2, 1.0.xx - float2 (uv3.x * 2.0, uv3.y)); }

DeclareEntryPoint (Zipper_2)
{
   float2 xy1, xy2;

   if (OpenShut) {
      xy1 = float2 (uv3.y, 1.0 - uv3.x);
      xy2 = float2 (uv3.y - 0.5, 1.0 - uv3.x);
   }
   else {
      xy1 = uv3.yx;
      xy2 = float2 (uv3.y - 0.5, uv3.x);
   }

   return uv3.y <= 0.5 ? ReadPixel (Ztop_2, xy1) : ReadPixel (Zbot_2, xy2);
}

//--------  Right to left  ----------------------------------------------------------------//

DeclarePass (Fg_3)
{ return OpenShut ? ReadPixel (Bg, uv2.yx) : ReadPixel (Fg, uv1.yx); }

DeclarePass (Bg_3)
{ return OpenShut ? ReadPixel (Fg, uv1.yx) : ReadPixel (Bg, uv2.yx); }

DeclarePass (F1_3)
{
   float2 xy = OpenShut ? float2 (uv3.x / 2.0, 1.0 - uv3.y) : float2 (uv3.x / 2.0, uv3.y);

   return ReadPixel (Fg_3, xy);
}

DeclarePass (B1_3)
{
   float2 xy = OpenShut ? float2 (uv3.x / 2.0, 1.0 - uv3.y) : float2 (uv3.x / 2.0, uv3.y);

   return ReadPixel (Bg_3, xy);
}

DeclarePass (Ztop_3)
{ return ZipPass (F1_3, B1_3, float2 (uv3.x * 2.0, 1.0 - uv3.y)); }

DeclarePass (F2_3)
{
   float2 xy = OpenShut ? 1.0.xx - float2 (uv3.x / 2.0, uv3.y) : float2 (1.0 - (uv3.x / 2.0), uv3.y);

   return ReadPixel (Fg_3, xy);
}

DeclarePass (B2_3)
{
   float2 xy = OpenShut ? 1.0.xx - float2 (uv3.x / 2.0, uv3.y) : float2 (1.0 - (uv3.x / 2.0), uv3.y);

   return ReadPixel (Bg_3, xy);
}

DeclarePass (Zbot_3)
{ return ZipPass (F2_3, B2_3, 1.0.xx - float2 (uv3.x * 2.0, uv3.y)); }

DeclareEntryPoint (Zipper_3)
{
   float2 xy1, xy2;

   if (OpenShut) {
      xy1 = uv3.yx;
      xy2 = float2 (uv3.y - 0.5, uv3.x);
   }
   else {
      xy1 = float2 (uv3.y, 1.0 - uv3.x);
      xy2 = float2 (uv3.y - 0.5, 1.0 - uv3.x);
   }

   return uv3.y <= 0.5 ? ReadPixel (Ztop_3, xy1) : ReadPixel (Zbot_3, xy2);
}

