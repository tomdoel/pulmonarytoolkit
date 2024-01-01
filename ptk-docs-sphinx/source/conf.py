# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

import os

project = 'Pulmonary Toolkit'
copyright = '2023, Tom Doel'
author = 'Tom Doel'
release = '1.0.2'



# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.napoleon',
    'sphinxcontrib.matlab',
    'myst_parser']

autodoc_default_options = {
    'members': True,
    'undoc-members': True,
    'show-inheritance': True,
    'special-members': True
}
autosummary_generate = True  # Turn on sphinx.ext.autosummary

primary_domain = "mat"

conf_dir = os.path.dirname(os.path.abspath(__file__))
matlab_src_dir = os.path.abspath(os.path.join(conf_dir, '..', '..'))

napoleon_custom_sections = [
    ('Returns', 'params_style'),
    ('Syntax', 'examples_style')
]

matlab_short_links = True
# matlab_auto_link = 'all'
matlab_show_property_default_value = True
matlab_class_signature = True

templates_path = ['_templates']
exclude_patterns = []

source_suffix = ['.rst', '.md']

source_encoding = 'utf-8'

# The name of the Pygments (syntax highlighting) style to use.
pygments_style = 'sphinx'

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = "pydata_sphinx_theme"
html_static_path = ['_static']

# Need to pip install theme with pip install pydata-sphinx-theme
html_logo = "_static/PTKLogo.jpg"
html_theme_options = { "show_prev_next": False}

html_title = u'Pulmomary Toolkit'

html_context = {
   "default_mode": "light"
}
html_theme_options = {
    "logo": {
        "text": "Pulmonary Toolkit",
        "image_light": "PTKLogo.jpg",
    }
}

html_show_sphinx = False
