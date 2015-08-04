classdef PTKAppDef < handle
    % PTKAppDef. Defines application information
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    methods
        function [preferred_context, plugin_to_use] = GetPreferredContext(obj, modality)
            % Returns the context that should be automatically used for
            % this dataset, or [] to indicate use the oritinal image
            
            if isempty(modality) || strcmp(modality, 'CT')
                preferred_context = PTKContext.LungROI;
                plugin_to_use = 'PTKLungROI';
            else
                preferred_context = [];
                plugin_to_use = [];
            end
        end

        function name = GetName(obj)
            name = PTKSoftwareInfo.Name;
        end
        
        function name = GetVersion(obj)
            name = PTKSoftwareInfo.Version;
        end
        
        function direction = GetDefaultOrientation(obj)
            direction = PTKImageOrientation.Coronal;
        end
        
        function style_sheet = GetDefaultStyleSheet(obj)
            style_sheet = PTKDefaultStyleSheet;
        end
        
    end
end
