//@author: vux
//@help: standard constant shader
//@tags: color
//@credits: 

float4x4 tV : VIEW;
float4x4 tVP : VIEWPROJECTION;
float4x4 tVI : VIEWINVERSE;
Texture2D texture2d;

float4 c <bool color=true;> = 1;
float velColMult = 1;
float alpha;
float pCount;
float connectorCount;

struct particle
{
float3 pos;
	float3 oldPos;
	bool pinched;
	float3 outputBuffer;

};
StructuredBuffer<particle> pData;

float radius = 0.05f;
 
    float3 g_positions[4]:IMMUTABLE =
    {
        float3( -1, 1, 0 ),
        float3( 1, 1, 0 ),
        float3( -1, -1, 0 ),
        float3( 1, -1, 0 ),
    };
    float2 g_texcoords[4]:IMMUTABLE = 
    { 
        float2(0,1), 
        float2(1,1),
        float2(0,0),
        float2(1,0),
    };



SamplerState g_samLinear : IMMUTABLE
{
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

struct VS_IN
{
	uint iv : SV_VertexID;

};

struct vs2ps
{
    float4 PosWVP: SV_POSITION ;	
	float2 TexCd : TEXCOORD0 ;
	float4 Vcol : COLOR ;
	uint iv2 : PrimitiveID;
};

vs2ps VS(VS_IN input)
{
    //inititalize all fields of output struct with 0
    vs2ps Out = (vs2ps)0;
	
	float3 p = pData[input.iv].pos;
//	float3 v = pData[input.iv].vel;
	
    Out.PosWVP = float4(p,1);// mul(float4(po.xyz,1),tVP);
	

	Out.Vcol = 0;
	Out.iv2 = input.iv;
	
    return Out;
}

[maxvertexcount(2)]
void GS(line vs2ps input[2], inout LineStream<vs2ps> SpriteStream)
{
    vs2ps output;
    
    //
    // Emit two new triangles
    //
    for(int i=0; i<2; i++)
    {
        float3 position = g_positions[i]*radius;
    	position = input[i].PosWVP.xyz;
    	float3 norm = mul(float3(0,0,-1),(float3x3)tVI );
        output.PosWVP = mul( float4(position,1.0), tVP );
        
        output.TexCd = g_texcoords[i];	
        output.Vcol = input[i].Vcol;
    	output.iv2 = input[i].iv2;
        SpriteStream.Append(output);
    }
    SpriteStream.RestartStrip();
}



float4 PS_Tex(vs2ps In): SV_Target
{

	float4 col;
	uint division = pCount / connectorCount;
	
	if((In.iv2+1) % division == 0){
		col = float4(1,0,1,0);
		col.a *= alpha;	
	} else {
		//col = float4(1,1,1,1);
		col = c;
		col.a *= alpha;	
		
	}
	
    return col;
}

technique10 Constant
{
	pass P0
	{
		
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( CompileShader( gs_4_0, GS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS_Tex() ) );
	}
}




