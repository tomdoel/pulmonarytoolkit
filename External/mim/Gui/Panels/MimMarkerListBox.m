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
            obj.Update;
        end
         
        function Update(obj)
            obj.ListBox.ClearItems;
            
            marker_sets = obj.GuiCallback.GetListOfMarkerSets;
            if ~isempty(marker_sets)
                for marker_index = 1 : length(marker_sets)
                    marker_set = marker_sets{marker_index};
                    gui_callback = obj.GuiCallback;
                    marker_item = MimUserSavedItem(obj.ListBox.GetListBox, marker_set.Second, 'Select this marker set', @gui_callback.LoadMarkers, @gui_callback.DeleteMarkerSet);

                    obj.ListBox.AddItem(marker_item);
                end

                current_marker_set = obj.GuiCallback.GetCurrentMarkerSetName;
                
                % Resize as new marker sets may have been added
                if ~isempty(obj.Position)
                    obj.Resize(obj.Position);
                end
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
            obj.Update;
        end
        
        function DeleteButtonClicked(obj, ~, ~)
        end
    end
    

    methods (Access = private)
    end    
end