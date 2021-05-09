# PTKImage

`PTKImage` is the basic image class in PTK. Most images are actually an inherited type `PTKDicomImage` which contains additional metadata and fields representing medical imaging data. Even images imported from non-DICOM data are typically represented by `PTKDicomImage` objects because they still need the metadata this class contains, and these images are usually originally derived from DICOM data anyway.

_Note: in future releases it is possible that other classes of type PTKImage may be created to represent non-DICOM medical imaging data._

_Note: In future releases, `PTKImage` may derive from another base type, but this will not affect anything here._

## Overview

`PTKImage` is a wrapper for an raw image, providing fields and methods that allow you to access and manipulate the data. Crucially, `PTKImage` will _automatically maintain the link between the data it represents and the original data from which it was derived_. This guarantees the integrity of the data, something that does not happen in most image toolkits.

For example. consider the case where you have an original image and a segmentation, each of which is represented by a `PTKImage`. Using `PTKImage` you can crop the segmentation to remove empty space around the border, in order to reduce memory usage and reduce processing time. You can then combine the two images (e.g. displaying the segmentation on top of the original data). The images will always be correctly aligned because `PTKImage` maintains knowledge of how the image was cropped. If, instead of using `PTKImage`, you stored the image in a raw matrix then the images would not be aligned - you would have to do this manually using knowledge of how the image was cropped... needless to say, this is extremely prone to error and inadvisable.


## How to create `PTKImages`

Its deliberately hard to create a `PTKImage` from scratch, because most of the time if you are typing to create a new PTKImage from scratch, you are probably doing something wrong. The reason is that your images are generally derived from real medical imaging data, and this has associated metadata, with important information such as the voxel size. If you create your own images, you lose this metadata. So you shouldn't create blank images from scratch, but instead you should derive them from existing data. The `PTKImage` mechanism is designed to more-or-less force you to do this, in order to prevent accidental bugs creeping into your code e.g. because you forgot to set a `VoxelSize` property somewhere.

So if you need to create a new PTKImage, you should be basing your new image on the metadata from your original source data. To this end, `PTKImage` provides two methods, `Copy()` and `BlankCopy()`.

* `Copy()` method provides a clone of your image, which you can then modify as you wish. Remember that Matlab is pass-by-reference, so if you pass an `PTKImage` object around and modify it, you are modifying the original image. So if you are planning to modify an image you probably want to copy it first.
* `BlankCopy() is the same as `Copy()` but leaves the actual image data (`RawImage`) empty so you can set it later. This is for the case where you want a template where you will store the image data later after you generate it.
* 'ChangeRawImage()` allows you to change the raw image data. Of course the image data must be the same size as the size in the template (it really doesn't make sense it if isn't)
* ... plus other methods to set or fetch parts of the image data





## Image types

`PTKImage` has a property `ImageType` which describes the data contained in `RawImage` (enumeration PTKImageType)
 * Grayscale - 8 or 16-bit integer greyscale image which generally preserves the original (un-normalised) image data, e.g. from MRI or CT
 * Colormap - an indexed image, used to indicate distinct regions in an image. Segmentations are often stored in Colormap format, where each integer value represents a distinct region. Note that PTK uses a double-index system which relates  the value in the image to the colour index Matlab uses for display. Matlab displays indexed images using a colormap, where for the default PTK colormap 0 is black, 1 is blue, etc. The property `ImageColorMap` defines the mapping from the image value to the colormap value. This allows a many-to-one mapping of image values to colours in the colormap. If `ImageColorMap` is blank then a simple 1-1 mapping is assumed (0->0, 1->1 etc.)
 * Scaled - A floating point value representing some property
 * Quiver - an (m x n x o x 3) tensor, i.e. a volume where each point has a 3-dimensional vector, which can be represented by a PTK quiver image
