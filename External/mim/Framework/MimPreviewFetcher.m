classdef MimPreviewFetcher < handle
    % MimPreviewFetcher. Part of the internal framework of the TD MIM Toolkit.
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
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