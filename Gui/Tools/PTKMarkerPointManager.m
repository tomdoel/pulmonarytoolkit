classdef PTKMarkerPointManager < CoreBaseClass
    % PTKMarkerPointManager. Part of the internal gui for the Pulmonary Toolkit.
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
        Reporting
        
        MarkersHaveBeenLoaded = false
    end
    
    methods
        function obj = PTKMarkerPointManager(marker_layer, marker_image_source, marker_display_parameters, viewer_panel, gui, gui_dataset, reporting)
            obj.MarkerLayer = marker_layer;
            obj.MarkerPointImage = marker_image_source;
            obj.MarkerDisplayParameters = marker_display_parameters;
            obj.ViewerPanel = viewer_panel;
            obj.Gui = gui;
            obj.GuiDataset = gui_dataset;
            obj.Reporting = reporting;
        end
        
        function ClearMarkers(obj)
            obj.MarkersHaveBeenLoaded = false;
            obj.ViewerPanel.MarkerImageSource.Image.Reset;
        end
        
        function AutoSaveMarkers(obj)
            if ~isempty(obj.MarkerLayer) && obj.MarkerLayer.MarkerImageHasChanged && obj.MarkersHaveBeenLoaded
                saved_marker_points = obj.GuiDataset.LoadMarkers;
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
                    if PTKSoftwareInfo.ConfirmBeforeSavingMarkers
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
        
        function LoadMarkersIfRequired(obj)
            if ~obj.MarkersHaveBeenLoaded && (obj.ViewerPanel.ShowMarkers || obj.ViewerPanel.IsInMarkerMode)
                obj.LoadMarkers;
            end
        end
        
        function LazyLoadMarkerImage(obj)
            if (obj.ViewerPanel.MarkerImageDisplayParameters.ShowMarkers || obj.ViewerPanel.IsInMarkerMode) && ~obj.MarkersHaveBeenLoaded
                obj.Gui.LoadMarkers;
            end
        end
        
        function LoadMarkers(obj)
            new_image = obj.GuiDataset.LoadMarkers;
            if isempty(new_image)
                disp('No previous markers found for this image');
            else
                obj.MarkerLayer.GetMarkerImage.SetBlankMarkerImage(obj.ViewerPanel.GetBackgroundImageSource.Image);
                obj.MarkerLayer.ChangeMarkerSubImage(new_image);
            end
            obj.MarkersHaveBeenLoaded = true;
        end
    end
    
    methods (Access = private)
        function SaveMarkers(obj)
            if obj.GuiDataset.DatasetIsLoaded
                obj.Reporting.ShowProgress('Saving Markers');
                markers = obj.MarkerLayer.GetMarkerImage.Image;
                obj.GuiDataset.SaveMarkers(PTKSoftwareInfo.MakerPointsCacheName, markers);
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

