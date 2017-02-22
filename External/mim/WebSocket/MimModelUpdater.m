classdef MimModelUpdater < CoreBaseClass

    methods
        function obj = MimModelUpdater()
        end
        
        function updateModel(obj, clientProxy, serverProxy)
            clientCache = clientProxy.getHashes();
            serverCache = serverProxy.getHashes();

            if isequal(clientCache.CurrentHash, serverCache.CurrentHash)
                % Model values are in sync

                if ~isempty(clientCache.CurrentHash) && ~isempty(serverCache.CurrentHash)
                    %If both undefined, then ignore
                    
                    % Update local cache if necessary. Do this before we update the server.
                    if ~isequal(clientCache.RemoteHash, serverCache.CurrentHash)
                        clientProxy.updateLastRemoteHash(serverCache);
                    end
                    
                    % Update remote cache if necessary.
                    if ~isequal(serverCache.RemoteHash, clientCache.CurrentHash)
                        serverProxy.updateLastRemoteHash(clientCache);
                    end
                end
            else
                % Model values are out of sync
            
                if isempty(clientCache.CurrentHash) || (~clientCache.hasChanged() && serverCache.hasChanged())
                    % Server value has changed, but client is unchanged, or client is undefined
                    
                    % Update local cache and value
                    clientProxy.updateCurrentValueToRemoteValue(serverCache, serverProxy.getCurrentValue());

                    % Update remote cache if necessary.
                    if ~isequal(serverCache.RemoteHash, clientCache.CurrentHash)
                        serverProxy.updateLastRemoteHash(clientCache);
                    end
                    
                elseif isempty(serverCache.CurrentHash) || (clientCache.hasChanged() && ~serverCache.hasChanged())
                    % Client value has changed, but server is unchanged, or server is undefined

                    % Update local cache if necessary. Do this before we update the server.
                    if ~isequal(clientCache.RemoteHash, serverCache.CurrentHash)
                        clientProxy.updateLastRemoteHash(serverCache);
                    end
                    
                    % Update remote cache and model value
                    serverProxy.updateCurrentValueToRemoteValue(clientCache, clientCache.getCurrentValue());

                elseif (clientCache.hasChanged() && serverCache.hasChanged())
                    % Both have changed -> conflict. We need to make some decision here
                    disp('Conflict');
                    
                else
                    disp('Unexpected'); % Unexpected
                end   
            end
        end
    end
end