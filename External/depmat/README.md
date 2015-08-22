# DepMat
GIT dependency management for Matlab. DepMat is for when your Matlab code depends on one or more GIT repositories, and you want these to be automatically kept up to date.
DepMat will check the current versions of the git repositories, and update to the newest version if required. DepMat will also add all subdirectories to the Matlab path automatically.

##Typical usage
Typically you might call `DepMatUpdate` whenever your Matlab program runs

```
DepMatUpdate(repoList);
````

where `repoList` is an array of `DepMatRepo` objects, each of which defines a repository on which your code depends.

An example function `TestRepoList` is provided, which generates an example list of repositories:

```
DepMatUpdate(TestRepoList);
````

You can substitute in your own function `MyRepoList`:

```
function repos = MyRepoList
    
    repos = DepMatRepo.empty;
    repos(end + 1) = DepMatRepo('apple', 'master', 'https://github.com/yourdomain/apple.git', 'apple_master');
    repos(end + 1) = DepMatRepo('banana', 'master', 'https://github.com/yourdomain/banana.git', 'banana_master');
    repos(end + 1) = DepMatRepo('orange', 'specialbranch', 'https://github.com/yourdomain/orange.git', 'orange_specialbranch');
end
```

This will the check out and keep up to date the repository `apple` with URL `https://github.com/yourdomain/apple.git` on branch `master`, in a directory called 'apple_master' and so on.
