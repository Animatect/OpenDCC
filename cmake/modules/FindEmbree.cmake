#
# Copyright 2017 Pixar
#
# Licensed under the Apache License, Version 2.0 (the "Apache License") with the following modification; you may not use
# this file except in compliance with the Apache License and the following modification to it: Section 6. Trademarks. is
# deleted and replaced with:
#
# 1. Trademarks. This License does not grant permission to use the trade names, trademarks, service marks, or product
#   names of the Licensor and its affiliates, except as required to comply with Section 4(c) of the License and to
#   reproduce the content of the NOTICE file.
#
# You may obtain a copy of the Apache License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the Apache License with the
# above modification is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied. See the Apache License for the specific language governing permissions and limitations under the Apache
# License.
#
# =============================================================================
#
# The module defines the following variables: EMBREE_INCLUDE_DIR - path to embree header directory EMBREE_LIBRARY     -
# path to embree library file EMBREE_FOUND   - true if embree was found
#
# Example usage: find_package(EMBREE) if(EMBREE_FOUND) message("EMBREE found: ${EMBREE_LIBRARY}") endif()
#
# =============================================================================

if(Embree_FIND_VERSION)
    set(EMBREE_FIND_VERSION ${Embree_FIND_VERSION})
else()
    set(EMBREE_FIND_VERSION 3)
endif()

# Support Houdini's embree_sidefx variant
if(APPLE)
    set(EMBREE_LIB_NAMES libembree3.dylib libembree_sidefx.dylib)
elseif(UNIX)
    set(EMBREE_LIB_NAMES libembree3.so libembree_sidefx.so)
elseif(WIN32)
    set(EMBREE_LIB_NAMES embree3.lib embree_sidefx.lib)
endif()

# Build search paths including Houdini locations
set(_embree_search_lib_paths
    "${EMBREE_LOCATION}/lib64"
    "${EMBREE_LOCATION}/lib"
    "$ENV{EMBREE_LOCATION}/lib64"
    "$ENV{EMBREE_LOCATION}/lib"
)

# Add Houdini paths if available
if(DEFINED HOUDINI_ROOT)
    list(APPEND _embree_search_lib_paths
        "${HOUDINI_ROOT}/custom/houdini/dsolib"
        "${HOUDINI_ROOT}/dsolib"
    )
endif()

find_library(
    EMBREE_LIBRARY
    NAMES ${EMBREE_LIB_NAMES}
    HINTS ${_embree_search_lib_paths}
    DOC "Embree library path")

# Build include search paths
set(_embree_search_include_paths
    "${EMBREE_LOCATION}/include"
    "$ENV{EMBREE_LOCATION}/include"
)

# Add Houdini paths if available
if(DEFINED HOUDINI_ROOT)
    list(APPEND _embree_search_include_paths
        "${HOUDINI_ROOT}/toolkit/include"
    )
endif()

# First try standard layout (embree3/rtcore.h)
find_path(
    EMBREE_INCLUDE_DIR embree${EMBREE_FIND_VERSION}/rtcore.h
    HINTS ${_embree_search_include_paths}
    DOC "Embree headers path")

# If not found, try Houdini layout where headers are directly in embree3/ folder
if(NOT EMBREE_INCLUDE_DIR AND DEFINED HOUDINI_ROOT)
    # Houdini has headers at toolkit/include/embree3/rtcore.h
    # So we need to set include dir to toolkit/include
    if(EXISTS "${HOUDINI_ROOT}/toolkit/include/embree3/rtcore.h")
        set(EMBREE_INCLUDE_DIR "${HOUDINI_ROOT}/toolkit/include" CACHE PATH "Embree headers path" FORCE)
    endif()
endif()

# Try to extract version - first check for rtcore_version.h (standard Embree)
if(EMBREE_INCLUDE_DIR AND EXISTS "${EMBREE_INCLUDE_DIR}/embree${EMBREE_FIND_VERSION}/rtcore_version.h")
    file(STRINGS "${EMBREE_INCLUDE_DIR}/embree${EMBREE_FIND_VERSION}/rtcore_version.h" TMP
         REGEX "^#define RTCORE_VERSION_MAJOR.*$")
    string(REGEX MATCHALL "[0-9]+" MAJOR ${TMP})
    file(STRINGS "${EMBREE_INCLUDE_DIR}/embree${EMBREE_FIND_VERSION}/rtcore_version.h" TMP
         REGEX "^#define RTCORE_VERSION_MINOR.*$")
    string(REGEX MATCHALL "[0-9]+" MINOR ${TMP})
    file(STRINGS "${EMBREE_INCLUDE_DIR}/embree${EMBREE_FIND_VERSION}/rtcore_version.h" TMP
         REGEX "^#define RTCORE_VERSION_PATCH.*$")
    string(REGEX MATCHALL "[0-9]+" PATCH ${TMP})

    set(EMBREE_VERSION ${MAJOR}.${MINOR}.${PATCH})
# Also check rtcore_config.h (Houdini's Embree uses RTC_VERSION_* macros here)
elseif(EMBREE_INCLUDE_DIR AND EXISTS "${EMBREE_INCLUDE_DIR}/embree${EMBREE_FIND_VERSION}/rtcore_config.h")
    file(STRINGS "${EMBREE_INCLUDE_DIR}/embree${EMBREE_FIND_VERSION}/rtcore_config.h" TMP
         REGEX "^#define RTC_VERSION_MAJOR.*$")
    string(REGEX MATCHALL "[0-9]+" MAJOR ${TMP})
    file(STRINGS "${EMBREE_INCLUDE_DIR}/embree${EMBREE_FIND_VERSION}/rtcore_config.h" TMP
         REGEX "^#define RTC_VERSION_MINOR.*$")
    string(REGEX MATCHALL "[0-9]+" MINOR ${TMP})
    file(STRINGS "${EMBREE_INCLUDE_DIR}/embree${EMBREE_FIND_VERSION}/rtcore_config.h" TMP
         REGEX "^#define RTC_VERSION_PATCH.*$")
    string(REGEX MATCHALL "[0-9]+" PATCH ${TMP})

    set(EMBREE_VERSION ${MAJOR}.${MINOR}.${PATCH})
endif()

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
    Embree
    REQUIRED_VARS EMBREE_INCLUDE_DIR EMBREE_LIBRARY
    VERSION_VAR EMBREE_VERSION)
