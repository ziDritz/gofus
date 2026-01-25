class ank.battlefield.MapHandler
{
   var _nLoadRequest;
   var _oDatacenter;
   var _mcBattlefield;
   var _mcContainer;
   var api;
   var _nLastCellCount;
   var _nAdjustTimer;
   static var OBJECT_TYPE_BACKGROUND = 1;
   static var OBJECT_TYPE_GROUND = 2;
   static var OBJECT_TYPE_OBJECT1 = 3;
   static var OBJECT_TYPE_OBJECT2 = 4;
   static var TIME_BEFORE_AJUSTING_MAP = 500;
   var _oLoadingCells = {};
   var _oSettingFrames = {};
   var _mclLoader = new MovieClipLoader();
   var _nMaxMapRender = 1;
   var _bShowingFightCells = false;
   var _bTacticMode = false;
   function MapHandler(b, c, d)
   {
      if(b != undefined)
      {
         this.initialize(b,c,d);
      }
      this._mclLoader.addListener(this);
   }
   function get showingFightCells()
   {
      return this._bShowingFightCells;
   }
   function set showingFightCells(bShowingFightCells)
   {
      this._bShowingFightCells = bShowingFightCells;
   }
   function get LoaderRequestLeft()
   {
      return this._nLoadRequest;
   }
   function get validCellsData()
   {
      return this._oDatacenter.Map.validCells;
   }
   function initialize(b, c, d)
   {
      this._mcBattlefield = b;
      this._oDatacenter = d;
      this._mcContainer = c;
      this.api = _global.API;
   }
   function build(oMap, nCellNum, bBuildAll)
   {
      this._oDatacenter.Map = oMap;
      var nCellWidth = ank.battlefield.Constants.CELL_WIDTH;
      var nCellHalfWidth = ank.battlefield.Constants.CELL_HALF_WIDTH;
      var nCellHalfHeight = ank.battlefield.Constants.CELL_HALF_HEIGHT;
      var nLevelHeight = ank.battlefield.Constants.LEVEL_HEIGHT;
      var nCol = -1;
      var nRow = 0;
      var nXOffset = 0;
      var oCellData = oMap.data;
      var nCellCount = oCellData.length;
      var nMaxCol = oMap.width - 1;
      var mcExternalContainer = this._mcContainer.ExternalContainer;
      var bSingleCell = nCellNum != undefined;
      var bRenderingEmptyCells = false;
      var bSameCellCount = this._nLastCellCount == nCellCount;
      this._nLoadRequest = 0;
      if(!bSingleCell && (ank.battlefield.Constants.USE_STREAMING_FILES && ank.battlefield.Constants.STREAMING_METHOD == "explod"))
      {
         this._mcContainer.applyMask(false);
      }
      if(oMap.backgroundNum != 0)
      {
         if(ank.battlefield.Constants.USE_STREAMING_FILES && (ank.battlefield.Constants.STREAMING_METHOD == "explod" && !bSingleCell))
         {
            var mcBackground = mcExternalContainer.Ground.createEmptyMovieClip("background",-1);
            mcBackground.cacheAsBitmap = _global.CONFIG.cacheAsBitmap["mapHandler/BACKGROUND"];
            this._mclLoader.loadClip(ank.battlefield.Constants.STREAMING_GROUNDS_DIR + oMap.backgroundNum + ".swf",mcBackground);
            this._nLoadRequest = this._nLoadRequest + 1;
         }
         else if(ank.battlefield.Constants.STREAMING_METHOD != "")
         {
            mcExternalContainer.Ground.attachMovie(oMap.backgroundNum,"background",-1).cacheAsBitmap = _global.CONFIG.cacheAsBitmap["mapHandler/BACKGROUND"];
         }
         else
         {
            mcExternalContainer.Ground.attach(oMap.backgroundNum,"background",-1).cacheAsBitmap = _global.CONFIG.cacheAsBitmap["mapHandler/BACKGROUND"];
         }
      }
      var nCellIndex = -1;
      while((nCellIndex = nCellIndex + 1) < nCellCount)
      {
         if(nCol == nMaxCol)
         {
            nCol = 0;
            nRow += 1;
            if(nXOffset == 0)
            {
               nXOffset = nCellHalfWidth;
               nMaxCol -= 1;
            }
            else
            {
               nXOffset = 0;
               nMaxCol += 1;
            }
         }
         else
         {
            nCol = nCol + 1;
         }
         if(bSingleCell)
         {
            if(nCellIndex < nCellNum)
            {
               continue;
            }
            if(nCellIndex > nCellNum)
            {
               return undefined;
            }
         }
         var oCellData = oCellData[nCellIndex];
         if(oCellData.active)
         {
            var nCellX = nCol * nCellWidth + nXOffset;
            var nCellY = nRow * nCellHalfHeight - nLevelHeight * (oCellData.groundLevel - 7);
            oCellData.x = nCellX;
            oCellData.y = nCellY;
            if(oCellData.movement || bBuildAll)
            {
               if(!bSameCellCount && !mcExternalContainer.InteractionCell["cell" + nCellIndex])
               {
                  if(!bRenderingEmptyCells)
                  {
                     if(ank.battlefield.Constants.STREAMING_METHOD != "")
                     {
                        var mcInteractionCell = mcExternalContainer.InteractionCell.attachMovie("i" + oCellData.groundSlope,"cell" + nCellIndex,nCellIndex,{_x:nCellX,_y:nCellY});
                     }
                     else
                     {
                        mcInteractionCell = mcExternalContainer.InteractionCell.attachMovie("i" + oCellData.groundSlope,"cell" + nCellIndex,nCellIndex,{_x:nCellX,_y:nCellY});
                     }
                  }
                  else
                  {
                     mcInteractionCell = mcExternalContainer.InteractionCell.createEmptyMovieClip("cell" + nCellIndex,nCellIndex,{_x:nCellX,_y:nCellY});
                  }
                  mcInteractionCell.__proto__ = ank.battlefield.mc.Cell.prototype;
                  mcInteractionCell.initialize(this._mcBattlefield);
               }
               else
               {
                  mcInteractionCell = mcExternalContainer.InteractionCell["cell" + nCellIndex];
               }
               oCellData.mc = mcInteractionCell;
               mcInteractionCell.data = oCellData;
            }
            else
            {
               mcExternalContainer.InteractionCell["cell" + nCellIndex].removeMovieClip();
            }
            if(oCellData.layerGroundNum != 0)
            {
               if(ank.battlefield.Constants.USE_STREAMING_FILES && ank.battlefield.Constants.STREAMING_METHOD == "explod")
               {
                  var bLoadGround = true;
                  if(bSingleCell)
                  {
                     var mcGround = mcExternalContainer.Ground["cell" + nCellIndex];
                     if(mcGround != undefined && mcGround.lastGroundID == oCellData.layerGroundNum)
                     {
                        mcGround.fullLoaded = bLoadGround = false;
                        this._oLoadingCells[mcGround] = oCellData;
                        this.onLoadInit(mcGround);
                     }
                  }
                  if(bLoadGround)
                  {
                     mcGround = mcExternalContainer.Ground.createEmptyMovieClip("cell" + nCellIndex,nCellIndex);
                     mcGround.fullLoaded = false;
                     this._oLoadingCells[mcGround] = oCellData;
                     this._mclLoader.loadClip(ank.battlefield.Constants.STREAMING_GROUNDS_DIR + oCellData.layerGroundNum + ".swf",mcGround);
                     this._nLoadRequest = this._nLoadRequest + 1;
                  }
               }
               else
               {
                  if(!bRenderingEmptyCells)
                  {
                     if(ank.battlefield.Constants.STREAMING_METHOD != "")
                     {
                        mcGround = mcExternalContainer.Ground.attachMovie(oCellData.layerGroundNum,"cell" + nCellIndex,nCellIndex);
                     }
                     else
                     {
                        mcGround = mcExternalContainer.Ground.attach(oCellData.layerGroundNum,"cell" + nCellIndex,nCellIndex);
                     }
                  }
                  else
                  {
                     mcGround = new MovieClip();
                  }
                  mcGround.cacheAsBitmap = _global.CONFIG.cacheAsBitmap["mapHandler/Cell/Ground"];
                  mcGround._x = nCellX;
                  mcGround._y = nCellY;
                  if(oCellData.groundSlope != 1)
                  {
                     mcGround.gotoAndStop(oCellData.groundSlope);
                  }
                  else if(oCellData.layerGroundRot != 0)
                  {
                     mcGround._rotation = oCellData.layerGroundRot * 90;
                     if(mcGround._rotation % 180)
                     {
                        mcGround._yscale = 192.86;
                        mcGround._xscale = 51.85;
                     }
                  }
                  if(oCellData.layerGroundFlip)
                  {
                     mcGround._xscale *= -1;
                  }
               }
            }
            else
            {
               mcExternalContainer.Ground["cell" + nCellIndex].removeMovieClip();
            }
            if(oCellData.layerObject1Num != 0)
            {
               if(ank.battlefield.Constants.USE_STREAMING_FILES && ank.battlefield.Constants.STREAMING_METHOD == "explod")
               {
                  var bLoadObject1 = true;
                  if(bSingleCell)
                  {
                     var mcObject1 = mcExternalContainer.Object1["cell" + nCellIndex];
                     if(mcObject1 != undefined && mcObject1.lastObject1ID == oCellData.layerObject1Num)
                     {
                        mcObject1.fullLoaded = bLoadObject1 = false;
                        this._oLoadingCells[mcObject1] = oCellData;
                        this.onLoadInit(mcObject1);
                     }
                  }
                  if(bLoadObject1)
                  {
                     mcObject1 = mcExternalContainer.Object1.createEmptyMovieClip("cell" + nCellIndex,nCellIndex);
                     mcObject1.fullLoaded = false;
                     this._oLoadingCells[mcObject1] = oCellData;
                     this._mclLoader.loadClip(ank.battlefield.Constants.STREAMING_OBJECTS_DIR + oCellData.layerObject1Num + ".swf",mcObject1);
                     this._nLoadRequest = this._nLoadRequest + 1;
                  }
               }
               else
               {
                  if(!bRenderingEmptyCells)
                  {
                     mcObject1 = mcExternalContainer.Object1.attachMovie(oCellData.layerObject1Num,"cell" + nCellIndex,nCellIndex);
                  }
                  else
                  {
                     mcObject1 = new MovieClip();
                  }
                  mcObject1.cacheAsBitmap = _global.CONFIG.cacheAsBitmap["mapHandler/Cell/Object1"];
                  mcObject1._x = nCellX;
                  mcObject1._y = nCellY;
                  if(oCellData.groundSlope == 1 && oCellData.layerObject1Rot != 0)
                  {
                     mcObject1._rotation = oCellData.layerObject1Rot * 90;
                     if(mcObject1._rotation % 180)
                     {
                        mcObject1._yscale = 192.86;
                        mcObject1._xscale = 51.85;
                     }
                  }
                  if(oCellData.layerObject1Flip)
                  {
                     mcObject1._xscale *= -1;
                  }
               }
               oCellData.mcObject1 = mcObject1;
            }
            else
            {
               mcExternalContainer.Object1["cell" + nCellIndex].removeMovieClip();
            }
            if(oCellData.layerObjectExternal != "")
            {
               if(!bRenderingEmptyCells)
               {
                  var mcExternalObject = mcExternalContainer.Object2.attachClassMovie(ank.battlefield.mc.InteractiveObject,"cellExt" + nCellIndex,nCellIndex * 100 + 1);
               }
               mcExternalObject.cacheAsBitmap = _global.CONFIG.cacheAsBitmap["mapHandler/Cell/ObjectExternal"];
               mcExternalObject.initialize(this._mcBattlefield,oCellData,oCellData.layerObjectExternalInteractive);
               mcExternalObject.loadExternalClip(oCellData.layerObjectExternal,oCellData.layerObjectExternalAutoSize);
               mcExternalObject._x = nCellX;
               mcExternalObject._y = nCellY;
               oCellData.mcObjectExternal = mcExternalObject;
            }
            else
            {
               mcExternalContainer.Object2["cellExt" + nCellIndex].removeMovieClip();
               delete oCellData.mcObjectExternal;
            }
            if(oCellData.layerObject2Num != 0)
            {
               if(ank.battlefield.Constants.USE_STREAMING_FILES && ank.battlefield.Constants.STREAMING_METHOD == "explod")
               {
                  var bLoadObject2 = true;
                  if(bSingleCell)
                  {
                     var mcObject2 = mcExternalContainer.Object2["cell" + nCellIndex];
                     if(mcObject2 != undefined && mcObject2.lastObject2ID == oCellData.layerObject2Num)
                     {
                        mcObject2.fullLoaded = bLoadObject2 = false;
                        this._oLoadingCells[mcObject2] = oCellData;
                        this.onLoadInit(mcObject2);
                     }
                  }
                  if(bLoadObject2)
                  {
                     mcObject2 = mcExternalContainer.Object2.createEmptyMovieClip("cell" + nCellIndex,nCellIndex * 100);
                     mcObject2.fullLoaded = false;
                     this._oLoadingCells[mcObject2] = oCellData;
                     this._mclLoader.loadClip(ank.battlefield.Constants.STREAMING_OBJECTS_DIR + oCellData.layerObject2Num + ".swf",mcObject2);
                     this._nLoadRequest = this._nLoadRequest + 1;
                  }
               }
               else
               {
                  if(!bRenderingEmptyCells)
                  {
                     mcObject2 = mcExternalContainer.Object2.attachMovie(oCellData.layerObject2Num,"cell" + nCellIndex,nCellIndex * 100);
                  }
                  else
                  {
                     mcObject2 = new MovieClip();
                  }
                  if(mcObject2)
                  {
                     mcObject2.cacheAsBitmap = _global.CONFIG.cacheAsBitmap["mapHandler/Cell/Object2"];
                     if(oCellData.layerObject2Interactive)
                     {
                        mcObject2.__proto__ = ank.battlefield.mc.InteractiveObject.prototype;
                        mcObject2.initialize(this._mcBattlefield,oCellData,true);
                     }
                     mcObject2._x = nCellX;
                     mcObject2._y = nCellY;
                     if(oCellData.layerObject2Flip)
                     {
                        mcObject2._xscale = -100;
                     }
                  }
               }
               if(mcObject2)
               {
                  oCellData.mcObject2 = mcObject2;
               }
               else
               {
                  oCellData.layerObject2Num = 0;
                  mcExternalContainer.Object2["cell" + nCellIndex].removeMovieClip();
                  delete oCellData.mcObject2;
               }
            }
            else
            {
               mcExternalContainer.Object2["cell" + nCellIndex].removeMovieClip();
               delete oCellData.mcObject2;
            }
         }
         else if(bBuildAll)
         {
            var nInactiveCellX = nCol * nCellWidth + nXOffset;
            var nInactiveCellY = nRow * nCellHalfHeight;
            oCellData.x = nInactiveCellX;
            oCellData.y = nInactiveCellY;
            var mcInactiveCell = mcExternalContainer.InteractionCell.attachMovie("i1","cell" + nCellIndex,nCellIndex,{_x:nInactiveCellX,_y:nInactiveCellY});
            mcInactiveCell.__proto__ = ank.battlefield.mc.Cell.prototype;
            mcInactiveCell.initialize(this._mcBattlefield);
            oCellData.mc = mcInactiveCell;
            mcInactiveCell.data = oCellData;
         }
      }
      if(!bSingleCell)
      {
         if(ank.battlefield.Constants.USE_STREAMING_FILES && ank.battlefield.Constants.STREAMING_METHOD == "explod")
         {
            if(this._nAdjustTimer != undefined)
            {
               return undefined;
            }
            this._nAdjustTimer = _global.setInterval(this,"adjustAndMaskMap",ank.battlefield.MapHandler.TIME_BEFORE_AJUSTING_MAP);
         }
         else
         {
            this.adjustAndMaskMap();
         }
      }
   }
   function tacticMode(bOrig)
   {
      var bModeChanged = this._bTacticMode != bOrig;
      if(!bModeChanged)
      {
         return undefined;
      }
      var oMapData = this._oDatacenter.Map;
      var oMapCellsData = oMapData.data;
      if(bOrig)
      {
         this._mcContainer.ExternalContainer.clearGround();
         if(oMapData.savedBackgroundNum == undefined && oMapData.backgroundNum != 631)
         {
            oMapData.savedBackgroundNum = oMapData.backgroundNum;
         }
         oMapData.backgroundNum = 631;
      }
      else if(oMapData.savedBackgroundNum != undefined)
      {
         if(oMapData.savedBackgroundNum == 0)
         {
            oMapData.backgroundNum = 632;
         }
         else
         {
            oMapData.backgroundNum = oMapData.savedBackgroundNum;
         }
      }
      for(var mapCell in oMapCellsData)
      {
         this.tacticModeRefreshCell(Number(mapCell),bOrig);
      }
      this._bTacticMode = bOrig;
   }
   function tacticModeRefreshCell(nCellNum, bOrig)
   {
      if(nCellNum > this.getCellCount())
      {
         ank.utils.Logger.err("[MapHandler] (tacticModeRefreshCell) Cellule " + nCellNum + " inexistante");
         return undefined;
      }
      var oMapData = this._oDatacenter.Map;
      var oCellData = oMapData.data[nCellNum];
      if(oCellData.layerObject2Num == 4561 || oCellData.layerObject2Num == 4562)
      {
         return undefined;
      }
      if(!oCellData.active)
      {
         return undefined;
      }
      if(!bOrig)
      {
         var oBackupCellData = ank.battlefield.datacenter.Cell(oMapData.originalsCellsBackup.getItemAt(String(nCellNum)));
         if(oBackupCellData == undefined)
         {
            ank.utils.Logger.err("[MapHandler] (tacticModeRefreshCell) La case est déjà dans son état init");
            return undefined;
         }
         oCellData.layerGroundNum = oBackupCellData.layerGroundNum;
         oCellData.groundSlope = oBackupCellData.groundSlope;
         oCellData.layerObject1Rot = oBackupCellData.layerObject1Rot;
         oCellData.layerObject1Num = oBackupCellData.layerObject1Num;
         if(oCellData.layerObject2Num != 25)
         {
            oCellData.layerObject2Num = oBackupCellData.layerObject2Num;
         }
      }
      else
      {
         if(oCellData.nPermanentLevel == 0)
         {
            var oNewCellData = new ank.battlefield.datacenter.Cell();
            for(var cellData in oCellData)
            {
               oNewCellData[cellData] = oCellData[cellData];
            }
            oMapData.originalsCellsBackup.addItemAt(String(nCellNum),oNewCellData);
         }
         oCellData.turnTactic(this,oMapData);
      }
      this.build(oMapData,nCellNum);
   }
   function updateCell(nCellNum, oNewCell, sMaskHex, nPermanentLevel)
   {
      if(nCellNum > this.getCellCount())
      {
         ank.utils.Logger.err("[updateCell] Cellule " + nCellNum + " inexistante");
         return undefined;
      }
      if(nPermanentLevel == undefined || _global.isNaN(nPermanentLevel))
      {
         nPermanentLevel = 0;
      }
      else
      {
         nPermanentLevel = Number(nPermanentLevel);
      }
      var nMaskValue = _global.parseInt(sMaskHex,16);
      var bUpdateLayerObjectExternalAutoSize = (nMaskValue & 0x010000) != 0;
      var bUpdateLayerObjectExternalInteractive = (nMaskValue & 0x8000) != 0;
      var bUpdateLayerObjectExternal = (nMaskValue & 0x4000) != 0;
      var bUpdateActive = (nMaskValue & 0x2000) != 0;
      var bUpdateLineOfSight = (nMaskValue & 0x1000) != 0;
      var bUpdateMovement = (nMaskValue & 0x0800) != 0;
      var bUpdateGroundLevel = (nMaskValue & 0x0400) != 0;
      var bUpdateGroundSlope = (nMaskValue & 0x0200) != 0;
      var bUpdateLayerGroundNum = (nMaskValue & 0x0100) != 0;
      var bUpdateLayerGroundFlip = (nMaskValue & 0x80) != 0;
      var bUpdateLayerGroundRot = (nMaskValue & 0x40) != 0;
      var bUpdateLayerObject1Num = (nMaskValue & 0x20) != 0;
      var bUpdateLayerObject1Flip = (nMaskValue & 0x10) != 0;
      var bUpdateLayerObject1Rot = (nMaskValue & 8) != 0;
      var bUpdateLayerObject2Num = (nMaskValue & 4) != 0;
      var bUpdateLayerObject2Flip = (nMaskValue & 2) != 0;
      var bUpdateLayerObject2Interactive = (nMaskValue & 1) != 0;
      var oCellData = this._oDatacenter.Map.data[nCellNum];
      if(nPermanentLevel > 0)
      {
         if(oCellData.nPermanentLevel == 0)
         {
            var oBackupCellData = new ank.battlefield.datacenter.Cell();
            for(var k in oCellData)
            {
               oBackupCellData[k] = oCellData[k];
            }
            this._oDatacenter.Map.originalsCellsBackup.addItemAt(nCellNum,oBackupCellData);
            oCellData.nPermanentLevel = nPermanentLevel;
         }
      }
      if(bUpdateActive)
      {
         oCellData.active = oNewCell.active;
      }
      if(bUpdateLineOfSight)
      {
         oCellData.lineOfSight = oNewCell.lineOfSight;
      }
      if(bUpdateMovement)
      {
         oCellData.movement = oNewCell.movement;
      }
      if(bUpdateGroundLevel)
      {
         oCellData.groundLevel = oNewCell.groundLevel;
      }
      if(bUpdateGroundSlope)
      {
         oCellData.groundSlope = oNewCell.groundSlope;
      }
      if(bUpdateLayerGroundNum)
      {
         oCellData.layerGroundNum = oNewCell.layerGroundNum;
      }
      if(bUpdateLayerGroundFlip)
      {
         oCellData.layerGroundFlip = oNewCell.layerGroundFlip;
      }
      if(bUpdateLayerGroundRot)
      {
         oCellData.layerGroundRot = oNewCell.layerGroundRot;
      }
      if(bUpdateLayerObject1Num)
      {
         oCellData.layerObject1Num = oNewCell.layerObject1Num;
      }
      if(bUpdateLayerObject1Rot)
      {
         oCellData.layerObject1Rot = oNewCell.layerObject1Rot;
      }
      if(bUpdateLayerObject1Flip)
      {
         oCellData.layerObject1Flip = oNewCell.layerObject1Flip;
      }
      if(bUpdateLayerObject2Flip)
      {
         oCellData.layerObject2Flip = oNewCell.layerObject2Flip;
      }
      if(bUpdateLayerObject2Interactive)
      {
         oCellData.layerObject2Interactive = oNewCell.layerObject2Interactive;
      }
      if(bUpdateLayerObject2Num)
      {
         oCellData.layerObject2Num = oNewCell.layerObject2Num;
      }
      if(bUpdateLayerObjectExternal)
      {
         oCellData.layerObjectExternal = oNewCell.layerObjectExternal;
      }
      if(bUpdateLayerObjectExternalInteractive)
      {
         oCellData.layerObjectExternalInteractive = oNewCell.layerObjectExternalInteractive;
      }
      if(bUpdateLayerObjectExternalAutoSize)
      {
         oCellData.layerObjectExternalAutoSize = oNewCell.layerObjectExternalAutoSize;
      }
      oCellData.layerObjectExternalData = oNewCell.layerObjectExternalData;
      this.build(this._oDatacenter.Map,nCellNum);
   }
   function initializeMap(nPermanentLevel)
   {
      if(nPermanentLevel == undefined)
      {
         nPermanentLevel = Number.POSITIVE_INFINITY;
      }
      else
      {
         nPermanentLevel = Number(nPermanentLevel);
      }
      var oMapData = this._oDatacenter.Map;
      if(oMapData.savedBackgroundNum != undefined)
      {
         if(oMapData.savedBackgroundNum == 0)
         {
            oMapData.backgroundNum = 632;
         }
         else
         {
            oMapData.backgroundNum = oMapData.savedBackgroundNum;
         }
      }
      var oCellsData = oMapData.data;
      var oBackupCells = oMapData.originalsCellsBackup.getItems();
      for(var k in oBackupCells)
      {
         this.initializeCell(Number(k),nPermanentLevel);
      }
      this._bTacticMode = false;
   }
   function initializeCell(nCellNum, nPermanentLevel, bSaveTacticMode)
   {
      if(nPermanentLevel == undefined)
      {
         nPermanentLevel = Number.POSITIVE_INFINITY;
      }
      else
      {
         nPermanentLevel = Number(nPermanentLevel);
      }
      var oMapData = this._oDatacenter.Map;
      var oCellsData = oMapData.data;
      var oBackupCellData = oMapData.originalsCellsBackup.getItemAt(String(nCellNum));
      if(oBackupCellData == undefined)
      {
         ank.utils.Logger.err("[MapHandler] (initializeCell) La case est déjà dans son état init");
         return undefined;
      }
      if(oCellsData[nCellNum].nPermanentLevel <= nPermanentLevel)
      {
         if(bSaveTacticMode == true)
         {
            var bIsCellTactic = oCellsData[nCellNum].isTactic(oMapData);
            var oNewCellData = new ank.battlefield.datacenter.Cell();
            for(var cellData in oBackupCellData)
            {
               oNewCellData[cellData] = oBackupCellData[cellData];
            }
            if(bIsCellTactic)
            {
               oNewCellData.turnTactic(this,oMapData);
            }
            oCellsData[nCellNum] = oNewCellData;
            this.build(oMapData,nCellNum);
            if(!bIsCellTactic)
            {
               oMapData.originalsCellsBackup.removeItemAt(String(nCellNum));
            }
         }
         else
         {
            oCellsData[nCellNum] = oBackupCellData;
            this.build(oMapData,nCellNum);
            oMapData.originalsCellsBackup.removeItemAt(String(nCellNum));
         }
      }
   }
   function setObject2Frame(nCellNum, frame)
   {
      if(typeof frame == "number" && frame < 1)
      {
         ank.utils.Logger.err("[setObject2Frame] frame " + frame + " incorecte");
         return undefined;
      }
      if(nCellNum > this.getCellCount())
      {
         ank.utils.Logger.err("[setObject2Frame] Cellule " + nCellNum + " inexistante");
         return undefined;
      }
      var oCellData = this._oDatacenter.Map.data[nCellNum];
      var mcObject2 = oCellData.mcObject2;
      if(ank.battlefield.Constants.USE_STREAMING_FILES && (ank.battlefield.Constants.STREAMING_METHOD == "explod" && !mcObject2.fullLoaded))
      {
         this._oSettingFrames[nCellNum] = frame;
      }
      else if(ank.battlefield.Constants.USE_STREAMING_FILES && ank.battlefield.Constants.STREAMING_METHOD == "explod")
      {
         for(var sPropertyName in mcObject2)
         {
            if(mcObject2[sPropertyName] instanceof MovieClip)
            {
               mcObject2[sPropertyName].gotoAndStop(frame);
            }
         }
      }
      else
      {
         mcObject2.gotoAndStop(frame);
      }
   }
   function setObjectExternalFrame(nCellNum, frame)
   {
      if(typeof frame == "number" && frame < 1)
      {
         ank.utils.Logger.err("[setObject2Frame] frame " + frame + " incorecte");
         return undefined;
      }
      if(nCellNum > this.getCellCount())
      {
         ank.utils.Logger.err("[setObject2Frame] Cellule " + nCellNum + " inexistante");
         return undefined;
      }
      var oCellData = this._oDatacenter.Map.data[nCellNum];
      var mcExternalMovieClip = oCellData.mcObjectExternal._mcExternal;
      mcExternalMovieClip.gotoAndStop(frame);
   }
   function setObject2Interactive(nCellNum, bInteractive, nPermanentLevel)
   {
      if(nCellNum > this.getCellCount())
      {
         ank.utils.Logger.err("[setObject2State] Cellule " + nCellNum + " inexistante");
         return undefined;
      }
      var oCellData = this._oDatacenter.Map.data[nCellNum];
      if(oCellData.mcObject2 == this.api.gfx.rollOverMcObject)
      {
         this.api.gfx.onObjectRollOut(oCellData.mcObject2);
      }
      var oNewCellData = new ank.battlefield.datacenter.Cell();
      oNewCellData.layerObject2Interactive = bInteractive;
      this.updateCell(nCellNum,oNewCellData,"1",nPermanentLevel);
   }
   function getCellCount(Void)
   {
      return this._oDatacenter.Map.data.length;
   }
   function getCellData(nCellNum)
   {
      return this._oDatacenter.Map.data[nCellNum];
   }
   function getCellsData(Void)
   {
      return this._oDatacenter.Map.data;
   }
   function getWidth(Void)
   {
      return this._oDatacenter.Map.width;
   }
   function getHeight(Void)
   {
      return this._oDatacenter.Map.height;
   }
   function getCaseNum(nX, nY)
   {
      var _loc4_ = this.getWidth();
      return nX * _loc4_ + nY * (_loc4_ - 1);
   }
   function getCellHeight(nCellNum)
   {
      var _loc3_ = this.getCellData(nCellNum);
      var _loc4_ = !(_loc3_.groundSlope == undefined || _loc3_.groundSlope == 1) ? 0.5 : 0;
      var _loc5_ = _loc3_.groundLevel != undefined ? _loc3_.groundLevel - 7 : 0;
      return _loc5_ + _loc4_;
   }
   function getLayerByCellPropertyName(oCellPropertyName)
   {
      var aPropertyValues = [];
      for(var i in this._oDatacenter.Map.data)
      {
         aPropertyValues.push(this._oDatacenter.Map.data[i][oCellPropertyName]);
      }
      return aPropertyValues;
   }
   function resetEmptyCells()
   {
      var oSprites = this._mcBattlefield.spriteHandler.getSprites().getItems();
      var oCellWithSprites = [];
      for(var k in oSprites)
      {
         var oSprite = oSprites[k];
         if(!( oSprite.isPendingClearing || (oSprite.isClear || oSprite.mc.gfx._width == 0 && getTimer() - oSprite.creationInstant > 1000)))
         {
            oCellWithSprites[oSprite.cellNum] = true;
         }
      }
      var nCellCount = this.getCellCount();
      var nRemovedSpriteCount = 0;
      var nCellIndex = 0;
      while(nCellIndex < nCellCount)
      {
         if(oCellWithSprites[nCellIndex] != true)
         {
            var oCellData = this._mcBattlefield.mapHandler.getCellData(nCellIndex);
            var nSpriteOnCount = oCellData.spriteOnCount;
            if(nSpriteOnCount != 0)
            {
               nRemovedSpriteCount += nSpriteOnCount;
               oCellData.removeAllSpritesOnID();
            }
         }
         nCellIndex = nCellIndex + 1;
      }
      if(nRemovedSpriteCount > 0)
      {
      }
   }
   function adjustAndMaskMap()
   {
      if(this._nAdjustTimer != undefined)
      {
         _global.clearInterval(this._nAdjustTimer);
         this._nAdjustTimer = undefined;
      }
      this._mcContainer.applyMask(true);
      this._mcContainer.adjusteMap();
   }
   function onLoadInit(mc)
   {
      this._nLoadRequest = this._nLoadRequest - 1;
      if(this._oLoadingCells[mc] == undefined)
      {
         return undefined;
      }
      var aMovieClipPath = String(mc).split(".");
      var sLayerName = aMovieClipPath[aMovieClipPath.length - 2];
      var oCellData = this._oLoadingCells[mc];
      switch(sLayerName)
      {
         case "Ground":
            mc.cacheAsBitmap = _global.CONFIG.cacheAsBitmap["mapHandler/Cell/Ground"];
            mc._x = Number(oCellData.x);
            mc._y = Number(oCellData.y);
            if(oCellData.groundSlope == 1 && oCellData.layerGroundRot != 0)
            {
               mc._rotation = oCellData.layerGroundRot * 90;
               if(mc._rotation % 180)
               {
                  mc._yscale = 192.86;
                  mc._xscale = 51.85;
               }
               else
               {
                  var _loc0_ = null;
                  mc._xscale = _loc0_ = 100;
                  mc._yscale = _loc0_;
               }
            }
            else
            {
               mc._rotation = 0;
               mc._xscale = _loc0_ = 100;
               mc._yscale = _loc0_;
            }
            if(_loc5_.layerGroundFlip)
            {
               mc._xscale *= -1;
            }
            else
            {
               mc._xscale *= 1;
            }
            if(_loc5_.groundSlope != 1)
            {
               mc.gotoAndStop(_loc5_.groundSlope);
            }
            mc.lastGroundID = _loc5_.layerGroundNum;
            break;
         case "Object1":
            mc.cacheAsBitmap = _global.CONFIG.cacheAsBitmap["mapHandler/Cell/Object1"];
            mc._x = Number(_loc5_.x);
            mc._y = Number(_loc5_.y);
            if(_loc5_.groundSlope == 1 && _loc5_.layerObject1Rot != 0)
            {
               mc._rotation = _loc5_.layerObject1Rot * 90;
               if(mc._rotation % 180)
               {
                  mc._yscale = 192.86;
                  mc._xscale = 51.85;
               }
               else
               {
                  mc._xscale = _loc0_ = 100;
                  mc._yscale = _loc0_;
               }
            }
            else
            {
               mc._rotation = 0;
               mc._xscale = _loc0_ = 100;
               mc._yscale = _loc0_;
            }
            if(_loc5_.layerObject1Flip)
            {
               mc._xscale *= -1;
            }
            else
            {
               mc._xscale *= 1;
            }
            mc.lastObject1ID = _loc5_.layerObject1Num;
            break;
         case "Object2":
            mc.cacheAsBitmap = _global.CONFIG.cacheAsBitmap["mapHandler/Cell/Object2"];
            mc._x = Number(_loc5_.x);
            mc._y = Number(_loc5_.y);
            if(_loc5_.layerObject2Interactive)
            {
               mc.__proto__ = ank.battlefield.mc.InteractiveObject.prototype;
               mc.initialize(this._mcBattlefield,_loc5_,true);
            }
            else
            {
               mc.__proto__ = MovieClip.prototype;
            }
            if(_loc5_.layerObject2Flip)
            {
               mc._xscale = -100;
            }
            else
            {
               mc._xscale = 100;
            }
            mc.lastObject2ID = _loc5_.layerObject2Num;
      }
      if(this._oSettingFrames[_loc5_.num] != undefined)
      {
         var _loc6_ = this._oDatacenter.Map.data[_loc5_.num].mcObject2;
         for(var s in _loc6_)
         {
            if(_loc6_[s] instanceof MovieClip)
            {
               _loc6_[s].gotoAndStop(this._oSettingFrames[_loc5_.num]);
            }
         }
         delete this._oSettingFrames[_loc5_.num];
      }
      mc.fullLoaded = true;
      delete this._oLoadingCells[mc];
   }
   function showTriggers()
   {
      var _loc2_ = this.getCellsData();
      for(var i in _loc2_)
      {
         var _loc3_ = _loc2_[i];
         var _loc4_ = _loc3_.isTrigger;
         if(_loc4_)
         {
            this.flagCellNonBlocking(_loc3_.num);
         }
      }
   }
   function showFightCells(sTeam1Cells, sTeam2Cells)
   {
      if(sTeam1Cells == undefined || sTeam2Cells == undefined)
      {
         var _loc4_ = this.api.lang.getMapText(this._oDatacenter.Map.id);
         if(_loc4_.p1 == undefined || _loc4_.p2 == undefined)
         {
            return undefined;
         }
         sTeam1Cells = _loc4_.p1;
         sTeam2Cells = _loc4_.p2;
      }
      this._bShowingFightCells = true;
      var _loc5_ = 0;
      while(_loc5_ < sTeam1Cells.length)
      {
         var _loc6_ = ank.utils.Compressor.decode64(sTeam1Cells.charAt(_loc5_)) << 6;
         _loc6_ += ank.utils.Compressor.decode64(sTeam1Cells.charAt(_loc5_ + 1));
         this.api.gfx.select(_loc6_,dofus.Constants.TEAMS_COLOR[0],"startPosition");
         _loc5_ += 2;
      }
      var _loc7_ = 0;
      while(_loc7_ < sTeam2Cells.length)
      {
         var _loc8_ = ank.utils.Compressor.decode64(sTeam2Cells.charAt(_loc7_)) << 6;
         _loc8_ += ank.utils.Compressor.decode64(sTeam2Cells.charAt(_loc7_ + 1));
         this.api.gfx.select(_loc8_,dofus.Constants.TEAMS_COLOR[1],"startPosition");
         _loc7_ += 2;
      }
   }
   function flagCellNonBlocking(nCellNum, sSprite)
   {
      if(sSprite == undefined)
      {
         sSprite = this.api.datacenter.Player.ID;
      }
      var _loc4_ = new ank.battlefield.datacenter.VisualEffect();
      _loc4_.file = dofus.Constants.CLIPS_PATH + "flag.swf";
      _loc4_.bInFrontOfSprite = true;
      _loc4_.bTryToBypassContainerColor = true;
      this.api.gfx.spriteLaunchVisualEffect(sSprite,_loc4_,nCellNum,11,undefined,undefined,undefined,true,false);
   }
   function drawCellIds()
   {
      var _loc2_ = this._mcContainer.createEmptyMovieClip("mcCellIds",this._mcContainer.getNextHighestDepth());
      _loc2_.cacheAsBitmap = true;
      var _loc3_ = this.validCellsData;
      var _loc4_ = 0;
      while(_loc4_ < _loc3_.length)
      {
         var _loc5_ = _loc3_[_loc4_];
         var _loc6_ = _loc2_.createTextField("cell" + _loc5_.num,_loc2_.getNextHighestDepth(),_loc5_.x,_loc5_.y,0,0);
         _loc6_.selectable = false;
         _loc6_.mouseWheelEnabled = false;
         _loc6_.autoSize = true;
         var _loc7_ = new TextFormat();
         _loc7_.align = "center";
         _loc7_.size = 8;
         if(_loc5_.isTrigger)
         {
            _loc7_.color = 16773939;
         }
         else
         {
            _loc7_.color = 16777215;
         }
         _loc7_.bold = true;
         _loc6_.setNewTextFormat(_loc7_);
         _loc6_._alpha = 70;
         _loc6_.text = String(_loc5_.num);
         _loc6_._x -= _loc6_._width / 2;
         _loc6_._y -= _loc6_._height / 2;
         var _loc8_ = [];
         _loc8_.push(new flash.filters.GlowFilter(0,40,2,2,4,1,false,false));
         _loc6_.filters = _loc8_;
         _loc4_ = _loc4_ + 1;
      }
      return _loc2_;
   }
}
