classdef MimUserSavedItem < GemListItem
    % MimUserSavedItem. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     MimUserSavedItem is used in a list box to show a list of cached
    %     items that are available for the user to select, such as markers or
    %     manual segmentations.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (SetAccess = private)
        CacheFileName
        VisibleName
    end
    
    properties (Constant)
        UserSavedItemTextHeight = 18
    end
    
    properties (Access = private)
        TextControl
        
        LoadCallback
        DeleteCallback
    end
    
    properties (Constant, Access = private)
        UserSavedItemFontSize = 16
    end
    
    methods
        function obj = MimUserSavedItem(parent, name, tooltip, load_callback, delete_callback)
            obj = obj@GemListItem(parent, name);
            obj.CacheFileName = name;
            obj.VisibleName = name;
            obj.TextHeight = obj.UserSavedItemTextHeight;
            
            if nargin > 0
                obj.LoadCallback = load_callback;
                obj.DeleteCallback = delete_callback;
                
                obj.TextControl = GemText(obj, obj.VisibleName, tooltip, 'ItemSelect');
                obj.TextControl.FontSize = obj.UserSavedItemFontSize;
                obj.TextControl.HorizontalAlignment = 'left';
                obj.AddTextItem(obj.TextControl);
            end
        end
        
        function Resize(obj, location)
            size_changed = ~isequal(location, obj.Position);
            
            % Don't call the parent class
            Resize@GemVirtualPanel(obj, location);
            
            obj.TextControl.Resize(location);
            
            % A resize may change the location of the highlighted item            
            if size_changed
                obj.Highlight(false);
            end
        end
    end
    
    methods (Access = protected)
        
        function ItemLeftClicked(obj, src, eventdata)
            ItemLeftClicked@GemListItem(obj, src, eventdata);
            obj.LoadCallback(obj.CacheFileName);
        end
        
        function ItemRightClicked(obj, src, eventdata)
            ItemRightClicked@GemListItem(obj, src, eventdata);
            
            if isempty(get(obj.DescriptionControl.GraphicalComponentHandle, 'uicontextmenu'))
                context_menu = uicontextmenu;
                context_menu_delete = uimenu(context_menu, 'Label', 'Delete', 'Callback', @obj.DeleteCachedItem);
                obj.SetContextMenu(context_menu);
            end            
        end
    end
    
    methods (Access = private)
        function DeleteCachedItem(obj, ~, ~)
            parent_figure = obj.GetParentFigure;
            parent_figure.ShowWaitCursor;
            obj.DeleteCallback(obj.CacheFileName);
            
            % Note that at this point obj may have been deleted, so we can no longer use it
            parent_figure.HideWaitCursor;
        end        
    end
end