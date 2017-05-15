classdef MimPluginResultsInfo < handle
    % MimPluginResultsInfo. Part of the internal MIM framework
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the TD MIM Toolkit.
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
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = protected)
        ResultsInfo
    end
    
    methods
        function obj = MimPluginResultsInfo(info_map)
            % Creates a new cache of plugin infos. To support conversion
            % from legacy classes, an existing map can be passed in;
            % otherwise this argument should be blank and a new map is
            % created
            
            if nargin > 0
                obj.ResultsInfo = info_map;
            else
                obj.ResultsInfo = containers.Map;
            end
        end
        
        function AddCachedPluginInfo(obj, plugin_name, cache_info, context, cache_type, reporting)
            % Adds dependency record for a particular plugin result
            plugin_key = MimPluginResultsInfo.GetKey(plugin_name, context, cache_type);
            if obj.ResultsInfo.isKey(plugin_key)
                reporting.Error('MimPluginResultsInfo:CachedInfoAlreadyPresent', 'Cached plugin info already present');
            end
            obj.ResultsInfo(plugin_key) = cache_info;
        end
        
        function DeleteCachedPluginInfo(obj, plugin_name, context, cache_type, ~)
            % Removes the dependency record for a particular plugin result
            plugin_key = MimPluginResultsInfo.GetKey(plugin_name, context, cache_type);
            if obj.ResultsInfo.isKey(plugin_key)
                obj.ResultsInfo.remove(plugin_key);
            end
        end
        
        function updated = UpdateCachedPluginInfo(obj, plugin_name, cache_info, context, cache_type, reporting)
            % Updates the cache info if the existance of the result has changed
            plugin_key = MimPluginResultsInfo.GetKey(plugin_name, context, cache_type);
            result_exists = ~isempty(cache_info);
            cache_exists = obj.ResultsInfo.isKey(plugin_key);
            
            if (result_exists && ~cache_exists)
                obj.AddCachedPluginInfo(plugin_name, cache_info, context, cache_type, reporting);
                updated = true;
                return;
            end
            
            if (~result_exists && cache_exists)
                obj.DeleteCachedPluginInfo(plugin_name, cache_info, context, cache_type, reporting);
                updated = true;
                return;
            end
            
            updated = false;            
        end
        
        function [valid, edited_key_exists] = CheckDependencyValid(obj, next_dependency, reporting)
            % Checks a given dependency against the cached values to
            % determine if it is valid (ie it depends on the most recent
            % computed results)
            
            if isfield(next_dependency.Attributes, 'IsEditedResult')
                is_edited_result = next_dependency.Attributes.IsEditedResult;
            else
                is_edited_result = false;
            end
            
            if isfield(next_dependency.Attributes, 'IsManualSegmentation')
                is_manual = next_dependency.Attributes.IsManualSegmentation;
            else
                is_manual = false;
            end
            
            if isfield(next_dependency.Attributes, 'IsMarkerSet')
                is_marker = next_dependency.Attributes.IsMarkerSet;
            else
                is_marker = false;
            end
            
            if is_manual
                type_of_dependency = 'manual segmentation';
            else
                type_of_dependency = 'plugin';
            end
            
            plugin_key_nonedited = MimPluginResultsInfo.GetKey(next_dependency.PluginName, next_dependency.Context, MimCacheType.Results);
            plugin_key_edited = MimPluginResultsInfo.GetKey(next_dependency.PluginName, next_dependency.Context, MimCacheType.Edited);
            
            edited_key_exists = obj.ResultsInfo.isKey(plugin_key_edited);
            
            if is_edited_result
                plugin_key = plugin_key_edited;
            elseif is_manual
                plugin_key = MimPluginResultsInfo.GetKey(next_dependency.PluginName, next_dependency.Context, MimCacheType.Manual);
            elseif is_marker          
                plugin_key = MimPluginResultsInfo.GetKey(next_dependency.PluginName, next_dependency.Context, MimCacheType.Markers);
            else
                plugin_key = plugin_key_nonedited;
            end
            
            % The full list should always contain the most recent dependency
            % uid, unless the dependencies file was deleted
            if ~obj.ResultsInfo.isKey(plugin_key)
                reporting.Log(['No dependency record for this ' type_of_dependency ' - forcing re-run.']);
                valid = false;
                return;
            end
            
            current_info = obj.ResultsInfo(plugin_key);
            current_dependency = current_info.InstanceIdentifier;
            
            if current_info.IgnoreDependencyChecks
                reporting.Log(['Ignoring dependency checks for ' type_of_dependency ' ' next_dependency.PluginName '(' char(next_dependency.Context) ')']);
            else
                % Sanity check - this case should never occur
                if ~strcmp(next_dependency.DatasetUid, current_dependency.DatasetUid)
                    reporting.Error('MimPluginResultsInfo:DatsetUidError', 'Code error - not matching dataset UID during dependency check');
                end

                if ~strcmp(next_dependency.Uid, current_dependency.Uid)
                    reporting.Log('Mismatch in dependency version uids - forcing re-run');
                    valid = false;
                    return;
                else
                    reporting.LogVerbose(['Dependencies Ok for ' type_of_dependency ' ' next_dependency.PluginName]);
                end
            end
            
            valid = true;
        end
    end
    
    methods (Static, Access = private)
        function plugin_key = GetKey(plugin_name, context, cache_type)
            if isempty(context)
                plugin_key = plugin_name;
            else
                plugin_key = [plugin_name '.' char(context)];
            end
            
            % For non plugin results, append to the key to ensure keys from
            % different caches don't clash
            if ~(CoreCompareUtilities.CompareEnumName(cache_type, MimCacheType.Results))
                plugin_key = [plugin_key, '_' char(cache_type)];
            end
        end
    end
end

