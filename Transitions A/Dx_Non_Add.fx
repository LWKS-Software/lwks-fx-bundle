// @Maintainer jwrl
// @ReleaseDate 2018-03-31
//--------------------------------------------------------------//
// Lightworks user effect Dx_Non_Add.fx
//
// Created by LW user jwrl 8 March 2018
// @Author jwrl
// @CreationDate "8 March 2018"
//
// This effect emulates the classic analog vision mixer non-add
// mix.  This version replaces the 3 January 2017 version.  The
// algorithm used is more efficient than the earlier effect.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Non-additive mix";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Fg;
texture Bg;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler FgSampler = sampler_state { Texture = <Fg>; };

sampler BgSampler = sampler_state { Texture = <Bg>; };

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Amount
<
   string Description = "Amount";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

//--------------------------------------------------------------//
// Definitions and declarations
//--------------------------------------------------------------//

#define EMPTY 0.0.xxxx

//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = lerp (tex2D (FgSampler, xy1), EMPTY, Amount);
   float4 Bgd = lerp (EMPTY, tex2D (BgSampler, xy2), Amount);
   float4 Mix = max (Bgd, Fgd);

   float Gain = (1.0 - abs (Amount - 0.5)) * 2.0;

   return saturate (Mix * Gain);
}

//--------------------------------------------------------------//
// Technique
//--------------------------------------------------------------//

technique Non_Add
{
   pass P_1
   { PixelShader = compile PROFILE ps_main (); }
}

