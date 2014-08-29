classdef PTKTemplateCallback < PTKBaseClass
    % PTKTemplateCallback. Used by plugins to fetch empty template images
    %
    %     Template images are empty images with metadata matching the current
    %     image. They are used to create images that will be compatible with
    %     other images from the same dataset. The metadata image size and origin
    %     depends on the chosen context.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties (Access = private)
        LinkedDatasetChooser  % Sends the API calls to the correct dataset
        DatasetStack       % Handle to the current call stack for the primary dataset
    end
    
    methods
        function obj = PTKTemplateCallback(linked_dataset_chooser, dataset_call_stack)
            obj.DatasetStack = dataset_call_stack;
            obj.LinkedDatasetChooser = linked_dataset_chooser;
        end
        
        % Returns an image template for the requested context
        function template = GetTemplateImage(obj, context, dataset_name)
            if nargin < 2
                context = [];
            end
            if nargin < 3
                dataset_name = [];
            end
            template = obj.LinkedDatasetChooser.GetDataset(dataset_name).GetTemplateImage(context, obj.DatasetStack);
        end
    end
end
