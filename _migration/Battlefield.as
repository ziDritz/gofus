
   function buildMapFromObject(oMap, bBuildAll)
   {
      this.clear();
      if(oMap == undefined)
      {
         return undefined;
      }
      this.onMapBuilding();
      this.mapHandler.build(oMap,undefined,bBuildAll);
      if(this.mapHandler.LoaderRequestLeft == 0)
      {
         this.DispatchMapLoaded();
      }
      else
      {
         this._nFrameLoadTimeOut = ank.battlefield.Battlefield.FRAMELOADTIMOUT;
         var ref = this;
         this.onEnterFrame = function()
         {
            ref._nFrameLoadTimeOut--;
            if(ref._nFrameLoadTimeOut <= 0 || ref.mapHandler.LoaderRequestLeft <= 0)
            {
               delete ref.onEnterFrame;
               ref.DispatchMapLoaded();
            }
         };
      }
   }
   function buildMap(nID, sName, nWidth, nHeight, nBackID, sCompressedData, oMap, bBuildAll)
   {
      if(oMap == undefined)
      {
         oMap = new ank.battlefield.datacenter.Map();
      }
      ank.battlefield.utils.Compressor.uncompressMap(nID,sName,nWidth,nHeight,nBackID,sCompressedData,oMap,bBuildAll);
      this.buildMapFromObject(oMap,bBuildAll);
   }