# Loading data

PTK was primarily designed for 3D CT or MRI images covering the whole lung. PTK has varying levels of support for DICOM. MetaIO and other formats. See [Supported Data Formats](../data/supported-formats) for more details.

You can use PTK for other types of images, although not all plugins will work.

For non-lung images, consider using the [Medical Imaging Viewer (MIV)](../features/miv), which is similar to PTK but for non-lung images.

---
## Importing new data

You need to first import data into PTK. Data only need to be imported once, as PTK rememberes previously imported data.

1. [Start up the PTK viewer](../installing/running)

2. Click the `Import Data` button in the toolbar panel at the bottom left of the screen.

3. In the dialog that appears, select a folder containing the data you want to import. PTK will import all data from this folder and its subfolders.
   - Alternatively, you can select an individual image file to import
   - :warning: DICOM series are sometimes split across multiple folders. If this is the case for your data, make sure you select a **parent directory** above all of the relevant folders. This will ensure that your complete series is imported

4. When the data have finished importing, PTK will choose a representative series from the data you have imported and load that into the viewer. You can select a different subject or series by clicking in the sidebar or using the Patient Browser window as described below.

---

## Viewing a different dataset

PTK displays a single dataset (series) at a time.

The left sidebar contains a **Subject List** showing all subjects (patients) imported into PTK. The current subject is highlighted.

Below this is a **Series List** showing datasets (Series) for the **current Subject**
 * Click on a subject to switch to that subject (scroll if necessary down the subject list). When you change subject, PTK will load into the viewer the most recent dataset you viewed for that subject.
 * Click on a series to load that series dataset into the viewer

### Linked Datasets

 - If you have any [linked datasets](../features/linked-datasets) (for example for CT-MR registration or other analysis comparing multiple datasets) there is an additional list showing these below the subect and series lists.

### Delays when you first load a dataset

It may take a minute or two to visualise a dataset the very first time you load it. This is because PTK does some initial processing, in order to identify the lung region of interest (ROI). Identifying this ROI allows the non-lung regions to be internally discarded (the original data is not affected!) which substantially speeds up execution time and reduces memory usage. This ROI calculation is performed once per dataset the first time you load that dataset. Even if you restart PTK, restart Matlab or reboot your computer, it will not need to perform it again for that dataset.


### Loading failures

If PTK cannot load or process a series, it will either revert to the previous displayed series, or will unload all images. In either case you should select a working series to load in order to continue.

---

## The Patient Browser

The Patient Browser is a separate window which shows you all the subjects and series in the database.

Click the Patient Browser button to show the Patient Browser if it is not already shown. Then scroll through all the series (grouped by patient) and click the series you wish to load.

The left-hand sidebar is a shortcut to patients - clicking on a patient scrolls the main panel to that patient (but it will not automatically load a series).



---

## How subjects are grouped

Grouping of series into subjects (patients) is done through `Patient ID` and `Patient Name` metadata in the DICOM headers.

For non-DICOM data, such patient identifiers may not exist. In such cases, each series will be given its own subject.

In most situations the subject grouping is not important to the functioning of PTK, since PTK considers each series independently. Subject grouping is mostly done as a convenience to the user when using the GUI to see related series grouped together for the same subject.


### Subject grouping for anonymised data

For anonymised data, the Patient ID and Patient Name should ideally be consistent across all images in order for the images to be grouped under the same subject. (In a clinical setting, this would be a requirement.) However, as PTK is a research tool which is mainly used with anonymised data, it is recognised that anonymisation may not have been applied consistently. Sometimes, the anonymisation process might allocate an inconsistent Patient ID, but set the Patient Name to a consistent research identifier (such as `PATIENT1`, `PATIENT2` etc). For this reason, PTK has enabled by default a setting which allows series with the same `Patient Name` to always be grouped together even if they have different Patient IDs. This setting is `GroupPatientsWithSameName` in the `PTKAppDef.m` class. Note that changing this setting may require rebuilding of the subject database.

---

Next: see [Visualising Data](../gui/visualising-data)
