classdef PTKManualSegmentationMode < handle
    % PTKManualSegmentationMode. Part of the internal gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
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
        AppDef
        ViewerPanel
        GuiDataset
        Settings
        Reporting
        
        Dataset
        SegmentationName
        VisibleName
        Context
        PluginInfo
        
        ImageBeforeEdit
        
        UnsavedChanges
        IgnoreOverlayChanges
        ImageOverlayLock
    end
    
    methods
        function obj = PTKManualSegmentationMode(viewer_panel, gui_dataset, app_def, settings, reporting)
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
            obj.SegmentationName = current_segmentation_name;
            obj.VisibleName = current_visible_plugin_name;
            obj.UnsavedChanges = false;
            
            if (obj.ViewerPanel.OverlayImage.ImageExists)
                obj.ImageBeforeEdit = obj.ViewerPanel.OverlayImage.Copy;
            else 
                obj.ImageBeforeEdit = obj.ViewerPanel.BackgroundImage.BlankCopy;
                obj.ImageBeforeEdit.ChangeRawImage(zeros(obj.ImageBeforeEdit.ImageSize, 'uint8'));
            end
            
            obj.ViewerPanel.SetModes(PTKModes.EditMode, PTKSubModes.PaintEditing);
            obj.IgnoreOverlayChanges = false;            
        end
        
        function sub_mode = GetSubModeName(obj)
            sub_mode = obj.ViewerPanel.SubMode;
        end
        
        function ExitMode(obj)
            
            if obj.UnsavedChanges
                choice = questdlg(['Do you wish to save your edits for ', obj.SegmentationName, '?'], ...
                    'Delete edited results', 'Save', 'Delete', 'Save');
                switch choice
                    case 'Save'
                        obj.SaveEdit;
                    case 'Delete'
                        obj.SaveEditBackup;
                end
                
            end
            obj.Dataset = [];
            obj.SegmentationName = [];
            obj.VisibleName = [];
            obj.Context = [];
            obj.UnsavedChanges = false;
            obj.IgnoreOverlayChanges = true;            
        end
        
        function SaveEdit(obj)
            if ~isempty(obj.SegmentationName)
                obj.LockImageChangedCallback;
                obj.Reporting.ShowProgress(['Saving edited image for ', obj.VisibleName]);
                edited_result = obj.ViewerPanel.OverlayImage.Copy;
                
                template = obj.GuiDataset.GetTemplateImage;
                edited_result.ResizeToMatch(template);
                
                obj.Dataset.SaveManualSegmentation(obj.SegmentationName, edited_result, PTKContext.OriginalImage);
                obj.UnsavedChanges = false;
                obj.GuiDataset.UpdateEditedStatus(true);
                obj.Reporting.CompleteProgress;
                obj.UnLockImageChangedCallback;                
            end
        end
        
        function DeleteAllEditsWithPrompt(obj)
            if ~isempty(obj.SegmentationName)
                obj.LockImageChangedCallback;
                
                choice = questdlg(['Do you wish to delete your edits for ', obj.VisibleName, '? All your edits will be lost.'], ...
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
            if ~isempty(obj.SegmentationName)
                obj.LockImageChangedCallback;
                
                choice = questdlg('You are about to import an edited result. This will delete and replace any existing edits you have made. Do you wish to continue?', ...
                    'Import edited results', 'Import', 'Cancel', 'Import');
                switch choice
                    case 'Import'
                        obj.ReplaceEditWithPatch(patch);
                    case 'Cancel'
                end
                obj.UnLockImageChangedCallback;
            end
        end
        
        
        function ImportEdit(obj)
            if ~isempty(obj.SegmentationName)
                obj.LockImageChangedCallback;
                
                choice = questdlg('You are about to import an edited result. This will delete and replace any existing edits you have made for this plugin. Do you wish to continue?', ...
                    'Import edited results', 'Import', 'Cancel', 'Import');
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
            
            path_name = PTKSaveAs(edited_result, patient_name, path_name, true, obj.Reporting);
            if ~isempty(path_name)
                obj.Settings.SetLastSaveImagePath(path_name, obj.Reporting);
            end
        end

        function ExportPatch(obj)
            obj.SaveEdit;
            edited_result = obj.ViewerPanel.OverlayImage.Copy;
            template = obj.GuiDataset.GetTemplateImage;
            edited_result.ResizeToMatch(template);
            path_name = obj.Settings.SaveImagePath;
            
            patch = PTKEditedResultPatch;
            image_info = obj.GuiDataset.GetImageInfo;
            patch.SeriesUid = image_info.ImageUid;
            patch.SegmentationName = obj.SegmentationName;
            patch.EditedResult = edited_result;
            
            path_name = PTKSavePatchAs(patch, path_name, obj.Reporting);
            if ~isempty(path_name)
                obj.Settings.SetLastSaveImagePath(path_name, obj.Reporting);
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
            if ~isempty(obj.SegmentationName)
                obj.LockImageChangedCallback;                
                obj.Reporting.ShowProgress(['Abandoning edited image for ', obj.VisibleName]);
                edited_result = obj.ViewerPanel.OverlayImage;
                obj.Dataset.SaveData('AbandonedEdits', edited_result);
                obj.UnsavedChanges = false;
                obj.GuiDataset.UpdateEditedStatus(true);
                obj.Reporting.CompleteProgress;
                obj.UnLockImageChangedCallback;                
            end            
        end
        
        function DeleteAllEdits(obj)
            obj.Reporting.ShowProgress(['Deleting edited image for ', obj.VisibleName]);
            obj.UnsavedChanges = false;
            obj.Reporting.CompleteProgress;            
        end

        function ReplaceEditWithPatch(obj, patch)
            if ~isempty(obj.SegmentationName)
                obj.LockImageChangedCallback;
                obj.Reporting.ShowProgress(['Replacing edited image for ', obj.VisibleName]);
                
                current_overlay = obj.ViewerPanel.OverlayImage;
                edited_result = patch.EditedResult;
                edited_result.ImageType = current_overlay.ImageType;
                
                template = obj.GuiDataset.GetTemplateImage;
                if ~isequal(template.ImageSize, edited_result.ImageSize)
                    uiwait(errordlg('The edited results image cannot be imported as the image size does not match the original image', [obj.AppDef.GetName ': Cannot import edited results for ' obj.VisibleName], 'modal'));
                elseif ~isequal(template.VoxelSize, edited_result.VoxelSize)
                    uiwait(errordlg('The edited results image cannot be imported as the voxel size does not match the original image', [obj.AppDef.GetName ': Cannot import edited results for ' obj.VisibleName], 'modal'));
                else
                    obj.Dataset.SaveManualSegmentation(obj.SegmentationName, edited_result, obj.Context);
                    obj.UnsavedChanges = false;
                    obj.GuiDataset.UpdateEditedStatus(true);
                end
                
                obj.Reporting.CompleteProgress;
                obj.UnLockImageChangedCallback;
            end
        end
                    
        function ChooseAndReplaceEdit(obj)
            if ~isempty(obj.SegmentationName)
                obj.LockImageChangedCallback;
                obj.Reporting.ShowProgress(['Replacing edited image for ', obj.VisibleName]);
                
                image_info = PTKChooseImagingFiles(obj.Settings.SaveImagePath, obj.Reporting);
                
                if ~isempty(image_info)
                    obj.Settings.SetLastSaveImagePath(image_info.ImagePath, obj.Reporting);
                    
                    current_overlay = obj.ViewerPanel.OverlayImage;
                    edited_result = PTKLoadImages(image_info, obj.Reporting);
                    edited_result.ImageType = current_overlay.ImageType;
                    
                    template = obj.GuiDataset.GetTemplateImage;
                    if ~isequal(template.ImageSize, edited_result.ImageSize)
                        uiwait(errordlg('The edited results image cannot be imported as the image size does not match the original image', [obj.AppDef.GetName ': Cannot import edited results for ' obj.VisibleName], 'modal'));
                    elseif ~isequal(template.VoxelSize, edited_result.VoxelSize)
                        uiwait(errordlg('The edited results image cannot be imported as the voxel size does not match the original image', [obj.AppDef.GetName ': Cannot import edited results for ' obj.VisibleName], 'modal'));
                    else
                        obj.Dataset.SaveManualSegmentation(obj.SegmentationName, edited_result, obj.Context);
                        obj.UnsavedChanges = false;
                    end
                end
                
                obj.Reporting.CompleteProgress;
                obj.UnLockImageChangedCallback;
            end
            
        end
    end
end