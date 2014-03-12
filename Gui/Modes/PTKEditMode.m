classdef PTKEditMode < handle
    % PTKEditMode. Part of the internal gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (SetObservable)
        Flags
    end
    
    properties (SetAccess = private)
        AllowAutomaticModeEntry = false % Determines whether the mode can be entered automatically when the dataset or result is changed
        ExitOnNewPlugin = true % Mode will exit if a new plugin result is called
    end
    
    properties (Access = private)
        ViewerPanel
        GuiDataset
        Reporting
        
        Dataset
        PluginName
        VisiblePluginName
        Context
        PluginInfo
        
        ImageBeforeEdit
        
        UnsavedChanges
        IgnoreOverlayChanges
        ImageOverlayLock
    end
    
    methods
        function obj = PTKEditMode(viewer_panel, gui_dataset, reporting)
            obj.ViewerPanel = viewer_panel;
            obj.GuiDataset = gui_dataset;
            obj.Reporting = reporting;
            obj.UnsavedChanges = false;
            obj.IgnoreOverlayChanges = true;
            obj.ImageOverlayLock = 0;
        end
        
        function EnterMode(obj, current_dataset, plugin_info, current_plugin_name, current_visible_plugin_name, current_context)
            obj.Context = current_context;
            obj.Dataset = current_dataset;
            obj.PluginInfo = plugin_info;
            obj.PluginName = current_plugin_name;
            obj.VisiblePluginName = current_visible_plugin_name;
            obj.UnsavedChanges = false;
            
            if ~isempty(plugin_info)
                obj.ImageBeforeEdit = obj.ViewerPanel.OverlayImage.Copy;
                
                if strcmp(plugin_info.SubMode, PTKSubModes.EditBoundariesEditing)
                    obj.ViewerPanel.SetModes(PTKModes.EditMode, PTKSubModes.EditBoundariesEditing);
                    
                elseif strcmp(plugin_info.SubMode, PTKSubModes.FixedBoundariesEditing)
                    obj.ViewerPanel.SetModes(PTKModes.EditMode, PTKSubModes.FixedBoundariesEditing);
                    
                elseif strcmp(plugin_info.SubMode, PTKSubModes.ColourRemapEditing)
                    obj.ViewerPanel.SetModes(PTKModes.EditMode, PTKSubModes.EditColourRemap);
                    
                else
                    obj.ViewerPanel.SetModes(PTKModes.EditMode, []);
                end
            end
            obj.IgnoreOverlayChanges = false;            
        end
        
        function ExitMode(obj)
            
            if obj.UnsavedChanges
                choice = questdlg(['Do you wish to save your edits for ', obj.VisiblePluginName, '?'], ...
                    'Delete edited results', 'Save', 'Delete', 'Save');
                switch choice
                    case 'Save'
                        obj.SaveEdit;
                    case 'Delete'
                        obj.SaveEditBackup;
                end
                
            end
            obj.Dataset = [];
            obj.PluginName = [];
            obj.VisiblePluginName = [];
            obj.Context = [];
            obj.UnsavedChanges = false;
            obj.IgnoreOverlayChanges = true;            
        end
        
        function SaveEdit(obj)
            if ~isempty(obj.PluginName)
                obj.LockImageChangedCallback;
                obj.Reporting.ShowProgress(['Saving edited image for ', obj.VisiblePluginName]);
                edited_result = obj.ViewerPanel.OverlayImage;
                obj.Dataset.SaveEditedResult(obj.PluginName, edited_result, obj.Context);
                obj.UnsavedChanges = false;
                obj.GuiDataset.UpdateFigureTitle(obj.VisiblePluginName, true);
                obj.Reporting.CompleteProgress;
                obj.UnLockImageChangedCallback;                
            end
        end
        
        function DeleteAllEditsWithPrompt(obj)
            if ~isempty(obj.PluginName)
                obj.LockImageChangedCallback;
                
                choice = questdlg(['Do you wish to delete your edits for ', obj.VisiblePluginName, '? All your edits will be lost and replaced with the automatically computed results.'], ...
                    'Delete edited results', 'Delete', 'Don''t delete', 'Don''t delete');
                switch choice
                    case 'Delete'
                        obj.DeleteAllEdits;
                    case 'Don''t delete'
                end
                obj.UnLockImageChangedCallback;
            end
        end
                
        function OverlayImageChanged(obj, ~, ~)
            if obj.ImageOverlayLock < 1
                obj.UnsavedChanges = true;
            end
        end
    end
    
    methods (Access = private)
        function LockImageChangedCallback(obj)
            obj.ImageOverlayLock = obj.ImageOverlayLock + 1;
        end
        
        function UnLockImageChangedCallback(obj)
            obj.ImageOverlayLock = max(0, obj.ImageOverlayLock - 1);
        end
        
        function SaveEditBackup(obj)
            if ~isempty(obj.PluginName)
                obj.LockImageChangedCallback;                
                obj.Reporting.ShowProgress(['Abandoning edited image for ', obj.VisiblePluginName]);
                edited_result = obj.ViewerPanel.OverlayImage;
                obj.Dataset.SaveData('AbandonedEdits', edited_result);
                obj.UnsavedChanges = false;
                obj.GuiDataset.UpdateFigureTitle(obj.VisiblePluginName, true);
                obj.Reporting.CompleteProgress;
                obj.UnLockImageChangedCallback;                
            end            
        end
        
        function DeleteAllEdits(obj)
            obj.Reporting.ShowProgress(['Deleting edited image for ', obj.VisiblePluginName]);
            obj.Dataset.DeleteEditedResult(obj.PluginName);
            obj.UnsavedChanges = false;
            obj.GuiDataset.RunPlugin(obj.PluginName, obj.Reporting.ProgressDialog);
            obj.GuiDataset.UpdateFigureTitle(obj.VisiblePluginName, false);
            obj.Reporting.CompleteProgress;            
        end

        function RevertEdit(obj)
            edited_result = obj.ImageBeforeEdit;
            ptk_gui_app.SaveEditedResult(edited_result);
        end
    end
end