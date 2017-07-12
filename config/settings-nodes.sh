#!/bin/bash

# -- Configuration for XTEC Blocs ----------------------------------------------

# List of language codes to translate
declare -a LANGS=('ca' 'es_ES' 'eu' 'fr_FR' 'gl_ES' 'oci')

# GIT repository for the WordPress instance
WORDPRESS_URL=https://github.com/projectestac/agora_nodes.git

# WordPress source folder on the repository
SRC=