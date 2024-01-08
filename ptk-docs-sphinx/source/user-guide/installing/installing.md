# Installing the Pulmonary Toolkit

The recomended way to use the PTK is to obtain the code using git and run
it using Matlab.

```{tip}
Alternatively, if you want to run PTK without Matlab, you can run an older version as a pre-built executable. See [Installing without Matlab](../user-guide/installing-without-matlab) for more information.
```

## 1. Required software

You should have the following software installed before continuing:
 * Matlab version R2010b or later
 * The Matlab Image Processing Toolbox
 * A C++ compiler
 * A git client (eg git command line, GitHub Desktop, SourceTree)

Please see [Required Software](required-software.md) for more information about how to install these.


## 2. Download the Pulmonary Toolkit using git

The main PTK codebase lives on GitHub: https://github.com/tomdoel/pulmonarytoolkit.
To obtain the code, you clone it using your git client.

### Using a command-line git client
You can clone PTK using the following command:

```console
git clone https://github.com/tomdoel/pulmonarytoolkit.git
```

This will download the code into a folder called “pulmonarytoolkit"

### Using GitHub Desktop

Go to GitHub: https://github.com/tomdoel/pulmonarytoolkit
Click Clone or Download
Click Open in Desktop
Select a folder to store your local clone

### Using SourceTree

Open SourceTree
From the File menu, click New / Clone.
Click + New Repository
Click Clone from URL
In the Source URL, enter https://github.com/tomdoel/pulmonarytoolkit
Choose a destination path
Click Clone


---

## 3. Run the Pulmonary Toolkit

See [Running the Pulmonary Toolkit](../user-guide/running)

---

## 4. Updating the Pulmonary Toolkit

To update to the latest version of PTK, you "pull" the latest changes using git.

Using command-line git, make sure you are inside the pulmonarytoolkit directory:

```console
cd pulmonarytoolkit
git pull
```
