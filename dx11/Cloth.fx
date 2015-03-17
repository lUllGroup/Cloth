bool reset;
int pCount;
int resolveCount;
//float3 target;
float3 gravity;
StructuredBuffer<float> movementFactor;
float width;
float restLength;
Texture2D texDepth <string uiname="Depth";>;

int left;
int leftTogUp;
int applyAttractor;
float bounce;
float power;
float resolveFactor;
float depthExtrude;
float depthOffset;
int bendingCount = 1;
float texRepellForce = 1;

float returnStrength;


StructuredBuffer<float3> attractor;
StructuredBuffer<float3> resetData;
StructuredBuffer<int> pinDown;
StructuredBuffer<int> connectSizes;
StructuredBuffer<float> bendingFactors;
StructuredBuffer<float> depthMap;
StructuredBuffer<float> depthThreshold;
StructuredBuffer<float> positionThreshold;



SamplerState mySampler
{
	Filter = MIN_MAG_MIP_POINT;
	AddressU = Clamp;
	AddressV = Clamp;
};

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

[numthreads(64, 1, 1)]
void CSConstantForce( uint3 DTid : SV_DispatchThreadID)
{

	int iterator = DTid.x;
	float connectSize = 1;
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
			
			
			float3 p1 = 0;
			float3 p2 = 0;
	
			bool skip = false;
				
			
			for(int c = 0; c < bendingCount; c++){
				
				connectSize = connectSizes[c];
				bendingFactor = bendingFactors[c];
				
				for(int b = 0; b < 8; b++){
					
					switch(b){
						
						// Bending Constraints
								case 0:
								if(iterator < (pCount-(width * connectSize))){
									// Down
									connection = iterator+(width * connectSize);
									rest_length = restLength * connectSize;
								} else {
									skip = true;
								}
							
								break;
						
						case 1:
								if(iterator > (width * connectSize) -1 ){
									// Up
									connection = iterator-(width * connectSize);
									rest_length = restLength * connectSize;
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
								if(iterator < (pCount-(width*connectSize)) && iterator % width >= connectSize){
									// Down Left
									connection = iterator + ( width * connectSize)- connectSize;
									rest_length = rest_length2 * connectSize;			
								} else {
									skip = true;
								}
							
								break;
						
						case 7:
								if(iterator < (pCount-(width * connectSize)) && (iterator + connectSize) % width >= connectSize){
									// Down Right
									connection = iterator + (width * connectSize) + connectSize;
									rest_length = rest_length2 * connectSize;	
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
					
						//AllMemoryBarrier();
						
						if(!skip){
							if(pinDown[iterator] != 1){
								
								Output[iterator].pos += correctionVector * resolveFactor * bendingFactor ;
								//Output[connection].pos -= correctionVector * resolveFactor * bendingFactor ;
							}
						}
						skip = false;
						
						
					}
					
				}						
			}				
		}
		

		///////////////////////
		// Return
		///////////////////////
		
		float3 returnVec =  resetData[iterator] - Output[iterator].pos;
		Output[iterator].pos += returnVec * .0001  * returnStrength;
		
		
		
		uint numObjects, dummy;
    	attractor.GetDimensions(numObjects, dummy); 
		
		for(int d = 0; d < numObjects; d++){
			
			
			///////////////////////
			// Repell from attractor
			///////////////////////
			
			// calculate target force	
			float3 force = attractor[d] - Output[iterator].pos;
			float myDistance = length(force);
				
	
			if(myDistance <= 0.3  && applyAttractor){
				//float strength = 2 / myDistance * myDistance;
				Output[iterator].pos += force * -.001;
			} 
		}
	
		
		
		///////////////////////
		// Repell from texture
		///////////////////////

		
		
		int y = iterator/width + 1;
		int x = iterator - ((iterator/width) * width);

		
		float1 lookupA = mapRange(Output[iterator].pos.x,depthMap[0],depthMap[1],depthMap[2],depthMap[3]);
		float1 lookupB = mapRange(Output[iterator].pos.y,depthMap[4],depthMap[5],depthMap[6],depthMap[7]);
		
		float2 lookup1 = float2(lookupA,lookupB);
				
		
		float depth =  texDepth.SampleLevel(mySampler,lookup1,0).r;

		float3 newTarget = float3(Output[iterator].pos.x,Output[iterator].pos.y,((-depth * -depthExtrude) - depthOffset));	

		
		float3 force2 = Output[iterator].pos - newTarget;
		
		force2 = saturate(force2);
	

		if(depth > 0) {
			Output[iterator].pos += force2 * -.0005 * texRepellForce;
		}

			
		//////////////////////////////////////////////////////
		
		
		

		if(pinDown[iterator] != 1){
			
			// Standard behaviour
		
			int divide = iterator/(width) + 1;
		
			float3 temp = Output[iterator].pos;
			float3 movement = (Output[iterator].pos - Output[iterator].oldPos);						
			float3 tempOut = Output[iterator].pos +
			movement * bounce + (gravity * movementFactor[iterator]) * 0.001;
			
			Output[iterator].oldPos = temp;
			Output[iterator].pos = tempOut;
	
					
		} 
			else
		{
			
			// Pin Down
			
			
			
			Output[iterator].oldPos = resetData[iterator];
			Output[iterator].pos = resetData[iterator];
			
		}
			
		
		
		float3 distanceTarget = attractor[0] - Output[iterator].pos;
		float distanceTargetLength = length(distanceTarget);
		
		if(leftTogUp){
			if(distanceTargetLength <= .2){
				Output[iterator].pinched = true;
			}else{
				Output[iterator].pinched = false;
			}
		}
		
		if(Output[iterator].pinched && left){
			//Output[iterator].pos = float3(target.x,target.y, -.2);
			Output[iterator].pos += (distanceTarget + float3(0,0,-.2))*.001;
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