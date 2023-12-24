classdef PTKMexInfo < CoreCompiledFileInfo
    % Structure for caching information about compiled mex files.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    methods
        function obj = PTKMexInfo(current_version, filename, extension, file_path, compiler_options, other_files)
            obj = obj@CoreCompiledFileInfo(current_version, filename, extension, file_path, compiler_options, other_files);
        end
        
        function converted = CoreCompiledFileInfo(obj)
            converted = CoreCompiledFileInfo();
            mco = ?PTKMexInfo;
            for property = mco.PropertyList'
                converted.(property.Name) = obj.(property.Name);
            end            
        end        
    end
    
end

