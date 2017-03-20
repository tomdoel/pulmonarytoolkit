classdef MimSidePanelSeriesDescription < GemListItem
    % MimSidePanelSeriesDescription. Part of the gui for the TD MIM Toolkit.
    %
    %     This class is used internally within the TD MIM Toolkit to help
    %     build the user interface.
    %
    %     MimSidePanelSeriesDescription represents the controls showing series details in the
    %     side panel of the GUI.
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties (SetAccess = private)
        PatientId
        SeriesUid
    end
    
    properties (Constant)
        SeriesTextHeight = 18
    end
    
    properties (Access = private)
        ModalityControl
        DescriptionControl
        NumImagesControl
        
        ModalityText
        DescriptionText
        NumImagesText
        
        GuiCallback
    end
    
    properties (Constant, Access = private)
        SeriesFontSize = 16
        NumImagesFontSize = 14
        ModalityXOffset = 0
        NumberXOffset = 10
        ModalityWidth = 35
        MinDescriptionWidth = 100
        NumImagesWidth = 40
    end
    
    methods
        function obj = MimSidePanelSeriesDescription(parent, modality, study_description, series_description, date, time, num_images, patient_id, uid, gui_callback)
            obj = obj@GemListItem(parent, uid);
            obj.TextHeight = obj.SeriesTextHeight;
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

                num_images_text = ['(', int2str(num_images), ')'];
                    
                obj.ModalityText = modality;
                obj.DescriptionText = description_text;
                obj.NumImagesText = num_images_text;
                
                obj.ModalityControl = GemText(obj, obj.ModalityText, 'Select this series', 'Modality');
                obj.ModalityControl.FontSize = obj.SeriesFontSize;
                obj.ModalityControl.HorizontalAlignment = 'left';
                obj.AddTextItem(obj.ModalityControl);
                
                obj.DescriptionControl = GemText(obj, obj.DescriptionText, 'Select this series', 'Description');
                obj.DescriptionControl.FontSize = obj.SeriesFontSize;
                obj.DescriptionControl.HorizontalAlignment = 'left';
                obj.AddTextItem(obj.DescriptionControl);

                obj.NumImagesControl = GemText(obj, obj.NumImagesText, 'Select this series', 'NumImages');
                obj.NumImagesControl.FontSize = obj.NumImagesFontSize;
                obj.NumImagesControl.HorizontalAlignment = 'right';
                obj.AddTextItem(obj.NumImagesControl);
            end
        end
        
        function Resize(obj, location)
            size_changed = ~isequal(location, obj.Position);
            
            % Don't call the parent class
            Resize@GemVirtualPanel(obj, location);
            
            [modality_position, description_position, num_images_position] = GetLocations(obj, location);
            obj.ModalityControl.Resize(modality_position);
            obj.DescriptionControl.Resize(description_position);
            obj.NumImagesControl.Resize(num_images_position);
            
            % A resize may change the location of the highlighted item            
            if size_changed
                obj.Highlight(false);
            end
        end
        
        function [modality_position, description_position, num_images_position] = GetLocations(obj, location)
            y_base = location(2);
            width = location(3);
            
            modality_position = [location(1) + obj.ModalityXOffset, y_base, obj.ModalityWidth, obj.SeriesTextHeight];
            description_x = modality_position(1) + modality_position(3);
            description_width = max(obj.MinDescriptionWidth, width - obj.ModalityXOffset - obj.ModalityWidth - obj.NumImagesWidth);
            description_position = [description_x, y_base, description_width, obj.SeriesTextHeight];
            
            num_images_x = description_x + description_width;
            num_images_position = [num_images_x, y_base, obj.NumImagesWidth, obj.SeriesTextHeight];
        end        
    end
    
    methods (Access = protected)
        
        function ItemLeftClicked(obj, src, eventdata)
            ItemLeftClicked@GemListItem(obj, src, eventdata);
            obj.GuiCallback.SeriesClicked(obj.PatientId, obj.SeriesUid);
        end
        
        function ItemRightClicked(obj, src, eventdata)
            ItemRightClicked@GemListItem(obj, src, eventdata);
            
            if isempty(get(obj.DescriptionControl.GraphicalComponentHandle, 'uicontextmenu'))
                context_menu = uicontextmenu;
                context_menu_delete = uimenu(context_menu, 'Label', 'Delete this series', 'Callback', @obj.DeleteSeries);
                context_menu_patient = uimenu(context_menu, 'Label', 'Delete this patient', 'Callback', @obj.DeletePatient);
                obj.SetContextMenu(context_menu);
            end            
        end
        
        
    end
    
    methods (Access = private)
        function DeletePatient(obj, ~, ~)
            obj.GuiCallback.DeletePatient(obj.PatientId);
        end
        
        function DeleteSeries(obj, ~, ~)
            parent_figure = obj.GetParentFigure;
            parent_figure.ShowWaitCursor;
            obj.GuiCallback.DeleteSeries(obj.SeriesUid);
            
            % Note that at this point obj may have been deleted, so we can no longer use it
            parent_figure.HideWaitCursor;
        end
        
    end
end