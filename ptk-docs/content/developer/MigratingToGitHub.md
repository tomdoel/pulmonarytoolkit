This page is for users who originally checked out the PTK codebase from Google Code and who wish to migrate their existing codebase to GitHub


# HOW TO MIGRATE YOUR PTK CODEBASE FROM GOOGLE CODE

There are two ways to do this: automatic or manual.

***If you have any local code changes you want to preserve, please ensure they are backed up as a precaution. Migration method A should preserve them, but I cannot guarantee this.***


## METHOD A: Automatic migration - PTK will attempt to switch over itself (experimental!)

1. Ensure you have git command-line installed. On Linux and Mac this is probably already installed. On Windows you can install it here: https://git-for-windows.github.io. Please ensure you select "Use Git from the Windows Command Prompt" when installing.

2. Update your existing (Subversion) PTK repository to the latest version (for example, by running !svn update in the Matlab command window, or selecting update in SmartSVN). Note it will not be possible to do this after January 2016.

3. Run PTK, and when you are prompted, select "Migrate" and follow the instructions

4. If migration fails, you will have to use method B


## METHOD B: Manual migration

Clone the new PTK repository yourself using one of the following methods:

B1. Go to the website and select Clone in Desktop (you may be prompted to install GitHub Desktop) -  https://github.com/tomdoel/pulmonarytoolkit

B2. Clone using a git user interface - I recommend SourceTree - https://www.sourcetreeapp.com

B3. Clone from the command line: git clone https://github.com/tomdoel/pulmonarytoolkit.git
