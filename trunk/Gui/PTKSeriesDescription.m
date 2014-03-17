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
                
                obj.AddEventListener(obj.ModalityControl, 'TextClicked', @obj.SeriesClicked);
                obj.AddEventListener(obj.DescriptionControl, 'TextClicked', @obj.SeriesClicked);
                obj.AddEventListener(obj.DateControl, 'TextClicked', @obj.SeriesClicked);
                obj.AddEventListener(obj.NumImagesControl, 'TextClicked', @obj.SeriesClicked);
                obj.AddEventListener(obj.NumImagesSuffixControl, 'TextClicked', @obj.SeriesClicked);
                
                obj.AddEventListener(obj.ModalityControl, 'TextRightClicked', @obj.SeriesRightClicked);
                obj.AddEventListener(obj.DescriptionControl, 'TextRightClicked', @obj.SeriesRightClicked);
                obj.AddEventListener(obj.DateControl, 'TextRightClicked', @obj.SeriesRightClicked);
                obj.AddEventListener(obj.NumImagesControl, 'TextRightClicked', @obj.SeriesRightClicked);
                obj.AddEventListener(obj.NumImagesSuffixControl, 'TextRightClicked', @obj.SeriesRightClicked);
            end
        end
        
        function Select(obj, selected)
            obj.ModalityControl.Select(selected);
            obj.DescriptionControl.Select(selected);
            obj.DateControl.Select(selected);
            obj.NumImagesControl.Select(selected);
            obj.NumImagesSuffixControl.Select(selected);
        end
        
        function Highlight(obj, highlighted)
            obj.ModalityControl.Highlight(highlighted);
            obj.DescriptionControl.Highlight(highlighted);
            obj.DateControl.Highlight(highlighted);
            obj.NumImagesControl.Highlight(highlighted);
            obj.NumImagesSuffixControl.Highlight(highlighted);
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
            obj.Highlight(false);
        end
        
        function height = GetRequestedHeight(obj, width)
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
        
        function child_coords = ParentToChildCoordinates(obj, parent_coords)
            child_coords = parent_coords;
        end
    end
    
    methods (Access = protected)
        function input_has_been_processed = MouseHasMoved(obj, click_point, selection_type, src)
            % This method is called when the mouse is moved

            obj.Highlight(true);
            input_has_been_processed = true;
        end

        function input_has_been_processed = MouseExit(obj, click_point, selection_type, src)
            % This method is called when the mouse exits a control which previously
            % processed a MouseHasMoved event
            
            obj.Highlight(false);
            input_has_been_processed = true;
        end
        
    end
    
    methods (Access = private)
        function SeriesClicked(obj, ~, ~)
            obj.Select(true);
            obj.GuiCallback.LoadFromPatientBrowser(obj.PatientId, obj.SeriesUid);
        end
        
        function SeriesRightClicked(obj, ~, ~)
            if isempty(get(obj.DescriptionControl.GraphicalComponentHandle, 'uicontextmenu'))
                context_menu = uicontextmenu;
                context_menu_delete = uimenu(context_menu, 'Label', 'Delete this series', 'Callback', @obj.DeleteDataset);
                context_menu_patient = uimenu(context_menu, 'Label', 'Delete this patient', 'Callback', @obj.DeletePatient);
                set(obj.DescriptionControl.GraphicalComponentHandle, 'uicontextmenu', context_menu);
                set(obj.DateControl.GraphicalComponentHandle, 'uicontextmenu', context_menu);
                set(obj.ModalityControl.GraphicalComponentHandle, 'uicontextmenu', context_menu);
                set(obj.NumImagesControl.GraphicalComponentHandle, 'uicontextmenu', context_menu);
                set(obj.NumImagesSuffixControl.GraphicalComponentHandle, 'uicontextmenu', context_menu);
            end
        end

        function DeletePatient(obj, ~, ~)
            obj.Parent.DeletePatient;
        end
        
        function DeleteDataset(obj, ~, ~)
            choice = questdlg('Do you want to delete this dataset?', ...
                'Delete dataset', 'Delete', 'Don''t delete', 'Don''t delete');
            switch choice
                case 'Delete'
                    parent_figure = obj.GetParentFigure;
                    parent_figure.ShowWaitCursor;
                    obj.GuiCallback.DeleteFromPatientBrowser(obj.SeriesUid);
                    
                    % Note that at this point the SeriesDescription object may have been deleted, so
                    % we can't use 'obj'
                    parent_figure.HideWaitCursor;
                case 'Don''t delete'
            end
            
            
        end
        
    end
end