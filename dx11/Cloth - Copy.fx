bool reset;
int pCount;
int resolveCount;
float3 target;
float3 gravity;
float width;
float restLength;
Texture2D tex;
Texture2D texDepth <string uiname="Depth";>;
float2 FOV;

int left;
int leftTogUp;
int right;
float bounce;
float power;
float resolveFactor;
float depthExtrude;
float depthOffset;


SamplerState mySampler : IMMUTABLE
{
	Filter = MIN_MAG_MIP_POINT;
	AddressU = Clamp;
	AddressV = Clamp;
};

StructuredBuffer<float3> resetData;
StructuredBuffer<int> pinDown;
StructuredBuffer<int> connectSizes;
StructuredBuffer<float> bendingFactors;
StructuredBuffer<float> depthMap;
StructuredBuffer<float> depthThreshold;

struct particle
{
	float3 pos;
	float3 oldPos;
	bool pinched;
};

float1 mapRange(float1 value, float from1,float to1,float from2, float to2){
	
	return  (value - from1) / (to1 - from1) * (to2 - from2) + from2;
}

float2 mapRange(float2 value, float from1,float to1,float from2, float to2){
	
	return  (value - from1) / (to1 - from1) * (to2 - from2) + from2;
}

float3 mapRange3(float3 value, float from1,float to1,float from2, float to2){
	
	return  (value - from1) / (to1 - from1) * (to2 - from2) + from2;
}

RWStructuredBuffer<particle> Output : BACKBUFFER;


//==============================================================================
//COMPUTE SHADER ===============================================================
//==============================================================================

