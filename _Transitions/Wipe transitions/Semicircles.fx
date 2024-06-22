// @Maintainer jwrl
// @Released 2024-06-22
// @Author jwrl
// @Created 2024-06-22

/**
 This effect wipes the incoming video on using a series of semicircular wipes.  It does
 not provide a separate blend mode setting because with this style of effect it's not
 at all necessary.  All four wipe directions are provided.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Semicircles.fx
//
// Version history:
//
// Built 2024-06-22 jwrl.
//-----------------------------------------------------------------------------------------//

DeclareLightworksEffect ("Semicircles", "Mix", "Wipe transitions", "Uses a series of semicircular wipes to reveal the incoming video", CanSize);

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DeclareInput (Fg, Linear);
DeclareInput (Bg, Linear);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

DeclareFloatParamAnimated (Amount, "Progress", kNoGroup, kNoFlags, 1.0, 0.0, 1.0);

DeclareIntParam (SetTechnique, "Wipe direction", kNoGroup, 0, "Right to left|Left to right|Bottom to top|Top to bottom");

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

DeclareFloatParam (_OutputAspectRatio);

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float CircleGenHoriz (float2 xy, float offset_1, float offset_2)
{
   float2 xy1 = float2 (offset_1, 0.5);
   float2 xy2 = float2 (offset_2, 0.5);

   return step (distance (xy, xy1), 1.0) * step (1.0, distance (xy, xy2));
}

float CircleGenVert (float2 xy, float offset_1, float offset_2)
{
   float2 xy1 = float2 (0.5, offset_1);
   float2 xy2 = float2 (0.5, offset_2);

   return step (distance (xy1, xy), 1.0) * step (1.0, distance (xy2, xy));
}

//-----------------------------------------------------------------------------------------//
// Code
//-----------------------------------------------------------------------------------------//

//--  Left wipe  --------------------------------------------------------------------------//

DeclarePass (OutL)
{ return ReadPixel (Fg, uv1); }

DeclarePass (In_L)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (SemicirclesLeft)
{
   float4 Outgoing = tex2D (OutL, uv3);
   float4 Incoming = tex2D (In_L, uv3);

   float2 aspect = _OutputAspectRatio < 1.0
                 ? float2 (_OutputAspectRatio, 1.0)
                 : float2 (1.0, _OutputAspectRatio);
   float2 xy3    = ((uv3 - 0.5.xx) / aspect) + 0.5.xx;

   float amt     = Amount * 2.75;

   float start_1 = 2.000 - saturate (amt);
   float start_2 = 2.250 - saturate (amt - 0.375);
   float start_3 = 2.500 - saturate (amt - 0.75);
   float start_4 = 2.000 - saturate (amt - 1.75);

   float end_1   = 2.125 - saturate (amt - 0.125);
   float end_2   = 2.375 - saturate (amt - 0.5);
   float end_3   = 2.625 - saturate (amt - 0.875);
   float end_4   = 10.0;

   float wipe = CircleGenHoriz (xy3, start_1, end_1);

   wipe += CircleGenHoriz (xy3, start_2, end_2);
   wipe += CircleGenHoriz (xy3, start_3, end_3);
   wipe += CircleGenHoriz (xy3, start_4, end_4);

   return lerp (Outgoing, Incoming, saturate (wipe));
}

//--  Right wipe  -------------------------------------------------------------------------//

DeclarePass (OutR)
{ return ReadPixel (Fg, uv1); }

DeclarePass (In_R)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (SemicirclesRight)
{
   float4 Outgoing = tex2D (OutR, uv3);
   float4 Incoming = tex2D (In_R, uv3);

   float2 aspect = _OutputAspectRatio < 1.0
                 ? float2 (_OutputAspectRatio, 1.0)
                 : float2 (1.0, _OutputAspectRatio);
   float2 xy3    = ((uv3 - 0.5.xx) / aspect) + 0.5.xx;

   float amt     = Amount * 2.75;

   float start_1 = saturate (amt) - 1.0;
   float start_2 = saturate (amt - 0.375) - 1.25;
   float start_3 = saturate (amt - 0.750) - 1.5;
   float start_4 = saturate (amt - 1.750) - 1.0;

   float end_1   = saturate (amt - 0.125) - 1.125;
   float end_2   = saturate (amt - 0.500) - 1.375;
   float end_3   = saturate (amt - 0.875) - 1.625;
   float end_4   = 10.0;

   float wipe = CircleGenHoriz (xy3, start_1, end_1);

   wipe += CircleGenHoriz (xy3, start_2, end_2);
   wipe += CircleGenHoriz (xy3, start_3, end_3);
   wipe += CircleGenHoriz (xy3, start_4, end_4);

   return lerp (Outgoing, Incoming, saturate (wipe));
}

//--  Up wipe  ----------------------------------------------------------------------------//

DeclarePass (OutU)
{ return ReadPixel (Fg, uv1); }

DeclarePass (In_U)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (SemicirclesUp)
{
   float4 Outgoing = tex2D (OutU, uv3);
   float4 Incoming = tex2D (In_U, uv3);

   float2 aspect = _OutputAspectRatio < 1.0
                 ? float2 (_OutputAspectRatio, 1.0)
                 : float2 (1.0, _OutputAspectRatio);
   float2 xy3    = ((uv3 - 0.5.xx) / aspect) + 0.5.xx;

   float amt     = Amount * 2.75;

   float start_1 = 2.000 - saturate (amt);
   float start_2 = 2.250 - saturate (amt - 0.375);
   float start_3 = 2.500 - saturate (amt - 0.75);
   float start_4 = 2.000 - saturate (amt - 1.75);

   float end_1   = 2.125 - saturate (amt - 0.125);
   float end_2   = 2.375 - saturate (amt - 0.5);
   float end_3   = 2.625 - saturate (amt - 0.875);
   float end_4   = 10.0;

   float wipe = CircleGenVert (xy3, start_1, end_1);

   wipe += CircleGenVert (xy3, start_2, end_2);
   wipe += CircleGenVert (xy3, start_3, end_3);
   wipe += CircleGenVert (xy3, start_4, end_4);

   return lerp (Outgoing, Incoming, saturate (wipe));
}

//--  Down wipe  --------------------------------------------------------------------------//

DeclarePass (OutD)
{ return ReadPixel (Fg, uv1); }

DeclarePass (In_D)
{ return ReadPixel (Bg, uv2); }

DeclareEntryPoint (SemicirclesDown)
{
   float4 Outgoing = tex2D (OutD, uv3);
   float4 Incoming = tex2D (In_D, uv3);
   float4 retval   = Outgoing;

   float2 aspect = _OutputAspectRatio < 1.0
                 ? float2 (_OutputAspectRatio, 1.0)
                 : float2 (1.0, _OutputAspectRatio);
   float2 xy3    = ((uv3 - 0.5.xx) / aspect) + 0.5.xx;

   float amt     = Amount * 2.75;

   float start_1 = saturate (amt) - 1.0;
   float start_2 = saturate (amt - 0.375) - 1.25;
   float start_3 = saturate (amt - 0.750) - 1.5;
   float start_4 = saturate (amt - 1.750) - 1.0;

   float end_1   = saturate (amt - 0.125) - 1.125;
   float end_2   = saturate (amt - 0.500) - 1.375;
   float end_3   = saturate (amt - 0.875) - 1.625;
   float end_4   = 10.0;

   float wipe = CircleGenVert (xy3, start_1, end_1);

   wipe += CircleGenVert (xy3, start_2, end_2);
   wipe += CircleGenVert (xy3, start_3, end_3);
   wipe += CircleGenVert (xy3, start_4, end_4);

   return lerp (Outgoing, Incoming, saturate (wipe));
}

