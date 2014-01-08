classdef PTKSeriesDescription < PTKUserInterfaceObject
    % PTKSeriesDescription. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKPatientPanel represents the controls showing series details in the
    %     Patient Browser.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties (SetAccess = private)
        PatientId
        SeriesUid
    end
    
    properties (Access = private)
        ModalityControl
        DescriptionControl
        DateControl
        NumImagesControl
        NumImagesSuffixControl
        
        ModalityText
        DescriptionText
        DateText
        NumImagesText
        NumImagesSuffixText
        
        TextClickedListeners
        
        GuiCallback
    end
    
    properties (Constant)
        SeriesTextHeight = 23
    end
    
    properties (Constant, Access = private)
        SeriesFontSize = 20
        
        ModalityXOffset = 20
        NumberXOffset = 10
        ModalityWidth = 50
        MinDescriptionWidth = 50
        NumImagesWidth = 50
        NumImagesSuffixWidth = 80
        DateWidth = 160
    end
    
    methods
        function obj = PTKSeriesDescription(parent, modality, study_description, series_description, date, time, num_images, patient_id, uid, gui_callback)
            obj = obj@PTKUserInterfaceObject(parent);
            
            obj.SeriesUid = uid;
            obj.PatientId = patient_id;
            
            if nargin > 0
                obj.GuiCallback = gui_callback;
                if isempty(series_description)
                    if ~isempty(study_description)
                        description_text = study_description;
                    else
                        description_text = 'Unknown series';
                    end
                else
                    description_text = series_description;
                    if ~isempty(study_description)
                        description_text = [description_text, ' / ', study_description];
                    end
                end
                
                if isempty(date)
                    date_text = '';
                else
                    date_text = [date([7,8]) '/' date([5,6]) '/' date(1:4)];
                end
                
                if ~isempty(time)
                    date_text = [date_text, ' ', time(1:2) ':' time(3:4)];
                end

                num_images_text = int2str(num_images);
                    
                if num_images == 1
                    num_images_suffix_text = ' image';
                else
                    num_images_suffix_text = ' images';
                end
                
                obj.ModalityText = modality;
                obj.DateText = date_text;
                obj.DescriptionText = description_text;
                obj.NumImagesText = num_images_text;
                obj.NumImagesSuffixText = num_images_suffix_text;
                
                obj.ModalityControl = PTKText(obj, obj.ModalityText, 'Select this series', 'Modality');
                obj.ModalityControl.FontSize = obj.SeriesFontSize;
                obj.ModalityControl.HorizontalAlignment = 'left';
                obj.AddChild(obj.ModalityControl);
                
                obj.DescriptionControl = PTKText(obj, obj.DescriptionText, 'Select this series', 'Description');
                obj.DescriptionControl.FontSize = obj.SeriesFontSize;
                obj.DescriptionControl.HorizontalAlignment = 'left';
                obj.AddChild(obj.DescriptionControl);
                
                obj.DateControl = PTKText(obj, obj.DateText, 'Select this series', 'Date');
                obj.DateControl.FontSize = obj.SeriesFontSize;
                obj.DateControl.HorizontalAlignment = 'left';
                obj.AddChild(obj.DateControl);
                
                obj.NumImagesControl = PTKText(obj, obj.NumImagesText, 'Select this series', 'NumImages');
                obj.NumImagesControl.FontSize = obj.SeriesFontSize;
                obj.NumImagesControl.HorizontalAlignment = 'right';
                obj.AddChild(obj.NumImagesControl);
                
                obj.NumImagesSuffixControl = PTKText(obj, obj.NumImagesSuffixText, 'Select this series', 'NumImagesSuffix');
                obj.NumImagesSuffixControl.FontSize = obj.SeriesFontSize;
                obj.NumImagesSuffixControl.HorizontalAlignment = 'left';
                obj.AddChild(obj.NumImagesSuffixControl);
                
                obj.TextClickedListeners = [];
                obj.TextClickedListeners = addlistener(obj.ModalityControl, 'TextClicked', @obj.SeriesClicked);
                obj.TextClickedListeners(2) = addlistener(obj.DescriptionControl, 'TextClicked', @obj.SeriesClicked);
                obj.TextClickedListeners(3) = addlistener(obj.DateControl, 'TextClicked', @obj.SeriesClicked);
                obj.TextClickedListeners(4) = addlistener(obj.NumImagesControl, 'TextClicked', @obj.SeriesClicked);
                obj.TextClickedListeners(5) = addlistener(obj.NumImagesSuffixControl, 'TextClicked', @obj.SeriesClicked);
            end
        end
        
        function delete(obj)
            delete(obj.TextClickedListeners);
        end
        
        function Select(obj, selected)
            obj.ModalityControl.Select(selected);
            obj.DescriptionControl.Select(selected);
            obj.DateControl.Select(selected);
            obj.NumImagesControl.Select(selected);
            obj.NumImagesSuffixControl.Select(selected);
        end
        
        function CreateGuiComponent(obj, position, reporting)
            % There is no underlying panel to PTKSeriesDescription - we use the
            % parent's panel handle
        end
        
        function Resize(obj, location)
            Resize@PTKUserInterfaceObject(obj, location);
            
            [modality_position, description_position, date_position, num_images_position, num_images_suffix_position] = GetLocations(obj, location);
            obj.ModalityControl.Resize(modality_position);
            obj.DescriptionControl.Resize(description_position);
            obj.DateControl.Resize(date_position);
            obj.NumImagesControl.Resize(num_images_position);
            obj.NumImagesSuffixControl.Resize(num_images_suffix_position);
            if obj.IsVisible
            end
        end
        
        function height = GetRequestedHeight(obj)
            height = obj.SeriesTextHeight;
        end
        
        function [modality_position, description_position, date_position, num_images_position, num_images_suffix_position] = GetLocations(obj, location)
            y_base = location(2);
            width = location(3);
            
            modality_position = [obj.ModalityXOffset, y_base, obj.ModalityWidth, obj.SeriesTextHeight];
            description_x = modality_position(1) + modality_position(3);
            description_width = max(obj.MinDescriptionWidth, width - description_x - obj.DateWidth - obj.NumImagesWidth - obj.NumImagesSuffixWidth - obj.NumberXOffset);
            date_x = description_x + description_width;
            num_images_x = date_x + obj.DateWidth;
            num_images_suffix_x = num_images_x + obj.NumImagesWidth;
            
            description_position = [description_x, y_base, description_width, obj.SeriesTextHeight];
            date_position = [date_x, y_base, obj.DateWidth, obj.SeriesTextHeight];
            num_images_position = [num_images_x, y_base, obj.NumImagesWidth, obj.SeriesTextHeight];
            num_images_suffix_position = [num_images_suffix_x, y_base, obj.NumImagesSuffixWidth, obj.SeriesTextHeight];
        end
    end
    
    methods (Access = protected)
        function child_coords = ParentToChildCoordinates(obj, parent_coords)
            child_coords = parent_coords;
        end
    end
    
    methods (Access = private)
        function SeriesClicked(obj, ~, ~)
            obj.GuiCallback.LoadFromPatientBrowser(obj.PatientId, obj.SeriesUid);
        end
    end
end