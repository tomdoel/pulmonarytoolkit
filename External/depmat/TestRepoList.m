function repos = TestRepoList()
    % TestRepoList. An example list of repositories for use with DepMatUpdate
    %
    %
    %
    %     Licence
    %     -------
    %     Part of DepMat. https://github.com/tomdoel/depmat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %


    repos = DepMatRepo.empty();
    repos(end + 1) = DepMatRepo('coremat', 'main', 'https://github.com/tomdoel/coremat.git', 'coremat_main');
    repos(end + 1) = DepMatRepo('dicomat', 'main', 'https://github.com/tomdoel/dicomat.git', 'dicomat_main');
    repos(end + 1) = DepMatRepo('matnat', 'main', 'https://github.com/tomdoel/matnat.git', 'matnat_main');
end
