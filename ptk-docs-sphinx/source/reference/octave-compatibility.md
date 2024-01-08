# Octave compatibility

At time of writing, PTK does not work with Octave. This is because Octave does not implement some of the key Matlab functionality that PTK uses.

The following list may change with newer versions of Octave.

Known issues include:
 - Octave does not implement Enumerations, which are used in many parts of PTK
 - Octave does not fully implement events and listeners for classes, which are used for some of PTK's model classes
 - Octave does not apear to support the `empty()` method for creating empty vectors of classes
