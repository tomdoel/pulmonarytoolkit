classdef PTKDependency < handle
    % PTKDependency. Legacy support class for backwards compatibility. Replaced by MimDependency
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
   methods (Static)
        function obj = loadobj(property_struct)
            % This method is called when the object is loaded from disk.
            % Due to the class change, we expect property_struct to be a struct
            
            obj = MimDependency(property_struct.PluginName, property_struct.Context, property_struct.Uid, property_struct.DatasetUid, property_struct.Attributes);
        end
    end
end
