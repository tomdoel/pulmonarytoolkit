classdef MimMarkerSetItem < GemListItem
    % MimMarkerSetItem. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     MimMarkerSetItem represents the controls showing marker set details in the
    %     marker panel of the GUI.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (SetAccess = private)
        MarkerSetFileName
        VisibleName
    end
    
    properties (Constant)
        MarkerSetTextHeight = 18
    end
    
    properties (Access = private)
        MarkerSetControl
        
        GuiCallback
    end
    
    properties (Constant, Access = private)
        MarkerSetFontSize = 16
    end
    
    methods
        function obj = MimMarkerSetItem(parent, name, gui_callback)
            obj = obj@GemListItem(parent, name);
            obj.MarkerSetFileName = name;
            obj.VisibleName = name;
            obj.TextHeight = obj.MarkerSetTextHeight;
            
            if nargin > 0
                obj.GuiCallback = gui_callback;
                
                obj.MarkerSetControl = GemText(obj, obj.VisibleName, 'Select this marker set', 'Marker');
                obj.MarkerSetControl.FontSize = obj.MarkerSetFontSize;
                obj.MarkerSetControl.HorizontalAlignment = 'left';
                obj.AddTextItem(obj.MarkerSetControl);
            end
        end
        
        function Resize(obj, location)
            size_changed = ~isequal(location, obj.Position);
            
            % Don't call the parent class
            Resize@GemVirtualPanel(obj, location);
            
            obj.MarkerSetControl.Resize(location);
            
            % A resize may change the location of the highlighted item            
            if size_changed
                obj.Highlight(false);
            end
        end
    end
    
    methods (Access = protected)
        
        function ItemLeftClicked(obj, src, eventdata)
            ItemLeftClicked@GemListItem(obj, src, eventdata);
            obj.GuiCallback.LoadMarkers(obj.MarkerSetFileName);
        end
        
        function ItemRightClicked(obj, src, eventdata)
            ItemRightClicked@GemListItem(obj, src, eventdata);
            
            if isempty(get(obj.DescriptionControl.GraphicalComponentHandle, 'uicontextmenu'))
                context_menu = uicontextmenu;
                context_menu_delete = uimenu(context_menu, 'Label', 'Delete this marker set', 'Callback', @obj.DeleteMarkerSet);
                obj.SetContextMenu(context_menu);
            end            
        end
    end
    
    methods (Access = private)
        function DeleteMarkerSet(obj, ~, ~)
            parent_figure = obj.GetParentFigure;
            parent_figure.ShowWaitCursor;
            obj.GuiCallback.DeletMarkerSet(obj.MarkerSetFileName);
            
            % Note that at this point obj may have been deleted, so we can no longer use it
            parent_figure.HideWaitCursor;
        end        
    end
end