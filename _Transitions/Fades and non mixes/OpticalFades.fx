// @Maintainer jwrl
// @Released 2026-07-12
// @Author jwrl
// @Created 2018-12-31

/**
 This simple effect fades any video to which it's applied to or from from black.  It
 isn't a standard dissolve, since it requires one input only.  It must be applied in
 the same way as a title effect, i.e., by marking the region that the fade in or out
 is to occupy.

   [*]Amount:  The normal keyframed transition progress.
   [*]Fade type:  Can choose between fade up from transparent black and fade out
      to tranparent black.
   [*]Blend mode:  Selects between normal video, a posterised version, posterised
      monochrome video or black and white.

 NOTE:  This effect has been revised for Lightworks version 2026 and higher.  In my
 opinion it's really pointless because LW 2026 has fade in and fade out capabilities
 built in.  It's just here if for some reason you want it.  In all respects it behaves
 as the earlier versions did, and can be installed on any Lightworks version above 2022.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Fades.fx
//
// Version history:
//
// Updated 2026-07-12 jwrl.
// Revised for compatability with LW versions 2026 and higher.
//
// Updated 2024-08-17 jwrl.
// Replaced kTransparentBlack with 0.0.xxxx to fix Linux lerp()/mix() bug.
//
// Updated 2023-05-17 jwrl.
// Header reformatted.
//
// Conversion 2023-03-04 for LW 2023 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Fades", "Mix", "Fades and non mixes", "Fades video to or from black", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Inp);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Amount",     kNoGroup, kNoFlags, 1.0, 0.0, 1.0);
DeclareIntParam (Type,             "Fade type",  kNoGroup, 0, "Fade up|Fade down");
DeclareIntParam (SetTechnique,     "Blend mode", kNoGroup, 0, "Normal|Poster colour|Poster mono|Black and white");

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define MONO  float3(0.0, 0.0, 1.0)

#define BLACK float2(0.0,1.0).xxxy

#define T_1 0.25
#define T_2 0.5
#define T_3 0.75

#define M_0 0.0
#define M_1 0.333333
#define M_2 0.666667
#define M_3 1.0

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 makeMono (float4 Fg)
{
   return float4 (dot (Fg.rgb, MONO).xxx, Fg.a);
}

float fourtone (float S)
{
   float retval;

   if (S > T_3) { retval = M_3; }
   else if (S > T_2) { retval = M_2; }
   else if (S > T_1) { retval = M_1; }
   else retval = M_0;

   return retval;
}

float4 posterize (float4 Fg)
{
   float4 retval = Fg;

   retval.r = fourtone (Fg.r);
   retval.g = fourtone (Fg.g);
   retval.b = fourtone (Fg.b);

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

// Normal

DeclarePass (Fgd)
{ return ReadPixel (Inp, uv1); }

DeclareEntryPoint (Normal)
{
   float level = Type ? Amount : 1.0 - Amount;

   float4 Input  = ReadPixel (Fgd, uv2);

   return lerp (Input, BLACK, level);
}

//-----------------------------------------------------------------------------------------//

// Poster colour

DeclarePass (Fg1)
{ return ReadPixel (Inp, uv1); }

DeclareEntryPoint (Poster1)
{
   float level  = Type ? Amount : 1.0 - Amount;
   float mixlev = saturate (level * 4.0);

   float4 Input = ReadPixel (Fg1, uv2);

   Input = lerp (Input, posterize (Input), mixlev);

   return lerp (Input, BLACK, level);
}

//-----------------------------------------------------------------------------------------//

// Poster mono

DeclarePass (Fg2)
{ return ReadPixel (Inp, uv1); }

DeclareEntryPoint (Poster2)
{
   float level  = Type ? Amount : 1.0 - Amount;
   float mixlev = saturate (level * 4.0);

   float4 Input = ReadPixel (Fg2, uv2);
   float4 BandW = makeMono (Input);

   Input = lerp (Input, posterize (BandW), mixlev);

   return lerp (Input, BLACK, level);
}

//-----------------------------------------------------------------------------------------//

// Black and white

DeclarePass (Fg3)
{ return ReadPixel (Inp, uv1); }

DeclareEntryPoint (Monochrome)
{
   float level  = Type ? Amount : 1.0 - Amount;
   float mixlev = saturate (level * 4.0);

   float4 video = ReadPixel (Fg3, uv2);
   float4 Input = lerp (video, makeMono (video), mixlev);

   return lerp (Input, BLACK, level);
}
