classdef MimSegmentPanel < GemPanel
    % MimSegmentPanel. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    %     MimSegmentPanel shows segmentation tool buttons and a list of
    %     manual segmentations
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (Access = private)
        SegmentToolbar
        ManualSegmentationListBox
        
        OrderedControlGroupList
        GuiApp
        ModeTabName
        ModeToSwitchTo
        AppDef
        Visibility
        State
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
        function obj = MimSegmentPanel(parent, organised_plugins, mode_tab_name, mode_to_switch_to, visibility, gui_app, app_def, gui_dataset_state, group_vertically, allow_wrapping)
            obj = obj@GemPanel(parent);
            
            obj.TopBorder = false;
            obj.AppDef = app_def;
            obj.GuiApp = gui_app;
            obj.State = gui_dataset_state;
            
            obj.SegmentToolbar = MimToolbarPanel(obj, organised_plugins, mode_tab_name, mode_to_switch_to, visibility, gui_app, app_def, group_vertically, allow_wrapping);
            obj.AddChild(obj.SegmentToolbar);
            
            obj.ManualSegmentationListBox = MimUserSavedItemListBox(obj, 'manual segmentation', @gui_app.LoadSegmentationCallback, @gui_app.DeleteManualSegmentation, @gui_app.AddManualSegmentation, @gui_app.RenameManualSegmentation, @gui_app.DuplicateManualSegmentation, @gui_app.GetListOfManualSegmentations, @gui_app.CurrentSegmentationName);
            obj.ManualSegmentationListBox.TopBorder = true;
            obj.ManualSegmentationListBox.TitleLeftPadding = 5;
            obj.AddChild(obj.ManualSegmentationListBox);
            
            obj.ModeTabName = mode_tab_name;
            obj.ModeToSwitchTo = mode_to_switch_to;
            obj.Visibility = visibility;
            
            obj.AddEventListener(gui_dataset_state, 'PluginChangedEvent', @obj.SegmentationChangedCallback);
            obj.AddEventListener(obj.ManualSegmentationListBox, 'ListChanged', @obj.SegmentationListChangedCallback);
            obj.AddEventListener(gui_dataset_state, 'ManualSegmentationsChanged', @obj.ManualSegmentationsChangedCallback);
        end
        
        function SegmentationChangedCallback(obj, ~, ~)
            obj.ManualSegmentationListBox.SelectSetPanel(obj.State.CurrentSegmentationName, true);
        end
        
        function ManualSegmentationsChangedCallback(obj, ~, ~)
            obj.ManualSegmentationListBox.Update();
            obj.Update(obj.GuiApp);
        end
        
        function SegmentationListChangedCallback(obj, ~, ~)
            obj.ManualSegmentationListBox.Update();
            obj.Update(obj.GuiApp);
        end
        
        function Resize(obj, new_position)
            Resize@GemPanel(obj, new_position);
            
            % After calling Resize@GemPanel, the position will have been adjusted due to the border
            new_position = obj.InnerPosition;            
            
            panel_height = max(0, new_position(4));
            toolbar_height = obj.SegmentToolbar.GetRequestedHeight(new_position(3));
            toolbar_position = new_position;
            toolbar_position(2) = new_position(2) + panel_height - toolbar_height;
            toolbar_position(4) = toolbar_height;
            
            listbox_height = obj.ManualSegmentationListBox.GetRequestedHeight(new_position(3));
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
            
            obj.SegmentToolbar.Resize(toolbar_position);
            obj.ManualSegmentationListBox.Resize(listbox_position);
        end
        
        function Update(obj, gui_app)
            % Calls each group panel and updates the controls. In some cases, controls will
            % become enabled that were previously disabled; this requires the position
            % (since this may not have been set if this is the first time the control has been made visible)
            
            obj.SegmentToolbar.Update(gui_app);
             
            if ~isempty(obj.Position)
                obj.Resize(obj.Position);
            end
            
        end
        
        function height = GetRequestedHeight(obj, width)
            height = obj.SegmentToolbar.GetRequestedHeight(width) + obj.ManualSegmentationListBox.GetRequestedHeight(width);
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
            obj.SegmentToolbar.AddPlugins(current_dataset);
        end
        
        function UpdateForNewImage(obj, current_dataset, window, level)
            obj.SegmentToolbar.UpdateForNewImage(current_dataset, window, level);
            obj.ManualSegmentationListBox.UpdateForNewImage(current_dataset, window, level);
        end
        
        function AddPreviewImage(obj, plugin_name, preview_fetcher, window, level)
            obj.SegmentToolbar.AddPreviewImage(plugin_name, preview_fetcher, window, level);
        end

        function RefreshPlugins(obj, current_dataset, window, level)
            obj.SegmentToolbar.RefreshPlugins(current_dataset, window, level);
        end 
    end
end