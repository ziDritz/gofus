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
      var nMapID = Number(oData.id);
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
   }

}
