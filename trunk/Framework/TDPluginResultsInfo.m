classdef TDPluginResultsInfo < handle
    % TDPluginResultsInfo. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Provides metadata about plugin results, concerning the list of 
    %     dependencies used in generating each result for this dataset.
    %     This data is stored alongside plugin results in the disk cache, and is
    %     used to determine if a particular result is still valid. A result is
    %     still valid if the uid of each dependency in the dependency list 
    %     matches the uid of the current result for the matching plugin.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        ResultsInfo
    end
    
    methods
        function obj = TDPluginResultsInfo
            obj.ResultsInfo = containers.Map;
        end
        
        % Adds dependency record for a particular plugin result
        function AddCachedPluginInfo(obj, plugin_name, cache_info, reporting)
            if obj.ResultsInfo.isKey(plugin_name)
                reporting.Error('TDPluginResultsInfo:CachedInfoAlreadyPresent', 'Cached plugin info already present');
            end
            obj.ResultsInfo(plugin_name) = cache_info;
        end
        
        % Removes the dependency record for a particular plugin result
        function DeleteCachedPluginInfo(obj, plugin_name, ~)
            if obj.ResultsInfo.isKey(plugin_name)
                obj.ResultsInfo.remove(plugin_name);
            end
        end
        
        function valid = CheckDependencyValid(obj, next_dependency, reporting)
            % The full list should always contain the most recent dependency
            % uid, unless the dependencies file was deleted
            if ~obj.ResultsInfo.isKey(next_dependency.PluginName)
                reporting.Log('No dependency record for this plugin - forcing re-run.');
                valid = false;
                return;
            end
            
            current_info = obj.ResultsInfo(next_dependency.PluginName);
            current_dependency = current_info.InstanceIdentifier;
            
            if current_info.IgnoreDependencyChecks
                reporting.Log(['Ignoring dependency checks for plugin ' next_dependency.PluginName]);
            else
                % Sanity check - this case should never occur
                if ~strcmp(next_dependency.DatasetUid, current_dependency.DatasetUid)
                    reporting.Error('TDPluginResultsInfo:DatsetUidError', 'Code error - not matching dataset UID during dependency check');
                end

                if ~strcmp(next_dependency.Uid, current_dependency.Uid)
                    reporting.Log('Mismatch in dependency version uids - forcing re-run');
                    valid = false;
                    return;
                else
                    reporting.Log(['Dependencies Ok for plugin ' next_dependency.PluginName]);
                end
            end
            
            valid = true;
        end
    end
end

