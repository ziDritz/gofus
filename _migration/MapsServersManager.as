class dofus.managers.MapsServersManager extends dofus.managers.ServersManager
{
   static var _sSelf = null;
   var _lastLoadedMap = undefined;
   var _aKeys = [];
   var _bBuildingMap = false;
   var _bCustomFileCall = false;
   var _bPreloadCall = false;
   function MapsServersManager()
   {
      super();
      dofus.managers.MapsServersManager._sSelf = this;
   }
   function get isBuilding()
   {
      return this._bBuildingMap;
   }
   function set isBuilding(bBuilding)
   {
      this._bBuildingMap = bBuilding;
   }
   static function getInstance()
   {
      return dofus.managers.MapsServersManager._sSelf;
   }
   function initialize(oAPI)
   {
      super.initialize(oAPI,"maps","maps/");
   }
   function loadMap(sID, sDate, sKey)
   {
      this._lastLoadedMap = undefined;
      if(!_global.isNaN(Number(sID)))
      {
         if(sKey != undefined && sKey.length > 0)
         {
            this._aKeys[Number(sID)] = dofus.aks.Aks.prepareKey(sKey);
         }
         else
         {
            delete this._aKeys[Number(sID)];
         }
      }
      this.loadData(sID + "_" + sDate + (this._aKeys[Number(sID)] == undefined ? "" : "X") + ".swf");
   }
   function getMapName(nMapID)
   {
      var oMapText = this.api.lang.getMapText(nMapID);
      var oAreaInfos = this.api.lang.getMapAreaInfos(oMapText.sa);
      var sAreaName = this.api.lang.getMapAreaText(oAreaInfos.areaID).n;
      var sSubAreaName = this.api.lang.getMapSubAreaText(oMapText.sa).n;
      var sMapName = sAreaName + (sSubAreaName.indexOf("//") != -1 ? "" : " (" + sSubAreaName + ")");
      if(dofus.Constants.DEBUG)
      {
         sMapName += " (" + nMapID + ")";
      }
      return sMapName;
   }
   function parseMap(oData)
   {
      if(this.api.network.Game.isBusy)
      {
         this.addToQueue({object:this,method:this.parseMap,params:[oData]});
         return undefined;
      }
      var nMapID = Number(oData.id);
      if(this.api.config.isStreaming && this.api.config.streamingMethod == "compact")
      {
         var aIncarnationMaps = this.api.lang.getConfigText("INCARNAM_CLASS_MAP");
         var bIsIncarnationMap = false;
         var nIndex = 0;
         while(nIndex < aIncarnationMaps.length && !bIsIncarnationMap)
         {
            if(aIncarnationMaps[nIndex] == nMapID)
            {
               bIsIncarnationMap = true;
            }
            nIndex = nIndex + 1;
         }
         if(bIsIncarnationMap)
         {
            var aGfxFiles = [dofus.Constants.GFX_ROOT_PATH + "g" + this.api.datacenter.Player.Guild + ".swf",dofus.Constants.GFX_ROOT_PATH + "o" + this.api.datacenter.Player.Guild + ".swf"];
         }
         else
         {
            aGfxFiles = [dofus.Constants.GFX_ROOT_PATH + "g0.swf",dofus.Constants.GFX_ROOT_PATH + "o0.swf"];
         }
         if(!this.api.gfx.loadManager.areRegister(aGfxFiles))
         {
            this.api.gfx.loadManager.loadFiles(aGfxFiles);
            this.api.gfx.bCustomFileLoaded = false;
         }
         if(this.api.gfx.loadManager.areLoaded(aGfxFiles))
         {
            this.api.gfx.setCustomGfxFile(aGfxFiles[0],aGfxFiles[1]);
         }
         if(!this.api.gfx.bCustomFileLoaded || !this.api.gfx.loadManager.areLoaded(aGfxFiles))
         {
            var oLoadingUI = this.api.ui.getUIComponent("CenterTextMap");
            if(!oLoadingUI)
            {
               oLoadingUI = this.api.ui.loadUIComponent("CenterText","CenterTextMap",{text:this.api.lang.getText("LOADING_MAP"),timer:40000},{bForceLoad:true});
            }
            this.api.ui.getUIComponent("CenterTextMap").updateProgressBar("Downloading",this.api.gfx.loadManager.getProgressions(aGfxFiles),100);
            this.addToQueue({object:this,method:this.parseMap,params:[oData]});
            return undefined;
         }
         if(bIsIncarnationMap && !this._bPreloadCall)
         {
            this._bPreloadCall = true;
            this.api.gfx.loadManager.loadFiles([dofus.Constants.CLIPS_PERSOS_PATH + (this.api.datacenter.Player.Guild * 10 + this.api.datacenter.Player.Sex) + ".swf",dofus.Constants.CLIPS_PERSOS_PATH + "9059.swf",dofus.Constants.CLIPS_PERSOS_PATH + "9091.swf",dofus.Constants.CLIPS_PERSOS_PATH + "1219.swf",dofus.Constants.CLIPS_PERSOS_PATH + "101.swf",dofus.Constants.GFX_ROOT_PATH + "g0.swf",dofus.Constants.GFX_ROOT_PATH + "o0.swf"]);
         }
      }
      this._bCustomFileCall = false;
      if(this.api.network.Game.nLastMapIdReceived != nMapID && (this.api.network.Game.nLastMapIdReceived != -1 && this.api.lang.getConfigText("CHECK_MAP_FILE_ID")))
      {
         this.api.gfx.onMapLoaded();
         return undefined;
      }
      this._bBuildingMap = true;
      this._lastLoadedMap = oData;
      var sMapName = this.getMapName(nMapID);
      var nMapWidth = Number(oData.width);
      var nMapHeight = Number(oData.height);
      var nBackgroundNum = Number(oData.backgroundNum);
      var sMapData = this._aKeys[nMapID] == undefined ? oData.mapData : dofus.aks.Aks.decypherData(oData.mapData,this._aKeys[nMapID],_global.parseInt(dofus.aks.Aks.checksum(this._aKeys[nMapID]),16) * 2);
      var nAmbianceId = oData.ambianceId;
      var nMusicId = oData.musicId;
      var bIsOutdoor = oData.bOutdoor != 1 ? false : true;
      var bCanChallenge = (oData.capabilities & 1) == 0;
      var bCanAttack = (oData.capabilities >> 1 & 1) == 0;
      var bSaveTeleport = (oData.capabilities >> 2 & 1) == 0;
      var bUseTeleport = (oData.capabilities >> 3 & 1) == 0;
      var bCanAttackHunt = oData.canAggro != 1 ? false : true;
      var bCanUseItem = oData.canUseObject != 1 ? false : true;
      var bCanEquipItem = oData.canUseInventory != 1 ? false : true;
      var bCanBoostStats = oData.canChangeCharac != 1 ? false : true;
      this.api.datacenter.Basics.aks_current_map_id = nMapID;
      this.api.kernel.TipsManager.onNewMap(nMapID);
      this.api.kernel.StreamingDisplayManager.onNewMap(nMapID);
      var oDofusMap = new dofus.datacenter.DofusMap(nMapID);
      oDofusMap.bCanChallenge = bCanChallenge;
      oDofusMap.bCanAttack = bCanAttack;
      oDofusMap.bSaveTeleport = bSaveTeleport;
      oDofusMap.bUseTeleport = bUseTeleport;
      oDofusMap.bOutdoor = bIsOutdoor;
      oDofusMap.bCanAttackHunt = bCanAttackHunt;
      oDofusMap.bCanUseItem = bCanUseItem;
      oDofusMap.bCanEquipItem = bCanEquipItem;
      oDofusMap.bCanBoostStats = bCanBoostStats;
      oDofusMap.ambianceID = nAmbianceId;
      oDofusMap.musicID = nMusicId;
      this.api.gfx.buildMap(nMapID,sMapName,nMapWidth,nMapHeight,nBackgroundNum,sMapData,oDofusMap);
      if(this.api.network.Basics.lastReceivedReferenceTime != undefined)
      {
         this.api.kernel.NightManager.setReferenceTime(this.api.network.Basics.lastReceivedReferenceTime,this.api.kernel.OptionsManager.getOption("NightMode"),oDofusMap);
      }
      this._bBuildingMap = false;
   }
   function onComplete(mc)
   {
      var oLoadedData = mc;
      this.parseMap(oLoadedData);
   }
   function onFailed()
   {
      this.api.kernel.showMessage(undefined,this.api.lang.getText("NO_MAPDATA_FILE"),"ERROR_BOX",{name:"NoMapData"});
   }
}
