classdef MimPreviewFetcher < handle
    % MimPreviewFetcher. Part of the internal framework of the Pulmonary Toolkit.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)        
        GuiDataset
    end
    
    methods
        function obj =  MimPreviewFetcher(gui_dataset)
            obj.GuiDataset = gui_dataset;
        end
        
        function preview = FetchPreview(obj, plugin_name)
            preview = obj.GuiDataset.FetchPreview(plugin_name);
        end
    end
end