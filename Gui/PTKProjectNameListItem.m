classdef PTKProjectNameListItem < GemListItem
    % PTKProjectNameListItem. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKProjectNameListItem represents the control showing a project name in a
    %     GemListBox
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (Constant)
        ProjectTextHeight = 18
        FontSize = 16
    end
    
    properties (Access = private)
        ProjectNameText        
        ProjectId
        GuiCallback
    end
    
    methods
        function obj = PTKProjectNameListItem(parent, name, project_id, gui_callback)
            obj = obj@GemListItem(parent, project_id);
            obj.TextHeight = obj.ProjectTextHeight;
            
            if nargin > 0
                obj.ProjectId = project_id;
                obj.GuiCallback = gui_callback;

                obj.ProjectNameText = GemText(obj, name, name, 'Project');
                obj.ProjectNameText.FontSize = obj.FontSize;
                obj.AddTextItem(obj.ProjectNameText);
            end
        end
        
        function Resize(obj, location)
            size_changed = ~isequal(location, obj.Position);
            % Don't call the parent class
            Resize@GemVirtualPanel(obj, location);
                        
            obj.ProjectNameText.Resize(location);
            
            % A resize may change the location of the highlighted item
            if size_changed
                obj.Highlight(false);
            end
        end
        
    end
    
    methods (Access = protected)
        
        function ItemLeftClicked(obj, src, eventdata)
            ItemLeftClicked@GemListItem(obj, src, eventdata);
            obj.GuiCallback.ProjectClicked(obj.ProjectId);
        end
        
        function ItemRightClicked(obj, src, eventdata)
            ItemRightClicked@GemListItem(obj, src, eventdata);
            
            if isempty(get(obj.ProjectNameText.GraphicalComponentHandle, 'uicontextmenu'))
                context_menu = uicontextmenu;
                context_menu_project = uimenu(context_menu, 'Label', 'Refresh', 'Callback', @obj.RefreshProjects);
                obj.SetContextMenu(context_menu);
            end
        end
        
    end
    
    methods (Access = private)
        function RefreshProjects(obj, ~, ~)
            obj.GuiCallback.RefreshProjects;
        end
    end
end