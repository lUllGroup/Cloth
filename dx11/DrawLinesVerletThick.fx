//@author: vux
//@help: standard constant shader
//@tags: color
//@credits:

float4x4 tV : VIEW;
float4x4 tVP : VIEWPROJECTION;
float4x4 tVI : VIEWINVERSE;
float4x4 tWVP : WORLDVIEWPROJECTION;

Texture2D texture2d;

float4 c <bool color=true;> = 1;
float velColMult = 1;
float alpha;
bool drawRadius;
bool drawCollision;

struct particle
{
	float3 pos;
	float3 vel;
	float3 oldPos;
	float3 acc;

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
	//float4 p: POSITION;
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
	float3 v = pData[input.iv].vel;
	//	radius = pData[input.iv].radius;
	
	Out.PosWVP = float4(p,1);// mul(float4(po.xyz,1),tVP);
	Out.Vcol = float4(saturate(v * velColMult)+0.5,1);
	Out.iv2 = input.iv;
	
	return Out;
}

float1 mapRange(float1 value, float from1,float to1,float from2, float to2){
	
	return  (value - from1) / (to1 - from1) * (to2 - from2) + from2;
}


[maxvertexcount(4)]
void GS(line vs2ps input[2], inout TriangleStream<vs2ps> SpriteStream)
{
	vs2ps output;
	
	//
	// Emit two new triangles
	//
	output.iv2 = input[0].iv2;
	
	float3 tangent = input[1].PosWVP.xyz - input[0].PosWVP.xyz;
//	if(length(tangent) >= 0.3){
//		return;
//	}
	
	float3 normal = normalize(float3(tangent.z, -tangent.x, 0));
	normal *= 0.1;

	tangent *= radius*0.6;
	
	for(int k=0; k<2; k++)
	{
		for(int i=0; i<2; i++)
		{
			
			float3 position;
			

			
			if(i == 0){
				position = -normal * radius;
				position = mul( position, (float3x3)tVI ) + (input[1].PosWVP.xyz + tangent);
			}
			
			
			if(i == 1){
				position = normal * radius;
				position = mul( position, (float3x3)tVI ) + (input[1].PosWVP.xyz + tangent);
			}
			
			
			
			float3 norm = mul(float3(0,0,-1),(float3x3)tVI );
			
			
			
			output.PosWVP = mul( float4(position,1.0), tWVP );
			output.TexCd = g_texcoords[i];
			output.Vcol = input[0].Vcol;
			
			
			SpriteStream.Append(output);
		}
		for(int j=2; j<4; j++)
		{
			
			float3 position;
			
			
			if(j == 2){
				position = -normal * radius;
				position = mul( position, (float3x3)tVI ) + (input[0].PosWVP.xyz - tangent);
			}
			
			
			if(j == 3){
				position = normal * radius;
				position = mul( position, (float3x3)tVI ) + (input[0].PosWVP.xyz -+ tangent);
			}
			
			
		
			
			float3 norm = mul(float3(0,0,-1),(float3x3)tVI );
			

			output.PosWVP = mul( float4(position,1.0), tWVP );		
			output.TexCd = g_texcoords[j];
			output.Vcol = input[0].Vcol;
			
			
			SpriteStream.Append(output);
		}
	}
	SpriteStream.RestartStrip();
}


float4 PS_Tex(vs2ps In): SV_Target
{
	
	float4 col = float4(1,1,1,alpha);
	
	
	
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

technique10 VelocityColor
{
	pass P0
	{
		
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( CompileShader( gs_4_0, GS() ) );
	}
}