[numthreads(128, 1, 1)]
void CSConstantForce( uint3 DTid : SV_DispatchThreadID)
{

	int iterator = DTid.x;
	float connectSize = 1;
	//float bendingLengthFactor = 1;
	float bendingFactor = 1;
	
	if (reset)
	{
		Output[iterator].pos = resetData[iterator];
		Output[iterator].oldPos = resetData[iterator];
	}
	
	else
	{	
		
			for(int a = 0; a < resolveCount; a++){
				
			float connection = 0;
			float rest_length = restLength;
			float rest_length2 = sqrt((rest_length * rest_length) + (rest_length * rest_length));
			
			int connectionCount = 8;
			
			float3 p1 = 0;
			float3 p2 = 0;
	
			bool skip = false;
				
			
			for(int c = 0; c < 2; c++){
				
				connectSize = connectSizes[c];
				bendingFactor = bendingFactors[c];
				for(int b = 0; b < connectionCount; b++){
					
					switch(b){
						
						// Bending Constraints
						
						case 0:
								if(iterator < (pCount-(width*connectSize)) && iterator % width >= connectSize){
									// Down Left
									connection = iterator + ( width * connectSize)- connectSize;
									rest_length = rest_length2 * connectSize;			
								} else {
									skip = true;
								}
								break;
						
						case 1:
								if(iterator < (pCount-(width * connectSize)) && (iterator + connectSize) % width >= connectSize){
									// Down Right
									connection = iterator + (width * connectSize) + connectSize;
									rest_length = rest_length2 * connectSize;	
								} else {
									skip = true;
								}
								break;
						
						case 2:
								if(iterator > (width * connectSize) -1 && iterator % width >= connectSize){
									// Up Left
									connection = iterator - (width * connectSize) - connectSize;
									rest_length = rest_length2 * connectSize;	
								} else {
									skip = true;
								}
								break;
						
						case 3:
								if(iterator > (width * connectSize) -1 && (iterator + connectSize) % width >= connectSize){
									// Up Right
									connection = iterator - ( width * connectSize) + connectSize;
									rest_length = rest_length2 * connectSize;
								} else {
									skip = true;
								}
								break;
						
						case 4:	
								if((iterator + connectSize) % width >= connectSize){
									// Right
									connection = (iterator+(connectSize*1));
									rest_length = restLength * connectSize;
								} else {
									skip = true;
								}
								break;
						
						case 5:
								if(iterator % width >= connectSize){
									// Left
									connection = (iterator+(-connectSize));
									rest_length = restLength * connectSize;
								} else {
									skip = true;
								}
								break;
						
						case 6:
								if(iterator < (pCount-(width * connectSize))){
									// Down
									connection = iterator+(width * connectSize);
									rest_length = restLength * connectSize;
								} else {
									skip = true;
								}
							
								break;
						
						case 7:
								if(iterator > (width * connectSize) -1 ){
									// Up
									connection = iterator-(width * connectSize);
									rest_length = restLength * connectSize;
								} else {
									skip = true;
								}
								break;
						
						
					}

				
					
					p1 = Output[iterator].pos;
					p2 = Output[connection].pos;
					
					float3 p1_to_p2 =  p2 - p1;
					float currentDistance = length(p1_to_p2);
				
					if(currentDistance > 0.0){
				
						float3 correctionVector = p1_to_p2 * (power - rest_length/currentDistance);
						
						if(!skip){
							if(pinDown[iterator] != 1){
								int divide = iterator/(width) + 1;
								Output[iterator].pos += correctionVector * resolveFactor * bendingFactor ;
//								if(connection > width -1){
//									Output[connection].pos -= correctionVector * .03;
//								}
							}
							
						}
						skip = false;
						
						
					}
					
				}						
			}				
		}
			
		// calculate target force	
		float3 force = target - Output[iterator].pos;
		float myDistance = length(force);
			
		
		
		if(myDistance <= 0.05  && right){
			//float strength = 2 / myDistance * myDistance;
			Output[iterator].pos += force * -.02;
		} 
		
		
		//////////////////////
		// Repell from texture
		//////////////////////
		
		
		

		
		
		
		int y = iterator/width + 1;
		int x = iterator - ((iterator/width) * width);
		
		
//		float1 lookupA = mapRange(Output[iterator].pos.x,-2,2,0,1);
//		float1 lookupB = mapRange(Output[iterator].pos.y,2,-2,0,1);
		
		float1 lookupA = mapRange(Output[iterator].pos.x,depthMap[0],depthMap[1],depthMap[2],depthMap[3]);
		float1 lookupB = mapRange(Output[iterator].pos.y,depthMap[4],depthMap[5],depthMap[6],depthMap[7]);
		
		float2 lookup1 = float2(lookupA,lookupB);
		
		float4 repell = tex.SampleLevel(mySampler,lookup1,0);
		
	
			

		//float3 newTarget = float3(Output[iterator].pos.x,Output[iterator].pos.y,-repell.r * .25);	

		
//		force2 = normalize(force);
//		force2*= -0.01;
		//float myDistance2 = length(force2);
		
		
					float depth =  texDepth.SampleLevel(mySampler,lookup1,0).r  * 65.535;
//					float XtoZ = tan(FOV.x/2) * 2;
//				    float YtoZ = tan(FOV.y/2) * 2;

					//depth = mapRange(depth,0,1,0,1000);
			
					//saturate(depth);
		
					float3 newTarget = float3(Output[iterator].pos.x,Output[iterator].pos.y,(depth*-depthExtrude)-depthOffset);	
//					input.pos.x = ((lookup1 - 0.5) * depth * XtoZ * -1);
//					input.pos.y = ((0.5 - lookup1) * depth * YtoZ);
//					input.pos.z = depth;
		
		
//		float x1 = ((lookup1 - 0.5) * depth * XtoZ * -1);
//		float y1 = ((0.5 - lookup1) * depth * YtoZ);
//		float3 newTarget = float3(x1,y1o,depth);
	
		float3 force2 = Output[iterator].pos - newTarget;
		
		
		//float strength2 = 2 / myDistance2 * myDistance2;
//		if((depth) <= 0.01 && force2.z > 0 ) {
//			Output[iterator].pos += force2 * -.008;
//		}
		
		
	//
		
		if(depth > depthThreshold[0] && depth < depthThreshold[1] && force2.z > 0) {
			Output[iterator].pos += force2 * -.008;
		}

		

//		if((repell.r) >= 0.2 && force2.z > 0 ) {
//			Output[iterator].pos += force2 * -.008;
//		}
		
	
			
		//////////////////////////////////////////////////////
		
		
		

		if(pinDown[iterator] != 1){
			
			// Standard behaviour
			
			int divide = iterator/(width) + 1;
	
			float3 temp = Output[iterator].pos;
			float3 tempOut = Output[iterator].pos +
			(Output[iterator].pos - Output[iterator].oldPos)*bounce + (gravity * 1) * 0.001;
	
			Output[iterator].oldPos = temp;
			Output[iterator].pos = tempOut;
			
					
		} 
			else
		{
			
			// Pin Down

			Output[iterator].oldPos = resetData[iterator];
			Output[iterator].pos = resetData[iterator];
		
		}
			
		
		
		float3 distanceTarget = target - Output[iterator].pos;
		float distanceTargetLength = length(distanceTarget);
		
		if(leftTogUp){
			if(distanceTargetLength <= .03){
				Output[iterator].pinched = true;
			}else{
				Output[iterator].pinched = false;
			}
		}
		
		if(Output[iterator].pinched && left){
			Output[iterator].pos = float3(target.x,target.y, -.1);
		}
	}
}



//==============================================================================
//TECHNIQUES ===================================================================
//==============================================================================

technique11 simulation
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CSConstantForce() ) );
	}
}