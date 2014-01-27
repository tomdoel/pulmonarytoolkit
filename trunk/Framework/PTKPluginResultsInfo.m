classdef PTKPluginResultsInfo < handle
    % PTKPluginResultsInfo. Part of the internal framework of the Pulmonary Toolkit.
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
        function obj = PTKPluginResultsInfo
            obj.ResultsInfo = containers.Map;
        end
        
        % Adds dependency record for a particular plugin result
        function AddCachedPluginInfo(obj, plugin_name, cache_info, context, is_edited, reporting)
            plugin_key = obj.GetKey(plugin_name, context, is_edited);
            if obj.ResultsInfo.isKey(plugin_key)
                reporting.Error('PTKPluginResultsInfo:CachedInfoAlreadyPresent', 'Cached plugin info already present');
            end
            obj.ResultsInfo(plugin_key) = cache_info;
        end
        
        % Removes the dependency record for a particular plugin result
        function DeleteCachedPluginInfo(obj, plugin_name, context, is_edited, ~)
            plugin_key = obj.GetKey(plugin_name, context, is_edited);
            if obj.ResultsInfo.isKey(plugin_key)
                obj.ResultsInfo.remove(plugin_key);
            end
        end
        
        function valid = CheckDependencyValid(obj, next_dependency, reporting)
            if isfield(next_dependency.Attributes, 'IsEditedResult')
                is_edited_result = next_dependency.Attributes.IsEditedResult;
            else
                is_edited_result = false;
            end
            plugin_key = obj.GetKey(next_dependency.PluginName, next_dependency.Context, is_edited_result);
            
            % The full list should always contain the most recent dependency
            % uid, unless the dependencies file was deleted
            if ~obj.ResultsInfo.isKey(plugin_key)
                reporting.Log('No dependency record for this plugin - forcing re-run.');
                valid = false;
                return;
            end
            
            current_info = obj.ResultsInfo(plugin_key);
            current_dependency = current_info.InstanceIdentifier;
            
            if current_info.IgnoreDependencyChecks
                reporting.Log(['Ignoring dependency checks for plugin ' next_dependency.PluginName '(' char(next_dependency.Context) ')']);
            else
                % Sanity check - this case should never occur
                if ~strcmp(next_dependency.DatasetUid, current_dependency.DatasetUid)
                    reporting.Error('PTKPluginResultsInfo:DatsetUidError', 'Code error - not matching dataset UID during dependency check');
                end

                if ~strcmp(next_dependency.Uid, current_dependency.Uid)
                    reporting.Log('Mismatch in dependency version uids - forcing re-run');
                    valid = false;
                    return;
                else
                    reporting.LogVerbose(['Dependencies Ok for plugin ' next_dependency.PluginName]);
                end
            end
            
            valid = true;
        end
    end
    
    methods (Static, Access = private)
        function plugin_key = GetKey(plugin_name, context, is_edited)
            if isempty(context)
                plugin_key = plugin_name;
            else
                plugin_key = [plugin_name '.' char(context)];
            end
            
            if is_edited
                plugin_key = [plugin_key, '_Edited'];
            end
        end
    end
end

