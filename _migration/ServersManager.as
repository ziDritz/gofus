class dofus.managers.ServersManager extends // Autoload
{
   var _sObjectName;
   var _sFolder;
   var _sFile;
 

   function ready(oAPI, sObjectName, sFolder)
   {
      this._sObjectName = sObjectName;
      this._sFolder = sFolder; // content csv 
   }
   function getData(sFile)
   {
      if(this._sFile == sFile)
      {
         return undefined;
      }
      this._sFile = sFile;
      this.clearTimer();
      this._mcl.unloadClip(this._mc);
      this.api.ui.loadUIComponent("Waiting","Waiting");
      this._aServers = _root._loader.copyAndOrganizeDataServersForDataBank(dofus.utils.DofusTranslator.STANDARD_DATA_BANK);
      this._urlIndex = -1;
      this.loadWithNextURL();
   }
}
