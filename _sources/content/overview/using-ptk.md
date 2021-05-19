# Ways of using the Pulmonary Toolkit (PTK)

There are several ways of using PTK:

## If you have a Matlab license:

### 1. Run the PTK GUI from within Matlab

   This is the most user-friendly option, which allows you to visualise and process data from within a graphical user interface (GUI) and to export the results. You can develop your own Plugins within Matlab and they automatically become available through the GUI.

#### Requirements:
   * Matlab version R2010b or later
   * The Matlab Image Processing Toolbox
   * A C++ compiler compatible with Matlab
   * (recommended) a Git client

#### How to run the PTK GUI from with Matlab
   * Clone the Matlab repository. If you have a command-line Git client you can run
   ```
   git clone https://github.com/tomdoel/pulmonarytoolkit.git
   ```
   This will clone the repository into a local directory `pulmonarytoolkit`
   * Launch Matlab
   * Change to the `pulmonarytoolkit` directory
   * Run `ptk` from the Matlab command window
   ```
   ptk
   ```


### 2. Integrate into your own Matlab software using the PTK API and PTK Library

   If you want to run automated scripted/batch processing, or you are developing your own GUI, the PTK API gives you access to the full power of PTK through your Matlab code without any graphical interface or user interface required.

   See the tutorials for more information on how to use the API. Using the API requires an understanding of object orientated software.

   * The main entrypoint is the `PTKMain()` which you use to create a singleton
   ```
       ptk_main = PTKMain();
   ```
   * You can use this to load in data and create a `PTKDataset` object for a particular series (identified by DICOM series instance UID, or filename for other image formats)
   * You run Plugins on your `PTKDataset` object using the `GetResult()` method

   * If you don't want to use PTK's database and Plugin architecture but you still want to use its image processing or other useful algorithms in your own code, the PTK Library provides a suite of functions you can call directly from your own code.

## If you do not have a Matlab license:

### 3. Run the PTK App

   The PTK App is the PTK GUI described above, but compiled into an application which runs outside of Matlab.

   You can download and run the PTK GUI App for Windows/macOS/Linux from the GitHub website. You don't need a Matlab license, but you may need to install the free Matlab MCR software.

   See [Running PTK WIthout Matlab](../overview/Running-PTK-without-Matlab) for more details.

   You can't run your own Plugins from the pre-built PTK GUI App, although you if you have the Matlab Compiler you can compile your own PTK App which does include your own Plugins.


### 4. Run batch processing from the command-line using the PTK API App

   The PTK API App is a command-line application which runs batch processing outside of Matlab. Calling the app runs a `PTKScript` which defines a batch processing action based on input commands.

   You can download and run the PTK GUI App for Windows/macOS/Linux from the GitHub website. You don't need a Matlab license, but you may need to install the free Matlab MCR software.

   See [Running PTK WIthout Matlab](../overview/Running-PTK-without-Matlab) for more details.

   You can't run your own Scripts from the pre-built PTK GUI App, although you if you have the Matlab Compiler you can compile your own PTK API App which does include your own Scripts.
