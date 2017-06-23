# gem
A Matlab GUI toolkit for creating modern-style user interfaces.

Gem (GUI Extensions for Matlab) is a library of classes that wrap around Matlab's own graphical user interface objects. Gem provides a rich set of features that are difficult to code by hand in Matlab user interfaces, for example:
 * Stylesheets, where colours and fonts are automatically inherited by controls from their parents;
 * Mouseover highligting of controls such as buttons and list elements;
 * Mouse and keyboard shortcuts are location-dependent; different panels can process different shortcuts;
 * Scrolling panels and lists which respond to mousewheel and slider bar movement;
 * Responsive user interfaces; each control can implement its own resize behaviour;
 * Tabbed panels;
 * Screen coordinates are relative to each control; 
 * No ugly flickering while creating the GUI; it stays invisible until it is ready to display;
 * Cine through a slices in an image volume (requires parts of the MIM toolkit).

Gem reuses existing Matlab graphics classes, so it is compatible with Matlab user interfaces. 


## Limitations

* Gem is not a complete GUI toolkit and there are some things missing and some things that don't quite work as they should.
* There are no layout managers or GUI editors; you need to implement the resize behaviour yourself

## Licence

(c) Tom Doel

Gem is available open-source under an MIT licence

## Website

https://github.com/tomdoel/gem


## Development notes

* You create your GUI by creating Gem objects and binding them together. All Gem objects inherit from the GemUserInterfaceControl class. Binding an object to its parent is done by firstly passing in the Gem parent control handle into the constructor of the Gem control, and secondly by calling AddChild() on the parent. If you forget to call AddChild() on any of your objects then you will get an exception when you try to run the GUI. The two-step binding is necessary because the child control needs to be fully created before it is added to the parent control, and that does not happen until the constructor finishes
* The actual Matlab graphical controls are not created until they are first made visible. If you call Show() on a GemFigure then all its controls will be made visible (if they are enabled - see below). The creation of the graphical component is done by the CreateGuiComponent() method. Creation only happens once per object. 
* Controls have a concept of Visible, which is determined by their parent's visibility, and Enabled, which is inherited from the parent but can be disabled for individual controls. This allows you to show and hide controls depending on the context. Genererally you only use Show() and Hide() on the parent figure to show or hide the entire window and all of its controls. If you want to hide a panel or button, you would disable that panel or button.
* If you need custom resize behaviour (which you will do e.g. in panels when there is no default layout manager), you do this by creating a class that inherits from the Gem class, and override the Resize() method. You then resize all your child components in the Resize method. Remember to call Resize() on the base class!
* If you need to get the Matlab graphics handle for a control, use the GetContainerHandle() method. This will get a handle even if this control does not have an actual graphics handle (for example, "virtual panels" are Gem classes but they do not have their own Matlab handle object; they use the graphics handle of the parent object).


