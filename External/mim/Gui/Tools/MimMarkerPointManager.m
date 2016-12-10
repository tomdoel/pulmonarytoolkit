classdef MimMarkerPointManager < CoreBaseClass
    % MimMarkerPointManager. Part of the internal gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (SetAccess = private)
    end
    
    properties (Access = private)
        MarkerLayer
        MarkerPointImage
        MarkerDisplayParameters
        ViewerPanel
        Gui
        GuiDataset
        AppDef
        Reporting
        
        MarkersHaveBeenLoaded = false
        CurrentMarkersName
    end
    
    methods
        function obj = MimMarkerPointManager(marker_layer, marker_image_source, marker_display_parameters, viewer_panel, gui, gui_dataset, app_def, reporting)
            obj.MarkerLayer = marker_layer;
            obj.MarkerPointImage = marker_image_source;
            obj.MarkerDisplayParameters = marker_display_parameters;
            obj.ViewerPanel = viewer_panel;
            obj.Gui = gui;
            obj.GuiDataset = gui_dataset;
            obj.AppDef = app_def;
            obj.Reporting = reporting;
        end
        
        function ClearMarkers(obj)
            obj.MarkersHaveBeenLoaded = false;
            obj.CurrentMarkersName = [];
            obj.ViewerPanel.MarkerImageSource.Image.Reset;
        end
        
        function AutoSaveMarkers(obj)
            if ~isempty(obj.MarkerLayer) && obj.MarkerLayer.MarkerImageHasChanged && obj.MarkersHaveBeenLoaded
                saved_marker_points = obj.GuiDataset.LoadMarkers(obj.CurrentMarkersName);
                current_marker_points = obj.MarkerLayer.GetMarkerImage.Image;
                markers_changed = false;
                if isempty(saved_marker_points)
                    if any(current_marker_points.RawImage(:))
                        markers_changed = true;
                    end
                else
                    if ~isequal(saved_marker_points.RawImage, current_marker_points.RawImage)
                        markers_changed = true;
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
                                obj.SaveMarkers;
                            case 'Don''t save'
                                obj.SaveMarkersBackup;
                                disp('Abandoned changes have been stored in AbandonedMarkerPoints.mat');
                        end
                    else
                        obj.SaveMarkers;
                    end
                end
            end
        end
        
        function SaveMarkersManualBackup(obj)
            if obj.GuiDataset.DatasetIsLoaded
                markers = obj.MarkerLayer.GetMarkerImage;
                obj.GuiDataset.SaveMarkers('MarkerPointsLastManualSave', markers);
            end
        end
        
        function LoadMarkersIfRequired(obj, name)
            if obj.IsLoadMarkersRequired
                obj.LoadMarkers(name);
            end
        end
        
        function load_required = IsLoadMarkersRequired(obj)
            load_required = ~obj.MarkersHaveBeenLoaded && (obj.ViewerPanel.MarkerImageDisplayParameters.ShowMarkers || obj.ViewerPanel.IsInMarkerMode);
        end
        
        function LoadMarkers(obj, name)
            new_image = obj.GuiDataset.LoadMarkers(name);
            if ~isempty(new_image)
                obj.MarkerLayer.GetMarkerImage.SetBlankMarkerImage(obj.ViewerPanel.GetBackgroundImageSource.Image);
                obj.MarkerLayer.ChangeMarkerSubImage(new_image);
            end
            obj.MarkersHaveBeenLoaded = true;
            obj.CurrentMarkersName = name;
        end
    end
    
    methods (Access = private)
        function SaveMarkers(obj)
            if obj.GuiDataset.DatasetIsLoaded
                if isempty(obj.CurrentMarkersName)
                    obj.Reporting.Error('MimMarkerPointManager:NoMarkerFilename', 'The markers could not be saved as the marker filename has not been specified. ');
                end
                obj.Reporting.ShowProgress('Saving Markers');
                markers = obj.MarkerLayer.GetMarkerImage.Image;
                obj.GuiDataset.SaveMarkers(obj.CurrentMarkersName, markers);
                obj.MarkerLayer.MarkerPointsHaveBeenSaved;
                obj.Reporting.CompleteProgress;
            end
        end
        
        function SaveMarkersBackup(obj)
            if obj.GuiDataset.DatasetIsLoaded
                obj.Reporting.ShowProgress('Abandoning Markers');                
                markers = obj.MarkerLayer.GetMarkerImage;
                obj.GuiDataset.SaveMarkers('AbandonedMarkerPoints', markers);
                obj.Reporting.CompleteProgress;
            end
        end        
    end
end

