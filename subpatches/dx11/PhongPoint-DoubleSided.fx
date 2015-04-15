//@author: vvvv group
//@help: basic pixel based lightning with point light
//@tags: shading, blinn
//@credits:

// -----------------------------------------------------------------------------
// PARAMETERS:
// -----------------------------------------------------------------------------

//transforms
float4x4 tW: WORLD;        //the models world matrix
float4x4 tV: VIEW;         //view matrix as set via Renderer (DX9)
float4x4 tWV: WORLDVIEW;
float4x4 tWVP: WORLDVIEWPROJECTION;
float4x4 tP: PROJECTION;   //projection matrix as set via Renderer (DX9)
float4x4 tWIT: WORLDINVERSETRANSPOSE;

#include "PhongPoint.fxh"

Texture2D tfront <string uiname="TextureFront";>;
Texture2D tback <string uiname="TextureBack";>;
Texture2D tZ <string uiname="TextureZ";>;

SamplerState g_samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

float4x4 tTex <bool uvspace=true; string uiname="Texture Transform";>;
float4x4 tTex2 <bool uvspace=true; string uiname="Texture Transform Z";>;

float4x4 tColor <string uiname="Color Transform";>;

float zPower;
int zTex = 0;

struct vs2ps
{
    float4 PosWVP: SV_POSITION;
    float4 TexCd : TEXCOORD0;
    float3 LightDirV: TEXCOORD1;
    float3 NormV: TEXCOORD2;
    float3 ViewDirV: TEXCOORD3;
    float3 PosW: TEXCOORD4;
	
};

// -----------------------------------------------------------------------------
// VERTEXSHADERS
// -----------------------------------------------------------------------------

vs2ps VS(
    float4 PosO: POSITION,
    float3 NormO: NORMAL,
    float4 TexCd : TEXCOORD0)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;

    Out.PosW = mul(PosO, tW).xyz;

    //inverse light direction in view space
    float3 LightDirW = normalize(lPos - Out.PosW);
    Out.LightDirV = mul(float4(LightDirW,0.0f), tV).xyz;
    
    //normal in view space
    Out.NormV = normalize(mul(mul(NormO, (float3x3)tWIT),(float3x3)tV).xyz);

    //position (projected)
    Out.PosWVP  = mul(PosO, tWVP);
    Out.TexCd = mul(TexCd, tTex);
    Out.ViewDirV = -normalize(mul(PosO, tWV).xyz);
    return Out;
}

// -----------------------------------------------------------------------------
// PIXELSHADERS:
// -----------------------------------------------------------------------------
float Alpha <float uimin=0.0; float uimax=1.0;> = 1;

#define bld(op,c0,c1) float4(lerp((c0*c0.a+c1*c1.a*(1-c0.a))/saturate(c0.a+c1.a*(1-c0.a)),(op),c0.a*c1.a).rgb,saturate(c0.a+c1.a*(1-c0.a)))


float4 PS(vs2ps In, bool front : SV_IsFrontFace): SV_Target
{
   float4 tTexZ =  mul(In.TexCd, tTex2);
	float4 tTex1 = mul(In.TexCd, tTex);
	//In.TexCd = mul(In.TexCd, tTex);
	float4 col;
	
	if(zTex == 1){
		
	
	//	float4 c0=tfront.Sample(g_samLinear,In.TexCd.xy);
	//	float4 c1=tZ.Sample(g_samLinear,In.TexCd.xy)*float4(1,1,1,saturate(-In.Pos.z*zPower));
	//  float4 col=bld(max(c0,c1),c0,c1);
		
		
		float4 c0=tfront.Sample(g_samLinear,In.TexCd.xy);
		
		In.TexCd = tTexZ;
		
		float4 c1=tZ.Sample(g_samLinear,In.TexCd.xy)*float4(1,1,1,saturate((-In.PosW.z-.05)*zPower));
		
		In.TexCd = tTex1;
		//col = c0;
		//if(-In.Pos.z*zPower > 1){
			col=bld(lerp(c0,c1,saturate((-In.PosW.z-.05)*zPower)),c1,c0);
		//}	    
		
		
	   	col.rgb *= PhongPoint(In.PosW, In.NormV, In.ViewDirV, In.LightDirV, 1).rgb;
		
		col.a *= Alpha;
		
		//col += In.Pos.z*10;
		
	} else {
		In.TexCd = tTex1;
		col = tfront.Sample(g_samLinear, In.TexCd.xy);
		col.rgb *= PhongPoint(In.PosW, In.NormV, In.ViewDirV, In.LightDirV, 1).rgb;
		col.a *= Alpha;
	}
	
	
	float4 col2 = tback.Sample(g_samLinear, In.TexCd.xy);
    col2.rgb *= PhongPoint(In.PosW, In.NormV, In.ViewDirV, In.LightDirV, .5).rgb;
	
    col2.a *= Alpha;

	
//	float4 cfront = tfront.Sample(g_samLinear,In.TexCd.xy);
//	float4 cback = tback.Sample(g_samLinear,In.TexCd.xy);
//	//Use different color depending on face side
    return front ? mul(col, tColor) : mul(col2, tColor);

    //return mul(col, tColor);
}


// -----------------------------------------------------------------------------
// TECHNIQUES:
// -----------------------------------------------------------------------------
technique10 TPhongPoint
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}

