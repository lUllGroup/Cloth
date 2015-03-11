
int elementcount;


struct adj{
	float faces;
	float faceCount;
};
/*This is the buffer from the renderer
Renderer automatically assigns BACKBUFFER semantic
Please note we mark the buffer as append here */
AppendStructuredBuffer<float> AppendPositionBuffer : BACKBUFFER;

AppendStructuredBuffer<float> AppendPositionBuffer2 : BACKBUFFER;



[numthreads(32, 1, 1)]
void CS( uint3 i : SV_DispatchThreadID)
{ 
//	AppendPositionBuffer.Append(i.x);
	AppendPositionBuffer2.Append(i.x +22);

}

technique11 Process
{
	pass P0
	{
		SetComputeShader( CompileShader( cs_5_0, CS() ) );
	}
}







