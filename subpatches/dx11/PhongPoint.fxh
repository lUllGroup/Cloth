//light properties
float3 lPos <string uiname="Light Position";> = {0, 5, -2};       //light position in world space
float lAtt0 <String uiname="Light Attenuation 0"; float uimin=0.0;> = 0;
float lAtt1 <String uiname="Light Attenuation 1"; float uimin=0.0;> = 0.3;
float lAtt2 <String uiname="Light Attenuation 2"; float uimin=0.0;> = 0;
float lAtt02 <String uiname="Light Attenuation 02"; float uimin=0.0;> = 0;
float lAtt12 <String uiname="Light Attenuation 12"; float uimin=0.0;> = 0.3;
float lAtt22 <String uiname="Light Attenuation 22"; float uimin=0.0;> = 0;
float4 lAmb1  <bool color=true; String uiname="Ambient Color";>  = {0.15, 0.15, 0.15, 1};
float4 lDiff1 <bool color=true; String uiname="Diffuse Color";>  = {0.85, 0.85, 0.85, 1};
float4 lSpec1 <bool color=true; String uiname="Specular Color";> = {0.35, 0.35, 0.35, 1};
float4 lAmb2  <bool color=true; String uiname="Ambient Color 2";>  = {0.15, 0.15, 0.15, 1};
float4 lDiff2 <bool color=true; String uiname="Diffuse Color 2";>  = {0.85, 0.85, 0.85, 1};
float4 lSpec2 <bool color=true; String uiname="Specular Color 2";> = {0.35, 0.35, 0.35, 1};

float lPower <String uiname="Power"; float uimin=0.0;> = 25.0;     //shininess of specular highlight
float lRange <String uiname="Light Range"; float uimin=0.0;> = 10.0;

//phong point function
float4 PhongPoint(float3 PosW, float3 NormV, float3 ViewDirV, float3 LightDirV, float att2Factor)
{

    float d = distance(PosW, lPos);
    float atten = 0;
	float Att0 = lAtt0;
	float Att1 = lAtt1;
	float Att2 = lAtt2;
	
	float4 lAmb =  lAmb1;
	float4 lDiff =  lDiff1;	
	float4 lSpec =  lSpec1;
	
	if(att2Factor == 1){
		Att0 = lAtt02;
		Att1 = lAtt12;
		Att2 = lAtt22;
		
		lAmb =  lAmb2;
		lDiff =  lDiff2;	
		lSpec =  lSpec2;
	}

    //compute attenuation only if vertex within lightrange
    if (d<lRange)
    {
       atten = 1/(saturate(Att0) + saturate(Att1) * d + saturate(Att2) * pow(d, 2));
    }

    float4 amb = lAmb * atten;
    amb.a = 1;

    //halfvector
    float3 H = normalize(ViewDirV + LightDirV);

    //compute blinn lighting
    float4 shades = lit(dot(NormV, LightDirV), dot(NormV, H), lPower);

    float4 diff = lDiff * shades.y * atten;
    diff.a = 1;

    //reflection vector (view space)
    float3 R = normalize(2 * dot(NormV, LightDirV) * NormV - LightDirV);

    //normalized view direction (view space)
    float3 V = normalize(ViewDirV);

    //calculate specular light
    float4 spec = pow(max(dot(R, V),0), lPower*.2) * lSpec;

    return (amb + diff) + spec;
}
