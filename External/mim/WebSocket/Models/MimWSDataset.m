classdef MimWSDataset < MimModel
    methods (Access = protected)        
        function value = run(obj)
            seriesUid = obj.Parameters.seriesUid;
            value = obj.Callback.getMim().CreateDatasetFromUid(seriesUid);
        end
    end
end