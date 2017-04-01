classdef MimMarkerPanel < GemPanel
    % MimMarkerPanel. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    %     MimMarkerPanel shows marker tool buttons and a list of marker sets
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Access = private)
        MarkerToolbar
        MarkerListBox
        
        GuiApp
        ModeTabName
        ModeToSwitchTo
        AppDef
        Visibility
        
        MarkerManager
    end
    
    properties (Constant)
        ToolbarHeight = 85
        RowHeight = 85
        LeftMargin = 10
        RightMargin = 20
        HorizontalSpacing = 10
        SpacingBetweenLists = 20
    end
    
    methods
        function obj = MimMarkerPanel(parent, gui_dataset_state, marker_manager, organised_plugins, mode_tab_name, mode_to_switch_to, visibility, gui_app, app_def, group_vertically, allow_wrapping)
            obj = obj@GemPanel(parent);
            
            obj.TopBorder = false;
            obj.AppDef = app_def;
            obj.GuiApp = gui_app;
            
            obj.MarkerManager = marker_manager;
            obj.MarkerToolbar = MimToolbarPanel(obj, organised_plugins, mode_tab_name, mode_to_switch_to, visibility, gui_app, app_def, group_vertically, allow_wrapping);
            obj.AddChild(obj.MarkerToolbar);
            
            obj.MarkerListBox = MimUserSavedItemListBox(obj, 'marker set', @gui_app.LoadMarkers, @gui_app.DeleteMarkerSet, @gui_app.AddMarkerSet, @gui_app.GetListOfMarkerSets, @gui_app.GetCurrentMarkerSetName);
            obj.MarkerListBox.TopBorder = true;
            obj.MarkerListBox.TitleLeftPadding = 5;
            obj.AddChild(obj.MarkerListBox);
            
            obj.ModeTabName = mode_tab_name;
            obj.ModeToSwitchTo = mode_to_switch_to;
            obj.Visibility = visibility;
            
            obj.AddPostSetListener(marker_manager, 'CurrentMarkersName', @obj.MarkerSetNameChangedCallback);
            obj.AddEventListener(marker_manager, 'SavedMarkerListChanged', @obj.MarkerListChangedCallback);
            obj.AddEventListener(gui_dataset_state, 'MarkersChanged', @obj.MarkersChangedCallback);
        end
        
        function MarkersChangedCallback(obj, ~, ~)
            obj.MarkerListBox.Update();
            obj.Update();
        end
        
        function MarkerSetNameChangedCallback(obj, ~, ~)
            obj.MarkerListBox.SelectSetPanel(obj.MarkerManager.CurrentMarkersName, true);
        end
        
        function MarkerListChangedCallback(obj, ~, ~)
             obj.MarkerListBox.Update(); % Update the list contents to force the new size
             obj.Update();
        end
        
        function Resize(obj, new_position)
            Resize@GemPanel(obj, new_position);
            
            % After calling Resize@GemPanel, the position will have been adjusted due to the border
            new_position = obj.InnerPosition;            
            
            panel_height = max(0, new_position(4));
            toolbar_height = 315;
            toolbar_position = new_position;
            toolbar_position(2) = new_position(2) + panel_height - toolbar_height;
            toolbar_position(4) = toolbar_height;
            
            listbox_height = obj.MarkerListBox.GetRequestedHeight(new_position(3));
            panel_vertical_gap = panel_height - toolbar_height - listbox_height - obj.SpacingBetweenLists;
            
            % Try to adjust the listbox so it fits in the space available,
            % but ensure it has a minimum size
            if (panel_vertical_gap < 0)
                listbox_height = max(20, listbox_height + panel_vertical_gap);
                panel_vertical_gap = panel_height - toolbar_height - listbox_height - obj.SpacingBetweenLists;
            end
            
            listbox_position = new_position;
            listbox_position(2) = new_position(2) + panel_vertical_gap;
            listbox_position(4) = listbox_height;
            
            obj.MarkerToolbar.Resize(toolbar_position);
            obj.MarkerListBox.Resize(listbox_position);
        end
        
        function Update(obj, gui_app)
            % Calls each group panel and updates the controls. In some cases, controls will
            % become enabled that were previously disabled; this requires the position
            % (since this may not have been set if this is the first time the control has been made visible)
            
            obj.MarkerToolbar.Update(gui_app);
                        
            if ~isempty(obj.Position)
                obj.Resize(obj.Position);
            end
            
        end
        
        function height = GetRequestedHeight(obj, width)
            height = obj.MarkerToolbar.GetRequestedHeight(width) + obj.MarkerListBox.GetRequestedHeight(width);
        end
        
        function mode = GetModeTabName(obj)
            mode = obj.ModeTabName;
        end
        
        function visibility = GetVisibility(obj)
            visibility = obj.Visibility;
        end
        
        function mode = GetModeToSwitchTo(obj)
            mode = obj.ModeToSwitchTo;
        end
        
        function AddPlugins(obj, current_dataset)
            obj.MarkerToolbar.AddPlugins(current_dataset);
        end
        
        function UpdateForNewImage(obj, current_dataset, window, level)
            obj.MarkerToolbar.UpdateForNewImage(current_dataset, window, level);
            obj.MarkerListBox.UpdateForNewImage(current_dataset, window, level);
        end
        
        function AddPreviewImage(obj, plugin_name, preview_fetcher, window, level)
            obj.MarkerToolbar.AddPreviewImage(plugin_name, preview_fetcher, window, level);
        end

        function RefreshPlugins(obj, current_dataset, window, level)
            obj.MarkerToolbar.RefreshPlugins(current_dataset, window, level);
        end 
    end
end