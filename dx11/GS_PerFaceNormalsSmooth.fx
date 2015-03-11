float4x4 tW : WORLD;
float4x4 tVP : VIEWPROJECTION;
float4x4 tWVP : WORLDVIEWPROJECTION;
float4x4 tWV : WORLDVIEW;
float4x4 tVI:VIEWINVERSE;
float4 Color <bool color=true;> = {1.0,1.0,1.0,1.0};

Texture2D tex0 <string uiname="Texture";>;
SamplerState s0 <bool visible=false;string uiname="Sampler";>
{Filter=MIN_MAG_MIP_LINEAR;AddressU=WRAP;AddressV=WRAP;};


struct vsin
{
	float4 PosO:POSITION;
	float4 TexCd:TEXCOORD0;
	float3 Norm:NORMAL0;
};

struct vs2gs
{
    float4 PosWVP:SV_POSITION;
	float4 TexCd:TEXCOORD0;
	float4 PosW:TEXCOORD1;
	float3 Norm:NORMAL0;
};

struct psIn
{
    float4 PosWVP:SV_POSITION;
	float4 TexCd:TEXCOORD0;
	float4 PosW:TEXCOORD1;
	float3 Norm:NORMAL0;
};

vs2gs VS(vsin input)
{
	//Passtrough in that case, since we will process in gs
	
	//We don't need normals we will calculate them on the fly
	vs2gs output;
	
	float4 PosW=input.PosO;
	//PosW=mul(PosW,tW);
  
	output.PosW = PosW;
	output.PosWVP =input.PosO;
	output.Norm=input.Norm;
	output.TexCd=input.TexCd;
    return output;
}


float3x3 lookat(float3 dir,float3 up=float3(0,1,0)){float3 z=normalize(dir);float3 x=normalize(cross(up,z));float3 y=normalize(cross(z,x));return float3x3(x,y,z);} 

float eps : EPSILON = 0.000001f;
float Thickness=0.05;
float TriangleSize=1;
bool FlatNormals=0;
#define TUBERESO 4

[maxvertexcount((TUBERESO+1)*2*3)]
//[maxvertexcount(3)]
void GS(triangle vs2gs input[3], inout TriangleStream<psIn> gsout)
{
	psIn o;
	float3 p=(input[0].PosW.xyz + input[1].PosW.xyz + input[2].PosW.xyz)/3.;
	
	for(uint j=0;j<3;j++){
		float3 p0=(input[(j+0)%3].PosW.xyz-p)*TriangleSize+p;
		float3 p1=(input[(j+1)%3].PosW.xyz-p)*TriangleSize+p;
		o=input[(j+0)%3];
		float3 n=normalize(input[(j+0)%3].Norm+input[(j+1)%3].Norm);
		float3x3 lkt=lookat(p1-p0,n);
		for(int i=0;i<=TUBERESO;i++){
			float3 off=float3(sin((-(float)i/TUBERESO+.125+float2(.25,0))*acos(-1)*2),0);
			off=mul(off*Thickness,lkt);
			o.Norm=normalize(off);
			o.PosW.xyz=p0+off;
			o.PosWVP=mul(o.PosW,tVP);
			gsout.Append(o);
			o.PosW.xyz=p1+off;
			o.PosWVP=mul(o.PosW,tVP);
			gsout.Append(o);
		}
		gsout.RestartStrip();
	}
	
}//Get triangle face direction
//	float3 f1 = input[1].pos.xyz - input[0].pos.xyz;
//    float3 f2 = input[2].pos.xyz - input[0].pos.xyz;
    
	//Compute flat normal
//	float3 norm = normalize(cross(f1, f2));

	//Convert into view space
//	float3 normv = mul(float4(norm,0),tWV).xyz;
//	normv = normalize(normv);
	
//	o.norm = float4(normalize(normv),1);

	//Transform triangles
//	o.pos = mul(input[0].pos,tWVP);
//	gsout.Append(o);
	
//	o.pos = mul(input[1].pos,tWVP);
//	gsout.Append(o);
	
//	o.pos = mul(input[2].pos,tWVP);
//	gsout.Append(o);
//}

float4 PS(psIn input): SV_Target
{
	float4 c=tex0.Sample(s0,input.TexCd.xy);
	float3 View=normalize(input.PosW.xyz-tVI[3].xyz);
	input.Norm=normalize(input.Norm);
	if(FlatNormals)input.Norm=normalize(cross(ddx(input.PosW.xyz),ddy(input.PosW.xyz)));
	float3 vRef=normalize(reflect(View,input.Norm));
	float g=saturate(-dot(View,input.Norm));
	c.rgb*=g;
	c*=Color;
	return c;
}


technique10 RenderFlat
{
	pass P0
	{
		SetVertexShader( CompileShader( vs_4_0, VS() ) );
		SetGeometryShader( CompileShader( gs_4_0, GS() ) );
		SetPixelShader( CompileShader( ps_4_0, PS() ) );
	}
}





