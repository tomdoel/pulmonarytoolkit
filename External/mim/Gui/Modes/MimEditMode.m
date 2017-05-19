classdef MimEditMode < handle
    % MimEditMode. Part of the internal gui for the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the TD MIM Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (SetObservable)
        Flags
    end
    
    properties (SetAccess = private)
        AllowAutomaticModeEntry = false % Determines whether the mode can be entered automatically when the dataset or result is changed
        ExitOnNewPlugin = true % Mode will exit if a new plugin result is called
    end
    
    properties (Access = private)
        AppDef
        ViewerPanel
        GuiDataset
        Settings
        Reporting
        
        Dataset
        PluginName
        VisibleEditName
        Context
        PluginInfo
        
        ManualSegmentationName
        
        ImageBeforeEdit
        
        UnsavedChanges
        IgnoreOverlayChanges
        ImageOverlayLock
    end
    
    methods
        function obj = MimEditMode(viewer_panel, gui_dataset, app_def, settings, reporting)
            obj.ViewerPanel = viewer_panel;
            obj.GuiDataset = gui_dataset;
            obj.AppDef = app_def;
            obj.Settings = settings;
            obj.Reporting = reporting;
            obj.UnsavedChanges = false;
            obj.IgnoreOverlayChanges = true;
            obj.ImageOverlayLock = 0;
        end
        
        function EnterMode(obj, current_dataset, plugin_info, current_plugin_name, current_visible_plugin_name, current_context, current_segmentation_name)
            obj.Context = current_context;
            obj.Dataset = current_dataset;
            obj.PluginInfo = plugin_info;
            obj.PluginName = current_plugin_name;
            obj.ManualSegmentationName = current_segmentation_name;
            obj.VisibleEditName = current_visible_plugin_name;
            if isempty(plugin_info) && ~isempty(current_segmentation_name)
                obj.VisibleEditName = current_segmentation_name;
            end
            
            obj.UnsavedChanges = false;
            
            if ~isempty(plugin_info)
                obj.ImageBeforeEdit = obj.ViewerPanel.OverlayImage.Copy;
                
                if strcmp(plugin_info.SubMode, MimSubModes.EditBoundariesEditing)
                    obj.ViewerPanel.SetModes(MimModes.EditMode, MimSubModes.EditBoundariesEditing);
                    
                elseif strcmp(plugin_info.SubMode, MimSubModes.FixedBoundariesEditing)
                    obj.ViewerPanel.SetModes(MimModes.EditMode, MimSubModes.FixedBoundariesEditing);
                    
                elseif strcmp(plugin_info.SubMode, MimSubModes.ColourRemapEditing)
                    obj.ViewerPanel.SetModes(MimModes.EditMode, MimSubModes.ColourRemapEditing);
                    
                elseif strcmp(plugin_info.SubMode, MimSubModes.PaintEditing)
                    obj.ViewerPanel.SetModes(MimModes.EditMode, MimSubModes.PaintEditing);
                    
                else
                    obj.ViewerPanel.SetModes(MimModes.EditMode, []);
                end
            elseif ~isempty(obj.ManualSegmentationName)
                 obj.ImageBeforeEdit = obj.ViewerPanel.OverlayImage.Copy;
                 obj.ViewerPanel.SetModes(MimModes.EditMode, MimSubModes.PaintEditing);
                 % Manual edit mode always defaults to paint over
                 % background
                 obj.ViewerPanel.PaintOverBackground = true;

                 % Manual edit mode always defaults to painting rather then
                 % deleting
                 if obj.ViewerPanel.PaintBrushColour < 1
                     obj.ViewerPanel.PaintBrushColour = 1;
                 end
            end
            obj.IgnoreOverlayChanges = false;            
        end
        
        function sub_mode = GetSubModeName(obj)
            sub_mode = obj.ViewerPanel.SubMode;
        end
        
        function ExitMode(obj)
            
            if obj.UnsavedChanges
                choice = questdlg(['Do you wish to save your edits for ', obj.VisibleEditName, '?'], ...
                    'Edits have not been saved', 'Save', 'Delete', 'Save');
                switch choice
                    case 'Save'
                        obj.SaveEdit();
                    case 'Delete'
                        obj.SaveEditBackup();
                end
                
            end
            obj.Dataset = [];
            obj.PluginName = [];
            obj.ManualSegmentationName = [];
            obj.VisibleEditName = [];
            obj.Context = [];
            obj.UnsavedChanges = false;
            obj.IgnoreOverlayChanges = true;            
        end
        
        function SaveEdit(obj)
            if ~isempty(obj.PluginName) || ~isempty(obj.ManualSegmentationName)

                obj.LockImageChangedCallback;
                obj.Reporting.ShowProgress(['Saving edited image for ', obj.VisibleEditName]);
                edited_result = obj.ViewerPanel.OverlayImage;
                if ~isempty(obj.PluginName)
                    obj.Dataset.SaveEditedResult(obj.PluginName, edited_result, obj.Context);
                else
                    obj.Dataset.SaveManualSegmentation(obj.ManualSegmentationName, edited_result);
                end
                obj.UnsavedChanges = false;
                obj.GuiDataset.UpdateEditedStatus(true);
                obj.Reporting.CompleteProgress;
                obj.UnLockImageChangedCallback;                
            end
        end
        
        function DeleteAllEditsWithPrompt(obj)
            if ~isempty(obj.PluginName) || ~isempty(obj.ManualSegmentationName)
                obj.LockImageChangedCallback;
                
                choice = questdlg(['Do you wish to delete your edits for ', obj.VisibleEditName, '? All your manual edits will be lost if you choose delete.'], ...
                    'Delete edited results', 'Delete', 'Don''t delete', 'Don''t delete');
                switch choice
                    case 'Delete'
                        obj.DeleteAllEdits;
                    case 'Don''t delete'
                end
                obj.UnLockImageChangedCallback;
            end
        end
        
        function ImportPatch(obj, patch)
            if ~isempty(obj.PluginName)
                obj.LockImageChangedCallback;
                
                choice = questdlg('You are about to import an edited result. This will delete and replace any existing edits you have made for this plugin. Do you wish to continue?', ...
                    'Import edited results', 'Import', 'Cancel', 'Import');
                switch choice
                    case 'Import'
                        obj.ReplaceEditWithPatch(patch);
                    case 'Cancel'
                end
                obj.UnLockImageChangedCallback;
            end
            
            % TODO: edits
        end
        
        
        function ImportEdit(obj)
            if ~isempty(obj.PluginName) || ~isempty(obj.ManualSegmentationName)
                obj.LockImageChangedCallback;
                
                choice = questdlg('You are about to import a segmentation. This will delete and replace any existing edits you have made for this segmentation. Do you wish to continue?', ...
                    'Import segmentation', 'Import', 'Cancel', 'Import');
                switch choice
                    case 'Import'
                        obj.ChooseAndReplaceEdit;
                    case 'Cancel'
                end
                obj.UnLockImageChangedCallback;
            end
        end
        
        function ExportEdit(obj)
            obj.SaveEdit;
            edited_result = obj.ViewerPanel.OverlayImage.Copy;
            patient_name = obj.ViewerPanel.BackgroundImage.Title;
            template = obj.GuiDataset.GetTemplateImage;
            edited_result.ResizeToMatch(template);
            path_name = obj.Settings.SaveImagePath;            
            path_name = MimSaveAs(edited_result, patient_name, path_name, true, obj.AppDef.GetDicomMetadata, obj.Reporting);
            if ~isempty(path_name)
                obj.Settings.SetLastSaveImagePath(path_name, obj.Reporting);
            end
        end

        function ExportPatch(obj)
            if ~isempty(obj.PluginName)
                obj.SaveEdit;
                edited_result = obj.ViewerPanel.OverlayImage.Copy;
                template = obj.GuiDataset.GetTemplateImage;
                edited_result.ResizeToMatch(template);
                path_name = obj.Settings.SaveImagePath;

                patch = PTKEditedResultPatch();
                image_info = obj.GuiDataset.GetImageInfo;
                patch.SeriesUid = image_info.ImageUid;
                patch.PluginName = obj.PluginName;
                patch.EditedResult = edited_result;

                path_name = MimSavePatchAs(patch, path_name, obj.Reporting);
                if ~isempty(path_name)
                    obj.Settings.SetLastSaveImagePath(path_name, obj.Reporting);
                end
            end
        end

        function OverlayImageChanged(obj, ~, ~)
            if obj.ImageOverlayLock < 1
                obj.UnsavedChanges = true;
            end
        end
        
        function MarkOverlayAsUnchanged(obj)
            obj.UnsavedChanges = false;
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
                obj.Reporting.ShowProgress(['Abandoning edited image for ', obj.VisibleEditName]);
                edited_result = obj.ViewerPanel.OverlayImage;
                obj.Dataset.SaveData('AbandonedEdits', edited_result);
                obj.UnsavedChanges = false;
                obj.GuiDataset.UpdateEditedStatus(true);
                obj.Reporting.CompleteProgress;
                obj.UnLockImageChangedCallback;                
            end            
        end
        
        function DeleteAllEdits(obj)
            obj.Reporting.ShowProgress(['Deleting edits for ', obj.VisibleEditName]);
            if ~isempty(obj.PluginName)
                obj.Dataset.DeleteEditedResult(obj.PluginName);
                obj.UnsavedChanges = false;
                obj.GuiDataset.RunPlugin(obj.PluginName, obj.Reporting.ProgressDialog);
            elseif ~isempty(obj.ManualSegmentationName)
                obj.GuiDataset.LoadManualSegmentationCallback(obj.ManualSegmentationName);
                obj.UnsavedChanges = false;
            end
            obj.GuiDataset.UpdateEditedStatus(false);
            obj.GuiDataset.ChangeMode(MimModes.EditMode);
            obj.Reporting.CompleteProgress;
        end

        function ReplaceEditWithPatch(obj, patch)
            if ~isempty(obj.PluginName)
                obj.LockImageChangedCallback;
                obj.Reporting.ShowProgress(['Replacing edited image for ', obj.VisibleEditName]);
                
                current_overlay = obj.ViewerPanel.OverlayImage;
                edited_result = patch.EditedResult;
                edited_result.ImageType = current_overlay.ImageType;
                
                template = obj.GuiDataset.GetTemplateImage;
                if max(abs(template.ImageSize - edited_result.ImageSize)) > 0.001
                    uiwait(errordlg('The edited results image cannot be imported as the image size does not match the original image', [obj.AppDef.GetName ': Cannot import edited results for ' obj.VisibleEditName], 'modal'));
                elseif max(abs(template.VoxelSize - edited_result.VoxelSize)) > 0.001
                    uiwait(errordlg('The edited results image cannot be imported as the voxel size does not match the original image', [obj.AppDef.GetName ': Cannot import edited results for ' obj.VisibleEditName], 'modal'));
                else
                    obj.Dataset.SaveEditedResult(obj.PluginName, edited_result, obj.Context);
                    obj.UnsavedChanges = false;
                    obj.GuiDataset.UpdateEditedStatus(true);
                    
                    % Update the loaded results
                    obj.GuiDataset.RunPlugin(obj.PluginName, obj.Reporting.ProgressDialog);
                    obj.GuiDataset.UpdateEditedStatus(false);
                    
                    % Ensure we are back in edit mode, as RunPlugin will have left this
                    obj.GuiDataset.ChangeMode(MimModes.EditMode);
                end
                
                obj.Reporting.CompleteProgress;
                obj.UnLockImageChangedCallback;
            end
        end
                    
        function ChooseAndReplaceEdit(obj)
            if ~isempty(obj.PluginName) || ~isempty(obj.ManualSegmentationName)
                obj.LockImageChangedCallback;
                obj.Reporting.ShowProgress(['Replacing edits image for ', obj.VisibleEditName]);
                
                image_info = MimChooseImagingFiles(obj.Settings.SaveImagePath, obj.Reporting);
                
                if ~isempty(image_info)
                    obj.Settings.SetLastSaveImagePath(image_info.ImagePath, obj.Reporting);
                    
                    current_overlay = obj.ViewerPanel.OverlayImage;
                    edited_result = MimLoadImages(image_info, obj.Reporting);
                    edited_result.ImageType = current_overlay.ImageType;
                    
                    template = obj.GuiDataset.GetTemplateImage;
                    if max(abs(template.ImageSize - edited_result.ImageSize)) > 0.001
                        uiwait(errordlg('The edits cannot be imported as the image size does not match the original image', [obj.AppDef.GetName ': Cannot import edits for ' obj.VisibleEditName], 'modal'));
                    elseif max(abs(template.VoxelSize - edited_result.VoxelSize)) > 0.001
                        uiwait(errordlg('The edits cannot be imported as the voxel size does not match the original image', [obj.AppDef.GetName ': Cannot import edits for ' obj.VisibleEditName], 'modal'));
                    else
                        edited_result.ResizeToMatch(current_overlay);
                        if ~isempty(obj.PluginName)
                            obj.Dataset.SaveEditedResult(obj.PluginName, edited_result, obj.Context);
                            obj.GuiDataset.UpdateEditedStatus(true);
                            % Update the loaded results
                            obj.GuiDataset.RunPlugin(obj.PluginName, obj.Reporting.ProgressDialog);
                            obj.UnsavedChanges = false;
                        elseif ~isempty(obj.ManualSegmentationName)
                            obj.Dataset.SaveManualSegmentation(obj.ManualSegmentationName, edited_result);
                            obj.GuiDataset.LoadManualSegmentationCallback(obj.ManualSegmentationName);
                            obj.UnsavedChanges = false;
                        end
                        
                        % Ensure we are back in edit mode, as RunPlugin will have left this
                        obj.GuiDataset.ChangeMode(MimModes.EditMode);
                    end
                end
                
                obj.Reporting.CompleteProgress;
                obj.UnLockImageChangedCallback;
            end
            
        end
    end
end