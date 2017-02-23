classdef MimModelUpdater < CoreBaseClass

    methods (Static)
        function updateModel(localProxy, remoteProxy)
            localCache = localProxy.getCache();
            remoteCache = remoteProxy.getCache();

            if isequal(localCache.CurrentHash, remoteCache.CurrentHash)
                % Model values are in sync

                if ~isempty(localCache.CurrentHash) && ~isempty(remoteCache.CurrentHash)
                    %If both undefined, then ignore
                    
                    % Update local cache if necessary. Do this before we update the remote.
                    if ~isequal(localCache.RemoteHash, remoteCache.CurrentHash)
                        localCache.updateHashes(localCache.CurrentHash, remoteCache.CurrentHash);
                    end
                    
                    % Update remote cache if necessary.
                    if ~isequal(remoteCache.RemoteHash, localCache.CurrentHash)
                        remoteProxy.updateHashes(localCache.CurrentHash, localCache.RemoteHash);
                    end
                end
            else
                % Model values are out of sync
            
                if isempty(localCache.CurrentHash) || (~localCache.hasChanged() && remoteCache.hasChanged())
                    % Server value has changed, but client is unchanged, or client is undefined

                    % If the server provided data then we can update the local value. If not, we can at least update the server about our current hashes which should trigger data sending
                    if remoteProxy.isValueProvided()
                        % Update local cache and value. Local and remote hash
                        % are the same as we are using the server values
                        localCache.updateAndNotify(remoteCache.CurrentHash, remoteCache.CurrentHash, remoteProxy.getCurrentValue());
                    end

                    % Update remote cache if necessary.
                    if ~isequal(remoteCache.RemoteHash, localCache.CurrentHash)
                        remoteProxy.updateHashes(localCache.CurrentHash, localCache.RemoteHash);
                    end
                    
                elseif isempty(remoteCache.CurrentHash) || (localCache.hasChanged() && ~remoteCache.hasChanged())
                    % Client value has changed, but server is unchanged, or server is undefined

                    % Update local cache if necessary. Do this before we update the remote.
                    if ~isequal(localCache.RemoteHash, remoteCache.CurrentHash)
                        localCache.updateHashes(localCache.CurrentHash, remoteCache.CurrentHash);
                    end
                    
                    % Update remote cache and model value
                    remoteProxy.updateAndNotify(localCache.CurrentHash, localCache.RemoteHash, localCache.getCurrentValue());

                elseif (localCache.hasChanged() && remoteCache.hasChanged())
                    % Both have changed -> conflict. We need to make some decision here
                    disp('Conflict');
                    
                else
                    disp('Unexpected'); % Unexpected
                end   
            end
        end
    end
end