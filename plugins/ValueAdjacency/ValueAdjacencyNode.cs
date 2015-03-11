#region usings
using System;
using System.ComponentModel.Composition;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;

using System.Collections.Generic;
#endregion usings

namespace VVVV.Nodes
{
	#region PluginInfo
	[PluginInfo(Name = "Adjacency", Category = "Value", Help = "Basic template with one value in/out", Tags = "")]
	#endregion PluginInfo
	public class ValueAdjacencyNode : IPluginEvaluate
	{
		#region fields & pins
		
		[Input("Calculate", DefaultValue = 0)]
		public ISpread<int> calc;
		
		[Input("Indices")]
		public ISpread<int> Indices;

		[Output("AdjacentFaces")]
		public ISpread<int> AdjacentFaces;
		
		[Output("AdjacentFacesCount")]
		public ISpread<int> AdjacentFacesCount;
		
		[Output("AdjacentFacesOffset")]
		public ISpread<int> AdjacentFacesOffset;
		
		[Output("Busy")]
		public ISpread<int> IsBusy;

		[Import()]
		public ILogger FLogger;
		#endregion fields & pins
		
		System.Threading.Thread newThread;
		
		int faceCounter = 0;
		List<int> Faces = new List<int>();
		List<int> Offsets = new List<int>();
		
		int SpreadMaxPublic;
		bool busy = false;
		
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			
			
			if(calc[0] == 1 && !busy) {
				SpreadMaxPublic = SpreadMax;
				newThread = new System.Threading.Thread(calcAdjacency);
				newThread.Start();
			}
			
			
		}
		
		public void calcAdjacency()
		{	
			
			busy = true;
			
			IsBusy[0] = 1;
			
			//AdjacentFaces.SliceCount = SpreadMax;
			AdjacentFacesCount.SliceCount = SpreadMaxPublic;
			AdjacentFacesOffset.SliceCount = SpreadMaxPublic;
			
		
				
				Faces.Clear();
				Offsets.Clear();
				int facesCounter = 0;
				int facesOffset = 0;
			//	faceCounter = 0;
				
				for (int i = 0; i < SpreadMaxPublic; i++){
					faceCounter = 0;
					facesCounter = 0;
					AdjacentFacesOffset[i] = facesOffset;
				//	if( i % 3 == 0){
				//		Offsets.Add(facesOffset);
						
				//	}
					
					
					for (int j = 0; j < SpreadMaxPublic; j+=3){
						
						if(Indices[j] == Indices[i]){
							Faces.Add(faceCounter);
							facesCounter++;
						}
						
						if(Indices[j+1] == Indices[i]){
							Faces.Add(faceCounter);
							facesCounter++;
						}
						if(Indices[j+2] == Indices[i]){
							Faces.Add(faceCounter);
							facesCounter++;
						}
						
						
						faceCounter++;
						
					}
					facesOffset += facesCounter;
					AdjacentFacesCount[i] = facesCounter;
					
					
				}
				
				
				AdjacentFaces.SliceCount = Faces.Count;
				
				for(int m = 0; m < Faces.Count; m++){
					
					AdjacentFaces[m] = Faces[m];	
					
				}
				
				//AdjacentFacesOffset.SliceCount = Offsets.Count;
				
				//for(int o = 0; o < Faces.Count; o++){
					
				//	AdjacentFacesOffset[o] = Offsets[o];	
					
				//}
				
				busy = false;
				IsBusy[0] = 0;
				newThread.Abort();
				
			
		}
	}
}
