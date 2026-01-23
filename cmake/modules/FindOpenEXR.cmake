# FindOpenEXR.cmake
# Finds OpenEXR library
#
# This module defines:
#   OpenEXR_FOUND - system has OpenEXR
#   OpenEXR::OpenEXR - imported target

# Support Houdini's bundled OpenEXR
if(DEFINED HOUDINI_ROOT)
    list(APPEND _openexr_search_paths
        "${HOUDINI_ROOT}/toolkit/include"
        "${HOUDINI_ROOT}/toolkit"
    )
    list(APPEND _openexr_lib_paths
        "${HOUDINI_ROOT}/custom/houdini/dsolib"
        "${HOUDINI_ROOT}/dsolib"
    )
endif()

find_path(
    OPENEXR_INCLUDE_DIR
    NAMES OpenEXR/OpenEXRConfig.h
    HINTS ${OPENEXR_ROOT} $ENV{OPENEXR_ROOT} ${_openexr_search_paths}
    PATH_SUFFIXES include
)

find_library(
    OPENEXR_LIBRARY
    NAMES OpenEXR-3_1 OpenEXR OpenEXR_sidefx
    HINTS ${OPENEXR_ROOT} $ENV{OPENEXR_ROOT} ${_openexr_lib_paths}
    PATH_SUFFIXES lib lib64
)

find_library(
    OPENEXRUTIL_LIBRARY
    NAMES OpenEXRUtil-3_1 OpenEXRUtil OpenEXRUtil_sidefx
    HINTS ${OPENEXR_ROOT} $ENV{OPENEXR_ROOT} ${_openexr_lib_paths}
    PATH_SUFFIXES lib lib64
)

find_library(
    OPENEXRCORE_LIBRARY
    NAMES OpenEXRCore-3_1 OpenEXRCore OpenEXRCore_sidefx
    HINTS ${OPENEXR_ROOT} $ENV{OPENEXR_ROOT} ${_openexr_lib_paths}
    PATH_SUFFIXES lib lib64
)

find_library(
    ILMTHREAD_LIBRARY
    NAMES IlmThread-3_1 IlmThread IlmThread_sidefx
    HINTS ${OPENEXR_ROOT} $ENV{OPENEXR_ROOT} ${_openexr_lib_paths}
    PATH_SUFFIXES lib lib64
)

# Extract version
if(OPENEXR_INCLUDE_DIR AND EXISTS "${OPENEXR_INCLUDE_DIR}/OpenEXR/OpenEXRConfig.h")
    file(STRINGS "${OPENEXR_INCLUDE_DIR}/OpenEXR/OpenEXRConfig.h" _openexr_version_line
         REGEX "^#define OPENEXR_VERSION_STRING \"[0-9]+\\.[0-9]+\\.[0-9]+\"")
    if(_openexr_version_line)
        string(REGEX REPLACE ".*\"([0-9]+\\.[0-9]+\\.[0-9]+)\".*" "\\1" OPENEXR_VERSION "${_openexr_version_line}")
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(OpenEXR
    REQUIRED_VARS OPENEXR_LIBRARY OPENEXR_INCLUDE_DIR
    VERSION_VAR OPENEXR_VERSION
)

if(OpenEXR_FOUND)
    # Create main OpenEXR target
    if(NOT TARGET OpenEXR::OpenEXR)
        add_library(OpenEXR::OpenEXR UNKNOWN IMPORTED)
        set_target_properties(OpenEXR::OpenEXR PROPERTIES
            IMPORTED_LOCATION "${OPENEXR_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENEXR_INCLUDE_DIR}"
        )
        if(WIN32)
            set_target_properties(OpenEXR::OpenEXR PROPERTIES
                IMPORTED_IMPLIB "${OPENEXR_LIBRARY}"
            )
        endif()
    endif()

    # Create OpenEXRUtil target
    if(OPENEXRUTIL_LIBRARY AND NOT TARGET OpenEXR::OpenEXRUtil)
        add_library(OpenEXR::OpenEXRUtil UNKNOWN IMPORTED)
        set_target_properties(OpenEXR::OpenEXRUtil PROPERTIES
            IMPORTED_LOCATION "${OPENEXRUTIL_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENEXR_INCLUDE_DIR}"
        )
        if(WIN32)
            set_target_properties(OpenEXR::OpenEXRUtil PROPERTIES
                IMPORTED_IMPLIB "${OPENEXRUTIL_LIBRARY}"
            )
        endif()
    endif()

    # Create OpenEXRCore target
    if(OPENEXRCORE_LIBRARY AND NOT TARGET OpenEXR::OpenEXRCore)
        add_library(OpenEXR::OpenEXRCore UNKNOWN IMPORTED)
        set_target_properties(OpenEXR::OpenEXRCore PROPERTIES
            IMPORTED_LOCATION "${OPENEXRCORE_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENEXR_INCLUDE_DIR}"
        )
        if(WIN32)
            set_target_properties(OpenEXR::OpenEXRCore PROPERTIES
                IMPORTED_IMPLIB "${OPENEXRCORE_LIBRARY}"
            )
        endif()
    endif()

    # Create IlmThread target
    if(ILMTHREAD_LIBRARY AND NOT TARGET OpenEXR::IlmThread)
        add_library(OpenEXR::IlmThread UNKNOWN IMPORTED)
        set_target_properties(OpenEXR::IlmThread PROPERTIES
            IMPORTED_LOCATION "${ILMTHREAD_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${OPENEXR_INCLUDE_DIR}"
        )
        if(WIN32)
            set_target_properties(OpenEXR::IlmThread PROPERTIES
                IMPORTED_IMPLIB "${ILMTHREAD_LIBRARY}"
            )
        endif()
    endif()

    set(OPENEXR_LIBRARIES
        ${OPENEXR_LIBRARY}
        ${OPENEXRUTIL_LIBRARY}
        ${OPENEXRCORE_LIBRARY}
        ${ILMTHREAD_LIBRARY}
    )
endif()

mark_as_advanced(OPENEXR_INCLUDE_DIR OPENEXR_LIBRARY OPENEXRUTIL_LIBRARY OPENEXRCORE_LIBRARY ILMTHREAD_LIBRARY)
