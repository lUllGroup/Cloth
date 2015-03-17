//@author: vux
//@help: template for standard shaders
//@tags: template
//@credits: 

Texture2D tfront <string uiname="Texture 1";>;
Texture2D tback <string uiname="Texture 2";>;

SamplerState g_samLinear
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};
struct particle
{
	float3 pos;
	float3 test;
	bool pinched;

};
StructuredBuffer<particle> pData;

cbuffer cbPerDraw : register( b0 )
{
	float4x4 tVP : VIEWPROJECTION;	
};

cbuffer cbPerObj : register( b1 )
{
	float4x4 tW : WORLD;
	float4 cAmb <bool color=true;String uiname="Color";> = { 1.0f,1.0f,1.0f,1.0f };
};

struct VS_IN
{
	float4 PosO : POSITION;
	float4 TexCd : TEXCOORD0;

};

struct vs2ps
{
    float4 PosWVP: SV_POSITION;
    float4 TexCd: TEXCOORD0;
	//bool front : SV_IsFrontFace;
	
};

struct psIn
{
    float4 PosWVP: SV_POSITION;
    float4 TexCd: TEXCOORD0;
	bool front : SV_IsFrontFace;
};

vs2ps VS(VS_IN input,uint id : SV_VertexID)
{
    vs2ps output;
    //output.PosWVP  = mul(input.PosO,mul(tW,tVP));
	output.PosWVP = float4(pData[id].pos.x,pData[id].pos.y,pData[id].pos.z,1);
    output.PosWVP =mul(output.PosWVP,mul(tW,tVP));
	output.TexCd = input.TexCd;
    return output;
}



float4 PS(psIn In): SV_Target
{
//    float4 col = tfront.Sample(g_samLinear,In.TexCd.xy) * cAmb;
//    return col;
	
	float4 cfront = tfront.Sample(g_samLinear,In.TexCd.xy);
	float4 cback = tback.Sample(g_samLinear,In.TexCd.xy);
	//Use different color depending on face side
    return In.front ? cfront : cback;
	
	
	
}





technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}




