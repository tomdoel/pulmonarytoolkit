classdef MimServer < handle
    
    properties (Access = private)
        WebSocketServer
        Mim
        ModelCache
        Updater
        Reporting
    end
    
    methods (Static)
        function start()
            MimServer.getServer().startServer();
        end
        
        function stop()
            MimServer.getServer().stopServer;
        end
        
        function mimServer = getServer()
            persistent mimServerSingleton
            if isempty(mimServerSingleton) || ~isvalid(mimServerSingleton)
                mimServerSingleton = MimServer();
            end
            mimServer = mimServerSingleton;            
        end
    end
    
    methods
        function localUpdateModel(obj, modelName, data, hash)
            modelCacheEntry = obj.ModelCache.getModelCacheEntry(modelName);
            localProxy = MimLocalModelProxy(modelCacheEntry);
            localProxy.updateCurrentValueToNewLocalValue(modelCacheEntry.Hashes, data);
            obj.WebSocketServer.sendTextModel(modelName, hash, modelCacheEntry.Hashes.RemoteHash, [], data);
            
%             obj.Updater.updateModel(localProxy, MimRemoteModelProxy(obj.WebSocketServer, modelName, parsedMessage.value, parsedMessage.modelCacheEntry));
%             obj.Updater.updateModel(MimLocalModelProxy(obj.ModelCache.getModelCacheEntry(modelName)), MimRemoteModelProxy(obj.WebSocketServer, parsedMessage)); % ToDo
%             obj.WebSocketServer.sendTextModel(obj, modelName, serverHash, lastClientHash, metaData, data)            
        end
        
%         function parseMessage(obj, parsedMessage)
%             disp(['Blob message received: version:' parsedMessage.version ' software version:' parsedMessage.softwareVersion ' model:' parsedMessage.modelName ' hash server:' parsedMessage.localHash ' hash last client:' parsedMessage.lastRemoteHash ' value:' parsedMessage.value]);
%             obj.Updater.updateModel(MimLocalModelProxy(obj.ModelCache.getModelCacheEntry(parsedMessage.modelName)), MimRemoteModelProxy(obj.WebSocketServer, parsedMessage.modelName, parsedMessage.value, parsedMessage.modelCacheEntry));
%         end
    end
    
    methods (Access = private)
        function obj = MimServer()
            obj.WebSocketServer = MimWebSocketServer(30000, @obj.parseMessage);
            framework_def = PTKFrameworkAppDef;
            obj.Reporting = MimReporting([], [], 'mimserver.log');
            obj.Mim = MimMain(framework_def, obj.Reporting);
            obj.ModelCache = MimModelCache();
            obj.Updater = MimModelUpdater();
        end
        
        function startServer(obj)
            if ~obj.WebSocketServer.Status
                obj.WebSocketServer.start();
            end
        end
        
        function stopServer(obj)
            obj.WebSocketServer.stop();
        end
    end
end
