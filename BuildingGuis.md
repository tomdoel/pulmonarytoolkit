# Building user interfaces using PTK classes #

The PTK provides a suite of classes which extend Matlab's user interface features to provide more power and functionality. The advantages offered include:
  * Modern-style tab controls
  * Scrolling panels. These can be scrolled with the mouse wheel or a side slider which automatically appears or disappears if necessary
  * Composite panels (a panel formed of an arbitrary number of sub-panels)
  * Auomatic lazy creation of graphical objects (the actual components are only created when they become visible)
  * Correct positioning of components before they become visible, so no ugly flicker while the GUI is being resized
  * Button controls with custom colours and image backgrounds
  * Clickable and selectable text controls and which can highlight as the mouse moves over
  * Mouse over, Left-click, mouse drag, right-click, shift-click and mouse wheel commands for all controls and panels
  * Keyboard shortcuts
  * Control classes can be extended to add your own functionality

## Classes ##
The core GUI classes are found in Library/GuiComponents. All graphical objects inherit from `PTKUserInterfaceObject`. A number of components are provided:

Base classes
  * `PTKUserInterfaceObject` - base class for graphical components. All classes must inherit from this
  * `PTKFigure` -  you must have at least one `PTKFigure` object. This contains a Matlab figure on which the controls are placed

Controls
  * PTKText
  * PTKButton
  * PTKSlider
  * PTKDropDownMenu

Panels
  * PTKPanel
  * PTKSlidingPanel
  * PTKCompositePanel
  * PTKTabPanel
  * PTKTabPanel

To modify control behaviour for individual controls, create the control and then modify its properties. To change control behaviour more generally, create your own control class inheriting from controls and modify the properties in that inherited class


## Building GUIs - essential concepts ##

  * You should create a `PTKFigure` object which will be the figure upon which your GUI is based. Generally you do this by creating a new class which inherits from `PTKFigure`. This is your basic interface window.

  * Create other controls - typically in the constructor. You must call `AddChild()` on the parent class to add a control. For example:

```
MyFigure < PTKFigure

...

properties (Access = private)
    MyText
end

methods  (Access = private)
    function obj = MyFigure
        % Constructor

        % Call the base class to initialise the hidden window
        obj = obj@PTKFigure('Figure title', [50 50 300 400]);

        obj.MyText = PTKText(....);
        obj.AddChild(obj.MyText);

        ...

        % Make the window visible
        obj.Show(PTKReportingDefault);
    end
end
```

  * Override the `Resize()` method to define the layout of your GUI. Remember to call the superclass `Resize()` method (this is important!)
  * `PTKFigure` is hidden by default. Call `Show()` to make it visible.
  * You can create the underlying PTK object at any point. The actual graphical components are generally created when they first become visible, via the `CreateGuiComponent()` method.
  * The `Resize()` method will remember the component's size, even if it currently has not been created yet (i.e. it is still invisible). When it becomes visible, it will be created with the correct size. This means you can lay out your GUI before it has been created, so when it comes visible it already has the correct size and layout.
  * If you are using Matlab gui components directly, you cannot create them in your constructor because there is go graphical handle yet to which you can attach them. You must instead create them in the `CreateGuiComponent()` method. Call the superclass method and you will then have a Matlab handle `obj.GraphicalComponentHandle` which you can use to create your Matlab gui object. NB If you are resizing these Matlab GUI objects in `Resize()` you will need to put a null check on them so they don't get resized before they have been created.



## Examples ##
  * `PTKViewer.m` is an example viewer application built using the `PTKGui` classes. `PTKViewer` itself is a `PTKFigure` object, containing a single panel (`PTKViewerPanel`)
  * `PTKPatientBrowser` is a `PTKFigure` object containing 2 panels. The left panel is `PTKListOfPatientsPanel`, which is a PTKPanel containing a listbox text and button controls. The right panel is a scrolling panel `PTKPatientsSlidingPanel`, which is a `PTKSlidingPanel` containing a `PTKCompositePanel` consisting of multiple  `PTKPanel`s of class `PTKPatientPanel`.
  * `PTKGui` is a `PTKFigure` object containing multiple panels including a `PTKTabControl` which contains the plugin panels.