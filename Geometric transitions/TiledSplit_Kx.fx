// @Maintainer jwrl
// @Released 2021-07-24
// @Author jwrl
// @Created 2021-07-24
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Tiles_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_Tiles.mp4

/**
 This is a delta key and alpha transition that splits a keyed image into tiles then blows
 them apart or materialises the key from tiles.  It's a combination of two previous effects,
 TileSplit_Ax and TileSplit_Adx.
*/

//-----------------------------------------------------------------------------------------//
// Lightworks user effect TiledSplit_Kx.fx
//
// Version history:
//
// Rewrite 2021-07-24 jwrl.
// Rewrite of the original effect to support LW 2021 resolution independence.
// Build date does not reflect upload date because of forum upload problems.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Tiled split (keyed)";
   string Category    = "Mix";
   string SubCategory = "Geometric transitions";
   string Notes       = "Splits a blended foreground into tiles and blows them apart";
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

#define Overflow(XY) (any (XY < 0.0) || any (XY > 1.0))
#define GetPixel(SHADER,XY)  (Overflow(XY) ? EMPTY : tex2D(SHADER, XY))

#define FACTOR 100
#define OFFSET 1.2

float _OutputAspectRatio;
float _Progress;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

DefineInput (Fg, s_Foreground);
DefineInput (Bg, s_Background);

DefineTarget (Super, s_Super);
DefineTarget (Tiles, s_Tiles);

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int Source
<
   string Description = "Source";
   string Enum = "Extracted foreground (delta key),Crawl/Roll/Title/Image key,Video/External image";
> = 0;

int SetTechnique
<
   string Description = "Transition position";
   string Enum = "At start if delta key folded,At start of clip,At end of clip";
> = 1;

bool CropEdges
<
   string Description = "Crop effect to background";
> = false;

float Width
<
   string Group = "Tile size";
   string Description = "Width";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

float Height
<
   string Group = "Tile size";
   string Description = "Height";
   float MinVal       = 0.0;
   float MaxVal       = 1.0;
> = 0.5;

float KeyGain
<
   string Description = "Key trim";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_keygen_F (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      float4 Bgnd = GetPixel (s_Background, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb = Bgnd.rgb * Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_keygen (float2 uv1 : TEXCOORD1, float2 uv2 : TEXCOORD2) : COLOR
{
   float4 Fgnd = GetPixel (s_Foreground, uv1);

   if (Source == 0) {
      float4 Bgnd = GetPixel (s_Background, uv2);

      Fgnd.a = smoothstep (0.0, KeyGain, distance (Bgnd.rgb, Fgnd.rgb));
      Fgnd.rgb *= Fgnd.a;
   }
   else if (Source == 1) {
      Fgnd.a = pow (Fgnd.a, 0.375 + (KeyGain / 2.0));
      Fgnd.rgb /= Fgnd.a;
   }

   return (Fgnd.a == 0.0) ? Fgnd.aaaa : Fgnd;
}

float4 ps_horiz_I (float2 uv : TEXCOORD3) : COLOR
{
   float dsplc  = (OFFSET - Height) * FACTOR / _OutputAspectRatio;
   float offset = floor (uv.y * dsplc);

   offset = ceil (frac (offset / 2.0)) * 2.0;
   offset = (1.0 - offset) * (1.0 - Amount);

   return GetPixel (s_Super, uv + float2 (offset, 0.0));
}

float4 ps_horiz_O (float2 uv : TEXCOORD3) : COLOR
{
   float dsplc  = (OFFSET - Height) * FACTOR / _OutputAspectRatio;
   float offset = floor (uv.y * dsplc);

   offset = ceil (frac (offset / 2.0)) * 2.0;
   offset = (offset - 1.0) * Amount;

   return GetPixel (s_Super, uv + float2 (offset, 0.0));
}

float4 ps_main_F (float2 uv1 : TEXCOORD1, float2 uv3 : TEXCOORD3) : COLOR
{
   float dsplc  = (OFFSET - Width) * FACTOR;
   float offset = floor (uv3.x * dsplc);

   offset = (1.0 - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);

   float4 Fgnd = GetPixel (s_Tiles, uv3 + float2 (0.0, offset / _OutputAspectRatio));

   if (CropEdges && Overflow (uv1)) Fgnd = EMPTY;

   return lerp (GetPixel (s_Foreground, uv1), Fgnd, Fgnd.a);
}

float4 ps_main_I (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float dsplc  = (OFFSET - Width) * FACTOR;
   float offset = floor (uv3.x * dsplc);

   offset = (1.0 - (ceil (frac (offset / 2.0)) * 2.0)) * (1.0 - Amount);

   float4 Fgnd = GetPixel (s_Tiles, uv3 + float2 (0.0, offset / _OutputAspectRatio));

   if (CropEdges && Overflow (uv2)) Fgnd = EMPTY;

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a);
}

float4 ps_main_O (float2 uv2 : TEXCOORD2, float2 uv3 : TEXCOORD3) : COLOR
{
   float dsplc  = (OFFSET - Width) * FACTOR;
   float offset = floor (uv3.x * dsplc);

   offset  = ((ceil (frac (offset / 2.0)) * 2.0) - 1.0) * Amount;

   float4 Fgnd = GetPixel (s_Tiles, uv3 + float2 (0.0, offset / _OutputAspectRatio));

   if (CropEdges && Overflow (uv2)) Fgnd = EMPTY;

   return lerp (GetPixel (s_Background, uv2), Fgnd, Fgnd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique TiledSplit_Kx_F
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen_F)
   pass P_2 < string Script = "RenderColorTarget0 = Tiles;"; > ExecuteShader (ps_horiz_I)
   pass P_3 ExecuteShader (ps_main_F)
}

technique TiledSplit_Kx_I
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Tiles;"; > ExecuteShader (ps_horiz_I)
   pass P_3 ExecuteShader (ps_main_I)
}

technique TiledSplit_Kx_O
{
   pass P_1 < string Script = "RenderColorTarget0 = Super;"; > ExecuteShader (ps_keygen)
   pass P_2 < string Script = "RenderColorTarget0 = Tiles;"; > ExecuteShader (ps_horiz_O)
   pass P_3 ExecuteShader (ps_main_O)
}
