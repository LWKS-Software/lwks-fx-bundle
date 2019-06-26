// @Maintainer jwrl
// @Released 2018-12-28
// @Author jwrl
// @Created 2018-11-10
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Split_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Split.mp4

/**
This is really the classic barn door effect, but since a wipe with that name already exists
in Lightworks another name had to be found.  This version moves the separated delta key
halves apart rather than just wipe them off.
*/

//-----------------------------------------------------------------------------------------//
// User effect BarnDoorSplit_Adx.fx
//
// Modified 28 Dec 2018 by user jwrl:
// Reformatted the effect description for markup purposes.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Barn door split (delta)";
   string Category    = "Mix";
   string SubCategory = "Wipe transitions";
   string Notes       = "Separates foreground from background then splits it and separates the halves horizontally or vertically";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Title : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state { Texture = <Fg>; };
sampler s_Background = sampler_state { Texture = <Bg>; };

sampler s_Title = sampler_state
{
   Texture   = <Title>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Progress";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Horizontal join in,Horizontal split out,Vertical join in,Vertical split out";
> = 0;

float Split
<
   string Description = "Split centre";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float KeyGain
<
   string Description = "Key adjust";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler s_Sampler, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   return tex2D (s_Sampler, uv);
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen_I (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Bgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_keygen_O (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float3 Fgd = tex2D (s_Foreground, xy1).rgb;
   float3 Bgd = tex2D (s_Background, xy2).rgb;

   float kDiff = distance (Bgd.g, Fgd.g);

   kDiff = max (kDiff, distance (Bgd.r, Fgd.r));
   kDiff = max (kDiff, distance (Bgd.b, Fgd.b));

   return float4 (Fgd, smoothstep (0.0, KeyGain, kDiff));
}

float4 ps_horiz_I (float2 uv : TEXCOORD1) : COLOR
{
   float range = (1.0 - Amount) * max (Split, 1.0 - Split);

   float2 xy2 = float2 (range, 0.0);
   float2 xy1 = uv - xy2;

   xy2 += uv;

   float4 Fgd = ((xy1.x < Split) && (xy2.x > Split)) ? EMPTY
              : (uv.x > Split) ? fn_tex2D (s_Title, xy1) : fn_tex2D (s_Title, xy2);

   return lerp (tex2D (s_Foreground, uv), Fgd, Fgd.a);
}

float4 ps_horiz_O (float2 uv : TEXCOORD1) : COLOR
{
   float range = Amount * max (Split, 1.0 - Split);

   float2 xy2 = float2 (range, 0.0);
   float2 xy1 = uv - xy2;

   xy2 += uv;

   float4 Fgd = ((xy1.x < Split) && (xy2.x > Split)) ? EMPTY
              : (uv.x > Split) ? fn_tex2D (s_Title, xy1) : fn_tex2D (s_Title, xy2);

   return lerp (tex2D (s_Background, uv), Fgd, Fgd.a);
}

float4 ps_vert_I (float2 uv : TEXCOORD1) : COLOR
{
   float split = 1.0 - Split;
   float range = (1.0 - Amount) * max (Split, split);

   float2 xy2 = float2 (0.0, range);
   float2 xy1 = uv - xy2;

   xy2 += uv;

   float4 Fgd = ((xy1.y < split) && (xy2.y > split)) ? EMPTY
              : (uv.y > split) ? fn_tex2D (s_Title, xy1) : fn_tex2D (s_Title, xy2);

   return lerp (tex2D (s_Foreground, uv), Fgd, Fgd.a);
}

float4 ps_vert_O (float2 uv : TEXCOORD1) : COLOR
{
   float split = 1.0 - Split;
   float range = Amount * max (Split, split);

   float2 xy2 = float2 (0.0, range);
   float2 xy1 = uv - xy2;

   xy2 += uv;

   float4 Fgd = ((xy1.y < split) && (xy2.y > split)) ? EMPTY
              : (uv.y > split) ? fn_tex2D (s_Title, xy1) : fn_tex2D (s_Title, xy2);

   return lerp (tex2D (s_Background, uv), Fgd, Fgd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Hsplit_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2
   { PixelShader = compile PROFILE ps_horiz_I (); }
}

technique Hsplit_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2
   { PixelShader = compile PROFILE ps_horiz_O (); }
}

technique Vsplit_I
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_I (); }

   pass P_2
   { PixelShader = compile PROFILE ps_vert_I (); }
}

technique Vsplit_O
{
   pass P_1
   < string Script = "RenderColorTarget0 = Title;"; >
   { PixelShader = compile PROFILE ps_keygen_O (); }

   pass P_2
   { PixelShader = compile PROFILE ps_vert_O (); }
}

