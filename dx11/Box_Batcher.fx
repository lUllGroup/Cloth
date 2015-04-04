float4x4 tVP: VIEWPROJECTION;
float4x4 tV : VIEW;

ByteAddressBuffer sobuffer;
Texture2D texRGBDepth <string uiname="RGBDepth";>;

SamplerState sPoint : IMMUTABLE
{
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Border;
    AddressV = Border;
};


struct vsIn
{
	float4 pos : POSITION;
	float3 norm : NORMAL;
	uint ii : SV_InstanceID;
};

struct psIn
{
    float4 pos : SV_POSITION;
	//float2 uv : TEXCOORD0;
	float3 nv : TEXCOORD0;
}; 

psIn VS(vsIn input)
{
	psIn output;
	
	//Stride is 24, as 12 for position and 12 for normals, we can't use StreamOut as structured bufffer,
	//So we use byteaddress
	float x = asfloat(sobuffer.Load(input.ii * 24));
	float y = asfloat(sobuffer.Load(input.ii * 24 + 4));
	float z = asfloat(sobuffer.Load(input.ii * 24 + 8));
	
	float3 center = float3(x,y,z);
	
	//Move Box
	
	if(length(center) > 4){
		center += input.pos.xyz;
	}

	

	
    output.pos  = mul(float4(center,1.0f),tVP);

	output.nv = mul(float4(input.norm,0.0f),tV).xyz;
	
	// pass texcoords for color lookup
	//output.uv = float2(asfloat(sobuffer.Load(input.ii * 24 + 16)), asfloat(sobuffer.Load(input.ii * 24 + 20)));
	
    return output;
}

float4 PS(psIn input): SV_Target
{
   return float4(normalize(input.nv)*0.5f+0.5f,1.0f);
	//return texRGBDepth.SampleLevel(sPoint,input.uv,0);
}


technique10 Constant
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}



 
