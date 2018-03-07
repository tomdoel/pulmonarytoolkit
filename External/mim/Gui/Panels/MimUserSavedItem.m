classdef MimUserSavedItem < GemListItem
    % MimUserSavedItem. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    %     MimUserSavedItem is used in a list box to show a list of cached
    %     items that are available for the user to select, such as markers or
    %     manual segmentations.
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (SetAccess = private)
        CacheFileName
        VisibleName
    end
    
    properties (Constant)
        UserSavedItemTextHeight = 21
    end
    
    properties (Access = private)
        TextControl
        
        LoadCallback
        DeleteCallback
        RenameCallback
        DuplicateCallback
        AddCallback
    end
    
    properties (Constant, Access = private)
        UserSavedItemFontSize = 14
    end
    
    methods
        function obj = MimUserSavedItem(parent, name, tooltip, load_callback, delete_callback, rename_callback, duplicate_callback, add_callback)
            obj = obj@GemListItem(parent, name);
            obj.CacheFileName = name;
            obj.VisibleName = name;
            obj.TextHeight = obj.UserSavedItemTextHeight;
            
            if nargin > 0
                obj.LoadCallback = load_callback;
                obj.DeleteCallback = delete_callback;
                obj.RenameCallback = rename_callback;
                obj.DuplicateCallback = duplicate_callback;
                obj.AddCallback = add_callback;
                
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
            
            if isempty(get(obj.TextControl.GraphicalComponentHandle, 'uicontextmenu'))
                context_menu = uicontextmenu;
                context_menu_delete = uimenu(context_menu, 'Label', 'Delete', 'Callback', @obj.DeleteCachedItem);
                context_menu_rename = uimenu(context_menu, 'Label', 'Rename', 'Callback', @obj.RenameCachedItem);
                context_menu_duplicate = uimenu(context_menu, 'Label', 'Duplicate', 'Callback', @obj.DuplicateCachedItem);
                context_menu_add = uimenu(context_menu, 'Label', 'Add', 'Callback', @obj.AddCachedItem);
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

        function RenameCachedItem(obj, ~, ~)
            parent_figure = obj.GetParentFigure;
            parent_figure.ShowWaitCursor;
            obj.RenameCallback(obj.CacheFileName);
            parent_figure.HideWaitCursor;
        end        
        
        function DuplicateCachedItem(obj, ~, ~)
            parent_figure = obj.GetParentFigure;
            parent_figure.ShowWaitCursor;
            obj.DuplicateCallback(obj.CacheFileName);
            parent_figure.HideWaitCursor;
        end        
        
        function AddCachedItem(obj, ~, ~)
            parent_figure = obj.GetParentFigure;
            parent_figure.ShowWaitCursor;
            obj.AddCallback();
            parent_figure.HideWaitCursor;
        end        
    end
end