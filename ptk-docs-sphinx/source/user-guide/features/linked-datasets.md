# Linked datasets

PTK allows one or more datasets to be linked to another dataset. This allows you to write analysis plugins that require input from two or more different datasets, for example multi-modal analysis or registration.

The dataset on which you run a Plugin is called the `Primary Dataset`. When you link another dataset, you attach it to the Primary Dataset with a label. The label can be used by your Plugins to fetch results from the linked dataset.

## Example: CT-MR registration

- You have a separate CT and MR datasets
- Choose the CT dataset as the Primary Dataset
- Link the MR dataset to the CT dataset, using label `MR`
- Write a Plugin which runs on the CT dataset. As well as fetching results from the CT dataset, it can fetch results from the linked MR dataset by using the label `MR`
- The results are stored in the CT dataset (because this is the dataset on which you are running the plugin). However the dependency tree for the result will include dependencies on the MR dataset and any of its plugins.

## Creating linking datasets

Linked datasets can be created from the API using the `LinkDataset()` method on `MimDataset` classes.

The GUI does not currently have the option to link datasets, but existing linkages can be viewed and removed.


## Viewing and removing linked datasets

When the primary dataset is being viewed in the PTK GUI, any linked datasets are shown in the sidebar in a **Linked Series** list. You can right-click to remove linkages. This won't remove the datasets, it will only remove the linkages.
