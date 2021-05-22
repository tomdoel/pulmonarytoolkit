# Updating the Pulmonary Toolkit

How you update to new PTK versions depends on whether you are using a git checkout or a pre-built binary release.


## Pre-built release

If you installed a pre-built release binary from the [PTK Releases page](https://github.com/tomdoel/pulmonarytoolkit/releases), you will need to update manually by installing the new release and deleting the old one.


## Automatic updates

If you have a git checkout on the main branch, PTK will offer to update your code when a new version comes out. It will prompt you each time to do this, and you will normally only do this the first time you run PTK after restarting Matlab.

If you choose `Do not ask me again`, no future update checks will occur and you will then need to update PTK manually using git. You can re-enable automatic updates by deleting the file 'do-not-update-git'.

PTK will use the git update process so your local changes will be preserved. PTK may not be able to update if you have local changes. Updating the .m files might confuse Matlab so if you encounter any problems, restart Matlab after updating.


## Updating a git clone

You can update the Toolkit at any time using your git client. Updating will obtain the latest changes to the code, including new features and bug fixes. Updating with git will preserve any changes you have made to the code on your machine.

If you have made local changes this could lead to conflicts - please see documentation for git or your git client on how to resolve conflicts.

Sometimes, Matlab can get confused by updates to `.m` files while it is running, especially if it has class objects loaded in memory. If you encounter any problems, restart Matlab after updating.


### Using GitHub Desktop
- Open GitHub Desktop.
- Select the `Pulmonary Toolkit` project
- Click `Update` from main

### Using SourceTree
- Open SourceTree
- Select the `Pulmonary Toolkit` project
- Click `pull` to obtain the latest version
