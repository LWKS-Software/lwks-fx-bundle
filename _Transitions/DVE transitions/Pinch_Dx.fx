// @Maintainer jwrl
// @Released 2021-07-25
// @Author jwrl
// @Created 2021-07-25
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_Pinch_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Wx_Pinch.mp4

/**
 This effect pinches the outgoing video to a user-defined point to reveal the incoming
 shot.  It can also reverse the process to bring in the incoming video.  A really
 simple effect, it makes no claim to be anything much.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect Pinch_Dx.fx
//
// Version history:
//
// Rewrite 2021-07-25 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Pinch transition";
   string Category    = "Mix";
   string SubCategory = "DVE transitions";
   string Notes       = "Pinches the outgoing video to a user-defined point to reveal the incoming shot";
   bool CanSize       = true;
> = 0;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#ifndef _LENGTH
Wrong_Lightworks_version
#endif

#ifdef WINDOWS
#define PROFILE ps_3_0
#endif

#define DefineInput(TEXTURE, SAMPLER) \
                                      \
 texture TEXTURE;                     \
                                      \
 sampler SAMPLER = sampler_state      \
 {                                    \
   Texture   = <TEXTURE>;             \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define DefineTarget(TARGET, TSAMPLE) \
                                      \
 texture TARGET : RenderColorTarget;  \
                                      \
 sampler TSAMPLE = sampler_state      \
 {                                    \
   Texture   = <TARGET>;              \
   AddressU  = ClampToEdge;           \
   AddressV  = ClampToEdge;           \
   MinFilter = Linear;                \
   MagFilter = Linear;                \
   MipFilter = Linear;                \
 }

#define ExecuteShader(SHADER) { PixelShader = compile PROFILE SHADER (); }

#define EMPTY 0.0.xxxx
#define BLACK float2(0.0, 1.0).xxxy

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))
#define MaskedIp(SHADER,XY) (Overflow(XY) ? BLACK : tex2D(SHADER, XY))

#define MID_PT  (0.5).xx
#define HALF_PI 1.5707963

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Outw, s_Outgoing);
DefineTarget (Inw, s_Incoming);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Pinch to reveal,Expand to reveal";
> = 0;

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

float centreX
<
   string Description = "End point";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float centreY
<
   string Description = "End point";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_in (float2 uv : TEXCOORD2) : COLOR { return MaskedIp (s_Background, uv); }
float4 ps_out (float2 uv : TEXCOORD1) : COLOR { return MaskedIp (s_Foreground, uv); }

float4 ps_main_0 (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float2 centre = lerp (MID_PT, float2 (centreX, 1.0 - centreY), Amount);
   float2 xy = (uv3 - centre) * (1.0 + pow ((1.0 - cos (Amount * HALF_PI)), 4.0) * 128.0);
   float2 scale = pow (abs (xy * 2.0), -sin (Amount * HALF_PI));

   xy *= scale;
   xy += MID_PT;

   float4 retval = GetPixel (s_Outgoing, xy);

   return lerp (GetPixel (s_Background, uv2), retval, retval.a);
}

float4 ps_main_1 (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float2 centre = lerp (float2 (centreX, 1.0 - centreY), MID_PT, Amount);
   float2 xy = (uv3 - centre) * (1.0 + pow ((1.0 - sin (Amount * HALF_PI)), 4.0) * 128.0);
   float2 scale = pow (abs (xy * 2.0), -cos ((Amount + 0.01) * HALF_PI));

   xy *= scale;
   xy += MID_PT;

   float4 retval = GetPixel (s_Incoming, xy);

   return lerp (GetPixel (s_Foreground, uv1), retval, retval.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Pinch_Dx_0
{
   pass P_1 < string Script = "RenderColorTarget0 = Outw;"; > ExecuteShader (ps_out)
   pass P_2 ExecuteShader (ps_main_0)
}

technique Pinch_Dx_1
{
   pass P_1 < string Script = "RenderColorTarget0 = Inw;"; > ExecuteShader (ps_in)
   pass P_2 ExecuteShader (ps_main_1)
}
