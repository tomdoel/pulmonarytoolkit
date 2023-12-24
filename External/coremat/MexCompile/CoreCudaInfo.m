classdef CoreCudaInfo < CoreCompiledFileInfo
    % Structure for caching information about compiled cuda files.
    %
    % CoreCudaInfo is used by CoreMex and its related files to manage
    % dependencies on mex files. You typically create a map of
    % CoreMexInfo objects, each of which defines a mex file to be
    % compiled, and pass it into CoreMex.
    %
    % The basic rule you must follow is to increment the version number
    % of your CoreMexInfo object whenever you change the corresponding
    % mex file. This will force recompilation of any older versions.
    %
    %
    % .. Licence
    %    -------
    %    Part of CoreMat. https://github.com/tomdoel/coremat
    %    Author: Tom Doel, 2013.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    
    properties
        CudaType
    end
    
    methods
        function obj = CoreCudaInfo(cuda_type, varargin)
            obj = obj@CoreCompiledFileInfo(varargin{:});
            if nargin > 0
                obj.CudaType = cuda_type;
            end
        end
    end
    
end

