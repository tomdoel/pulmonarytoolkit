classdef MimMarkerPointManager < CoreBaseClass
    % MimMarkerPointManager. Part of the internal gui for the TD MIM Toolkit.
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
    
    properties (Access = private)
        MarkerLayer
        MarkerPointImage
        BackgroundImageSource
        MarkerDisplayParameters
        ViewerPanel
        Gui
        GuiDataset
        AppDef
        Reporting
        
        MarkersHaveBeenLoaded = false
        MarkerImageHasUnsavedChanges = false
        MarkerSetInitialSave = false
    end
    
    events
        SavedMarkerListChanged
    end
    
    properties (SetObservable, SetAccess = private)
        CurrentMarkersName
    end
    
    methods
        function obj = MimMarkerPointManager(marker_layer, marker_image_source, marker_display_parameters, background_image_source, viewer_panel, gui, gui_dataset, app_def, reporting)
            obj.MarkerLayer = marker_layer;
            obj.MarkerPointImage = marker_image_source;
            obj.BackgroundImageSource = background_image_source;
            obj.MarkerDisplayParameters = marker_display_parameters;
            obj.ViewerPanel = viewer_panel;
            obj.Gui = gui;
            obj.GuiDataset = gui_dataset;
            obj.AppDef = app_def;
            obj.Reporting = reporting;
            obj.AddEventListener(marker_image_source, 'MarkerImageHasChanged', @obj.MarkerImageChangedCallback);
            obj.AddEventListener(background_image_source, 'NewImage', @obj.BackgroundImageChangedCallback);
            obj.AddEventListener(background_image_source, 'ImageModified', @obj.BackgroundImageChangedCallback);
        end
        
        function ClearMarkers(obj)
            obj.MarkersHaveBeenLoaded = false;
            obj.CurrentMarkersName = [];
            obj.MarkerPointImage.ClearMarkers();
            obj.ResetImageChangedFlag();
        end
        
        function AutoSaveMarkers(obj)
            if ~isempty(obj.MarkerLayer) && obj.MarkerImageHasUnsavedChanges && obj.MarkersHaveBeenLoaded
                saved_marker_points = obj.GuiDataset.LoadMarkers(obj.CurrentMarkersName);
                current_marker_points = obj.GetMarkersToSave();
                markers_changed = false;
                if isempty(saved_marker_points)
                    if ~isempty(current_marker_points.MarkerList)
                        markers_changed = true;
                    end
                else
                    if isa(saved_marker_points, 'PTKImage')
                        markers_changed = true;
                    else
                        if ~isequal(saved_marker_points.MarkerList, current_marker_points.MarkerList)
                            markers_changed = true;
                        end
                    end
                end
                
                if markers_changed
                    
                    % Depending on the software settings, the user can be prompted before saving
                    % changes to the markers
                    if obj.AppDef.ConfirmBeforeSavingMarkers
                        choice = questdlg('Do you want to save the changes you have made to the current markers?', ...
                            'Unsaved changes to markers', 'Delete changes', 'Save', 'Save');
                        switch choice
                            case 'Save'
                                obj.SaveMarkers();
                            case 'Don''t save'
                                obj.SaveMarkersBackup();
                                disp('Abandoned changes have been stored in AbandonedMarkerPoints.mat');
                        end
                    else
                        obj.SaveMarkers();
                    end
                end
            end
        end
        
        function SaveMarkersManualBackup(obj)
            if obj.GuiDataset.DatasetIsLoaded()
                markers = obj.GetMarkersToSave();
                obj.GuiDataset.SaveMarkers('MarkerPointsLastManualSave', markers);
            end
        end
        
        function LoadMarkersIfRequired(obj, name)
            if obj.IsLoadMarkersRequired()
                obj.LoadMarkers(name);
            end
        end
        
        function load_required = IsLoadMarkersRequired(obj)
            load_required = ~obj.MarkersHaveBeenLoaded && (obj.MarkerDisplayParameters.ShowMarkers || obj.ViewerPanel.IsInMarkerMode);
        end
        
        function LoadMarkers(obj, name)
            obj.AutoSaveMarkers();
            new_marker_list = obj.GuiDataset.LoadMarkers(name);
            if isempty(new_marker_list)
                new_marker_image = GemMarkerPointImage(zeros(0,4));
            else
                new_marker_image = GemMarkerPointImage(new_marker_list.ConvertToMarkerList());
            end
            obj.MarkerPointImage.LoadMarkers(new_marker_image);
            if isempty(new_marker_list)
                obj.SaveMarkers();
            end
            obj.ResetImageChangedFlag();
            obj.MarkersHaveBeenLoaded = true;
            obj.CurrentMarkersName = name;
        end
        
        function current_markers = GetCurrentMarkerSetName(obj)
            current_markers = obj.CurrentMarkersName;
        end
        
        function AddMarkerSet(obj, name)
            obj.SaveMarkers();
            obj.LoadMarkers(name);
            obj.SaveMarkers();
            notify(obj, 'SavedMarkerListChanged');
        end
        
        function DeleteMarkerSet(obj, name)
            obj.GuiDataset.DeleteMarkerSet(name);
            if strcmp(name, obj.GetCurrentMarkerSetName())
                obj.ClearMarkers();
            end
            notify(obj, 'SavedMarkerListChanged');
        end
    end
    
    methods (Access = private)
        function SaveMarkers(obj)
            if obj.GuiDataset.DatasetIsLoaded()
                if isempty(obj.CurrentMarkersName)
                    if ~isempty(obj.MarkerPointImage.MarkerList)
                        obj.Reporting.Error('MimMarkerPointManager:NoMarkerFilename', 'The markers could not be saved as the marker filename has not been specified. ');
                    end
                else
                    obj.Reporting.ShowProgress('Saving Markers');
                    markers = obj.GetMarkersToSave();
                    obj.GuiDataset.SaveMarkers(obj.CurrentMarkersName, markers);
                    obj.ResetImageChangedFlag();
                    obj.Reporting.CompleteProgress();
                end
            end
        end
        
        function marker_list_to_save = GetMarkersToSave(obj)
            image_to_save = obj.MarkerPointImage.GetImageToSave(obj.BackgroundImageSource.Image);
            series_uid = obj.GuiDataset.GetUidOfCurrentDataset();
            marker_list_to_save = MimMarkerList(image_to_save, series_uid);
        end
        
        function SaveMarkersBackup(obj)
            if obj.GuiDataset.DatasetIsLoaded
                obj.Reporting.ShowProgress('Abandoning Markers');                
                markers = obj.GetMarkersToSave();
                obj.GuiDataset.SaveMarkers('AbandonedMarkerPoints', markers);
                obj.Reporting.CompleteProgress;
            end
        end
        
        function BackgroundImageChangedCallback(obj, ~, ~)
            obj.MarkerPointImage.BackgroundImageChanged(obj.BackgroundImageSource.Image);
            obj.MarkerLayer.MarkerImageChanged();
            obj.ResetImageChangedFlag();
        end
        
        function MarkerImageChangedCallback(obj, ~, ~)
            obj.MarkerImageHasUnsavedChanges = true;
        end
        
        function ResetImageChangedFlag(obj)
            obj.MarkerImageHasUnsavedChanges = false;
        end
    end
end

