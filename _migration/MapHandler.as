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
      // Loop through all map cells
      while ((nCellIndex = nCellIndex + 1) < nCellCount)
      {
         // =====================================================
         // GRID POSITIONING (row / column / isometric offset)
         // =====================================================

         // If we reached the last column of the current row
         if (nCol == nMaxCol)
         {
            // Move to next row
            nCol = 0;
            nRow += 1;

            // Alternate horizontal offset for isometric layout
            if (nXOffset == 0)
            {
               nXOffset = nCellHalfWidth;
               nMaxCol -= 1; // odd row → fewer columns
            }
            else
            {
               nXOffset = 0;
               nMaxCol += 1; // even row → more columns
            }
         }
         else
         {
            // Move to next column in the same row
            nCol = nCol + 1;
         }


         // Retrieve cell data
         var oCellData = oCellData[nCellIndex];

         // =====================================================
         // ACTIVE CELL
         // =====================================================

         if (oCellData.active)
         {
            // -------------------------------------------------
            // Compute isometric screen coordinates
            // -------------------------------------------------

            var nCellX = nCol * nCellWidth + nXOffset;
            var nCellY = nRow * nCellHalfHeight - nLevelHeight * (oCellData.groundLevel - 7);

            // Store coordinates in cell data
            oCellData.x = nCellX;
            oCellData.y = nCellY;


            // =================================================
            // GROUND LAYER
            // =================================================

            if (oCellData.layerGroundNum != 0)
            {
               // (streaming logic ignored)

               if (!bRenderingEmptyCells)
               {
                  mcGround =
                     mcExternalContainer.Ground.attach(
                        oCellData.layerGroundNum,
                        "cell" + nCellIndex,
                        nCellIndex
                     );
               }
               else
               {
                  mcGround = new MovieClip();
               }

               mcGround.cacheAsBitmap =
                  _global.CONFIG.cacheAsBitmap["mapHandler/Cell/Ground"];

               mcGround._x = nCellX;
               mcGround._y = nCellY;

               // Apply slope frame
               if (oCellData.groundSlope != 1)
               {
                  mcGround.gotoAndStop(oCellData.groundSlope);
               }
               // Apply rotation if flat ground
               else if (oCellData.layerGroundRot != 0)
               {
                  mcGround._rotation = oCellData.layerGroundRot * 90;

                  // Correct scaling for diagonal rotation
                  if (mcGround._rotation % 180)
                  {
                     mcGround._yscale = 192.86;
                     mcGround._xscale = 51.85;
                  }
               }

               // Horizontal flip
               if (oCellData.layerGroundFlip)
               {
                  mcGround._xscale *= -1;
               }
            }
            else
            {
               // No ground → remove clip
               mcExternalContainer.Ground["cell" + nCellIndex].removeMovieClip();
            }

            // =================================================
            // OBJECT LAYER 1
            // =================================================

            if (oCellData.layerObject1Num != 0)
            {
               // (streaming logic ignored)

               if (!bRenderingEmptyCells)
               {
                  mcObject1 =
                     mcExternalContainer.Object1.attachMovie(
                        oCellData.layerObject1Num,
                        "cell" + nCellIndex,
                        nCellIndex
                     );
               }
               else
               {
                  mcObject1 = new MovieClip();
               }

               mcObject1.cacheAsBitmap =
                  _global.CONFIG.cacheAsBitmap["mapHandler/Cell/Object1"];

               mcObject1._x = nCellX;
               mcObject1._y = nCellY;

               // Rotation only on flat ground
               if (oCellData.groundSlope == 1 && oCellData.layerObject1Rot != 0)
               {
                  mcObject1._rotation = oCellData.layerObject1Rot * 90;

                  if (mcObject1._rotation % 180)
                  {
                     mcObject1._yscale = 192.86;
                     mcObject1._xscale = 51.85;
                  }
               }

               // Horizontal flip
               if (oCellData.layerObject1Flip)
               {
                  mcObject1._xscale *= -1;
               }

               oCellData.mcObject1 = mcObject1;
            }
            else
            {
               mcExternalContainer.Object1["cell" + nCellIndex].removeMovieClip();
            }


            // =================================================
            // OBJECT LAYER 2 (top layer)
            // =================================================

            if (oCellData.layerObject2Num != 0)
            {
               // (streaming logic ignored)

               if (!bRenderingEmptyCells)
               {
                  mcObject2 =
                     mcExternalContainer.Object2.attachMovie(
                        oCellData.layerObject2Num,
                        "cell" + nCellIndex,
                        nCellIndex * 100
                     );
               }
               else
               {
                  mcObject2 = new MovieClip();
               }

               if (mcObject2)
               {
                  mcObject2.cacheAsBitmap =
                     _global.CONFIG.cacheAsBitmap["mapHandler/Cell/Object2"];

                  // Interactive object
                  if (oCellData.layerObject2Interactive)
                  {
                     mcObject2.__proto__ =
                        ank.battlefield.mc.InteractiveObject.prototype;

                     mcObject2.initialize(this._mcBattlefield, oCellData, true);
                  }

                  mcObject2._x = nCellX;
                  mcObject2._y = nCellY;

                  // Horizontal flip
                  if (oCellData.layerObject2Flip)
                  {
                     mcObject2._xscale = -100;
                  }

                  oCellData.mcObject2 = mcObject2;
               }
               else
               {
                  // Cleanup if creation failed
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

         // =====================================================
         // INACTIVE CELL (build-all mode only)
         // =====================================================

         else if (bBuildAll)
         {
            var nInactiveCellX = nCol * nCellWidth + nXOffset;
            var nInactiveCellY = nRow * nCellHalfHeight;

            oCellData.x = nInactiveCellX;
            oCellData.y = nInactiveCellY;

            var mcInactiveCell =
               mcExternalContainer.InteractionCell.attachMovie(
                  "i1",
                  "cell" + nCellIndex,
                  nCellIndex,
                  {_x:nInactiveCellX,_y:nInactiveCellY}
               );

            mcInactiveCell.__proto__ = ank.battlefield.mc.Cell.prototype;
            mcInactiveCell.initialize(this._mcBattlefield);

            oCellData.mc = mcInactiveCell;
            mcInactiveCell.data = oCellData;
         }
      }

      // Only adjust the map when rendering the full map
      // (skip when updating a single cell)
      this.adjustAndMaskMap();

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
      var nMapWidth_n = this.getWidth();
      return nX * nMapWidth_n + nY * (nMapWidth_n - 1);
   }
   function getCellHeight(nCellNum)
   {
      var oCellData_o = this.getCellData(nCellNum);
      var nSlopeOffset_n = !(oCellData_o.groundSlope == undefined || oCellData_o.groundSlope == 1) ? 0.5 : 0;
      var nLevelOffset_n = oCellData_o.groundLevel != undefined ? oCellData_o.groundLevel - 7 : 0;
      return nLevelOffset_n + nSlopeOffset_n;
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
   function adjustAndMaskMap()
   {
      // If an adjustment timer exists, cancel it
      // This prevents repeated or duplicated adjustments
      if (this._nAdjustTimer != undefined)
      {
         _global.clearInterval(this._nAdjustTimer);
         this._nAdjustTimer = undefined;
      }

      // Apply a mask to the map container
      // This limits the visible area of the map
      this._mcContainer.applyMask(true);

      // Adjust the map layout (position / size)
      // Ensures the map fits correctly inside its container
      this._mcContainer.adjusteMap();
   }
}
