# Running the Pulmonary Toolkit

Make sure you have followed the installation instructions. If running from Matlab, you need the Matlab Image Processing Toolbox and you need to have a C++ compiler configured to work with Matlab.




## Running the GUI from Matlab

1. Start Matlab.

2. Change the current Matlab directory to the main folder on your hard disk containing the Pulmonary Toolkit. This is the folder containing the file `ptk.m` and is the path you specified when checking out the Toolkit in your git client.
 - Note 1: the current Matlab folder is shown below the Matlab ribbon.You can choose a different folder using the yellow/green “Browser for folder” icon  to the left of this.
 - Note 2: you can add this folder to the Matlab path if you wish to avoid having to change the folder in future.

3. In the **Matlab Command Window**, type
    ```
    ptk
    ```

   This will bring up the splash screen.

   You don't need to set any Matlab paths.

   Provided you have set up your compiler, the Toolkit should automatically compile the mex files the first time it starts up. This may take a few minutes. It only needs to do this once, or when the source files change.

### Compilation errors

   If the mex compilation fails (e.g. you have not set up a C++ compiler) you will need to fix your compiler installation and then force the Toolkit to re-run compilation using
   ```
   ptk_main = PTKMain();
   ptk_main.Recompile();
   ```


If everything is installed correctly, it will compile the C++ files and you can then import data using the Import Data button.

---

## Running a pre-build release

You first need to have the appropriate MCR and Visual Studio Redistributable installed.
Then you run the release executable you downloaded.

See [Running PTK without Matlab](../overview/Running-PTK-without-Matlab) for details.

---

## Using the API

If you are using the programmatic API, the main entry point is `PTKMain()`
From the Matlab Command Window:
```
ptk_main = PTKMain();
```
