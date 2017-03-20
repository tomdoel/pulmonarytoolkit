classdef PTKLinkedDatasetAssociatedDatasetRecord < CoreBaseClass
    % PTKLinkedDatasetAssociatedDatasetRecord. Part of the internal framework of the TD MIM Toolkit.
    %
    %     PTKLinkedDatasetAssociatedDatasetRecord is used by PTKLinkedDatasetRecorder to store
    %     a map of all linked datasets to the primary dataset for that linkage.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the MIM framework
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %

    properties
        AssociatedDatasetsList % Maps all the datasets which link to this dataset
    end
    
    methods
        function AddLink(obj, associated_uid)
            if isempty(obj.AssociatedDatasetsList) || ~ismember(obj.AssociatedDatasetsList, {associated_uid})
                obj.AssociatedDatasetsList{end + 1} = associated_uid;
            end
        end
        
        function RemoveLink(obj, associated_uid)
            obj.AssociatedDatasetsList = setdiff(obj.AssociatedDatasetsList, associated_uid);
        end
    end
end