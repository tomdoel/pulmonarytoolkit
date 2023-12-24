classdef MimTemplateCallback < CoreBaseClass
    % Used by plugins to fetch empty template images
    %
    % Template images are empty images with metadata matching the current
    % image. They are used to create images that will be compatible with
    % other images from the same dataset. The metadata image size and origin
    % depends on the chosen context.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %

    properties (Access = private)
        LinkedDatasetChooser  % Sends the API calls to the correct dataset
        DatasetStack       % Handle to the current call stack for the primary dataset
        Reporting
    end
    
    methods
        function obj = MimTemplateCallback(linked_dataset_chooser, dataset_call_stack, reporting)
            obj.DatasetStack = dataset_call_stack;
            obj.LinkedDatasetChooser = linked_dataset_chooser;
            obj.Reporting = reporting;
        end
        
        % Returns an image template for the requested context
        function template = GetTemplateImage(obj, context, dataset_name)
            if nargin < 2
                context = [];
            end
            if nargin < 3
                dataset_name = [];
            end
            template = obj.LinkedDatasetChooser.GetDataset(obj.Reporting, dataset_name).GetTemplateImage(context, obj.DatasetStack, obj.Reporting);
        end
    end
end
