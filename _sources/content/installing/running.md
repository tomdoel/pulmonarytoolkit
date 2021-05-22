# Running the Pulmonary Toolkit

Make sure you have followed the installation instructions. If running from Matlab, you need the Matlab Image Processing Toolbox and you need to have a C++ compiler configured to work with Matlab.


---

## Running the GUI from Matlab

You don't need to set any Matlab paths.

Navigate Matlab to the root folder of the pulmonarytoolkit project (the one containing ptk.m)

From the **Matlab Command Window**, run:

```
ptk
```

Provided you have set up your compiler, the Toolkit should automatically compile the mex files the first time it starts up. This may take a few minutes. It only needs to do this once, or when the source files change.

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

---

## Compilation errors

If the mex compilation fails (e.g. you have not set up a C++ compiler) you will need to fix your compiler installation and then force the Toolkit to re-run compilation using
```
ptk_main = PTKMain;
ptk_main;
```

## 7. Running the Toolkit

Ensure you have Matlab installed and the Matlab Image Processing Toolbox
Ensure you a C++ compiler installed and working with Matlab
Clone the latest version of the pulmonarytoolkit repository from GitHub
Start Matlab
Run the PTK graphical interface using:
