Texture2D tex0 <string uiname="Texture";>;

SamplerState s0 <bool visible=false;string uiname="Sampler";>
{Filter=MIN_MAG_MIP_LINEAR;AddressU=WRAP;AddressV=WRAP;};

struct particle
{
	float3 pos;
	float3 oldPos;
	bool pinched;
	float3 outputBuffer;
};


StructuredBuffer<particle> pData;
cbuffer cbControls:register(b0){
	float4x4 tWVP:WORLDVIEWPROJECTION;
	float4x4 tVP:VIEWPROJECTION;
	float4x4 tW:WORLD;
	float4x4 tV:VIEW;
	float4x4 tP:PROJECTION;
	float4x4 tWI:WORLDINVERSE;
	float4x4 tVI:VIEWINVERSE;
	float4x4 tPI:PROJECTIONINVERSE;
	float4x4 tWIT:WORLDINVERSETRANSPOSE;
	float4 Color <bool color=true;> = {1.0,1.0,1.0,1.0};
	float4x4 tTex <bool uvspace=true;string uiname="Texture Transform";>;
};

struct VS_IN{
	float4 PosO:POSITION;
	float4 TexCd:TEXCOORD0;
	float3 Norm:NORMAL0;
};

struct VS_OUT{
	float4 PosWVP:SV_POSITION;
	float4 TexCd:TEXCOORD0;
	float4 PosW:TEXCOORD1;
	float3 Norm:NORMAL0;
};

VS_OUT VS(VS_IN In,uint id : SV_VertexID){
	
	VS_OUT Out=(VS_OUT)0;
	float4 PosW=In.PosO;
	//PosW=mul(PosW,tW);
	
	PosW = float4(pData[id].pos.x,pData[id].pos.y,pData[id].pos.z,1);
  
	//Out.PosW = float4(pData[id].pos.x,pData[id].pos.y,pData[id].pos.z,1);
    Out.PosW=PosW;
	Out.PosWVP=mul(PosW,tVP);
	
	//Out.PosWVP = float4(pData[id].pos.x,pData[id].pos.y,pData[id].pos.z,1);
    //Out.PosWVP =mul(Out.PosWVP,mul(tW,tVP));

	Out.Norm=mul(In.Norm,(float3x3)tWIT);
	Out.TexCd=mul(In.TexCd,tTex);
	return Out;

//	    VS_OUT output;
//    //output.PosWVP  = mul(input.PosO,mul(tW,tVP));
//	output.PosWVP = float4(pData[id].pos.x,pDatao[id].pos.y,pData[id].pos.z,1);
//    output.PosWVP =mul(output.PosWVP,mul(tW,tVP));
//	output.PosW = output.PosWVP;
//	output.TexCd = In.TexCd;
//	output.Norm=mul(In.Norm,(float3x3)tWIT);
//
//    return output;
}


float3x3 lookat(float3 dir,float3 up=float3(0,1,0)){float3 z=normalize(dir);float3 x=normalize(cross(up,z));float3 y=normalize(cross(z,x));return float3x3(x,y,z);} 

float Thickness=0.05;
float TriangleSize=1;
bool FlatNormals=0;
#define TUBERESO 4

[maxvertexcount((TUBERESO+1)*2*3)]
void GS(triangle VS_OUT In[3], inout TriangleStream<VS_OUT> GSOut)
{
	VS_OUT o;
	float3 p=(In[0].PosW.xyz+In[1].PosW.xyz+In[2].PosW.xyz)/3.;
	
	for(uint j=0;j<3;j++){
		float3 p0=(In[(j+0)%3].PosW.xyz-p)*TriangleSize+p;
		float3 p1=(In[(j+1)%3].PosW.xyz-p)*TriangleSize+p;
		o=In[(j+0)%3];
		float3 n=normalize(In[(j+0)%3].Norm+In[(j+1)%3].Norm);
		float3x3 lkt=lookat(p1-p0,n);
		for(int i=0;i<=TUBERESO;i++){
			float3 off=float3(sin((-(float)i/TUBERESO+.125+float2(.25,0))*acos(-1)*2),0);
			off=mul(off*Thickness,lkt);
			o.Norm=normalize(off);
			o.PosW.xyz=p0+off;
			o.PosWVP=mul(o.PosW,tVP);
			GSOut.Append(o);
			o.PosW.xyz=p1+off;
			o.PosWVP=mul(o.PosW,tVP);
			GSOut.Append(o);
		}
		GSOut.RestartStrip();
	}
}

float4 PS_NORMAL(VS_OUT In):SV_Target{
	if(FlatNormals)In.Norm=normalize(cross(ddx(In.PosW.xyz),ddy(In.PosW.xyz)));
	float4 c=float4(normalize(In.Norm)*0.5+0.5,1);
	return c;
}

float4 PS_CONST(VS_OUT In):SV_Target{
	float4 c=tex0.Sample(s0,In.TexCd.xy);
	c*=Color;
	return c;
}
float4 PS_SHADE(VS_OUT In):SV_Target{
	float4 c=tex0.Sample(s0,In.TexCd.xy);
	float3 View=normalize(In.PosW.xyz-tVI[3].xyz);
	In.Norm=normalize(In.Norm);
	if(FlatNormals)In.Norm=normalize(cross(ddx(In.PosW.xyz),ddy(In.PosW.xyz)));
	float3 vRef=normalize(reflect(View,In.Norm));
	float g=saturate(-dot(View,In.Norm));
	c.rgb*=g;
	c*=Color;
	return c;
}
technique10 Normal{
	pass P0{
		SetVertexShader(CompileShader(vs_5_0,VS()));
		SetGeometryShader(CompileShader(gs_5_0,GS()));
		SetPixelShader(CompileShader(ps_5_0,PS_NORMAL()));
	}
}
technique10 Constant{
	pass P0{
		SetVertexShader(CompileShader(vs_5_0,VS()));
		SetGeometryShader(CompileShader(gs_5_0,GS()));
		SetPixelShader(CompileShader(ps_5_0,PS_CONST()));
	}
}
technique10 Shade{
	pass P0{
		SetVertexShader(CompileShader(vs_5_0,VS()));
		SetGeometryShader(CompileShader(gs_5_0,GS()));
		SetPixelShader(CompileShader(ps_5_0,PS_SHADE()));
	}
}



