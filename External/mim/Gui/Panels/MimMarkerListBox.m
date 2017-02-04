classdef MimMarkerListBox < GemListBoxWithTitle
    % MimMarkerListBox. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     MimMarkerListBox is part of the markers tab page which shows a list of user marker files
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    

    properties (Access = private)
        GuiCallback
    end
    
    methods
        function obj = MimMarkerListBox(parent, gui_callback)
            obj = obj@GemListBoxWithTitle(parent, 'MARKER SETS', 'Add marker set', 'Delete marker set');
            
            obj.GuiCallback = gui_callback;
        end
        
        function UpdateForNewImage(obj, current_dataset, window, level)
            obj.ListBox.ClearItems;
            
            if ~isempty(current_dataset)
                marker_sets = current_dataset.GetListOfMarkerSets;
                for marker_index = 1 : length(marker_sets)
                    marker_set = marker_sets{marker_index};
                    marker_item = MimMarkerSetItem(obj.ListBox.GetListBox, marker_set.Second, obj.GuiCallback);

                    obj.ListBox.AddItem(marker_item);
                end

                current_marker_set = obj.GuiCallback.GetCurrentMarkerSetName;
                obj.ListBox.SelectItem(current_marker_set, true);
            end
            
        end
        
        function SelectMarkerSetPanel(obj, marker_set_name, selected)
            obj.ListBox.SelectItem(marker_set_name, selected);
        end
    end
    
    methods (Access = protected)
        function AddButtonClicked(obj, ~, event_data)
            obj.GuiCallback.AddMarkerSet;
        end
        
        function DeleteButtonClicked(obj, ~, ~)
        end
    end
    

    methods (Access = private)
    end    
end