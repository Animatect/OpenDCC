# FindImath.cmake
# Finds Imath library
#
# This module defines:
#   Imath_FOUND - system has Imath
#   Imath::Imath - imported target

# For Houdini builds, prioritize Houdini's sidefx libraries
if(DEFINED HOUDINI_ROOT AND DCC_HOUDINI_SUPPORT)
    set(_imath_search_paths
        "${HOUDINI_ROOT}/toolkit/include"
        "${HOUDINI_ROOT}/toolkit"
    )
    set(_imath_lib_paths
        "${HOUDINI_ROOT}/custom/houdini/dsolib"
        "${HOUDINI_ROOT}/dsolib"
    )
    # For Houdini, only search sidefx library in Houdini paths
    find_path(
        IMATH_INCLUDE_DIR
        NAMES Imath/ImathConfig.h
        HINTS ${_imath_search_paths}
        PATH_SUFFIXES include
        NO_DEFAULT_PATH
    )
    find_library(
        IMATH_LIBRARY
        NAMES Imath_sidefx
        HINTS ${_imath_lib_paths}
        NO_DEFAULT_PATH
    )
    message(STATUS "FindImath: Using Houdini Imath_sidefx: ${IMATH_LIBRARY}")
else()
    # Support Houdini's bundled Imath
    if(DEFINED HOUDINI_ROOT)
        list(APPEND _imath_search_paths
            "${HOUDINI_ROOT}/toolkit/include"
            "${HOUDINI_ROOT}/toolkit"
        )
        list(APPEND _imath_lib_paths
            "${HOUDINI_ROOT}/custom/houdini/dsolib"
            "${HOUDINI_ROOT}/dsolib"
        )
    endif()

    find_path(
        IMATH_INCLUDE_DIR
        NAMES Imath/ImathConfig.h
        HINTS ${IMATH_ROOT} $ENV{IMATH_ROOT} ${_imath_search_paths}
        PATH_SUFFIXES include
    )

    find_library(
        IMATH_LIBRARY
        NAMES Imath-3_1 Imath Imath_sidefx
        HINTS ${IMATH_ROOT} $ENV{IMATH_ROOT} ${_imath_lib_paths}
        PATH_SUFFIXES lib lib64
    )
endif()

# Extract version
if(IMATH_INCLUDE_DIR AND EXISTS "${IMATH_INCLUDE_DIR}/Imath/ImathConfig.h")
    file(STRINGS "${IMATH_INCLUDE_DIR}/Imath/ImathConfig.h" _imath_version_line
         REGEX "^#define IMATH_VERSION_STRING \"[0-9]+\\.[0-9]+\\.[0-9]+\"")
    if(_imath_version_line)
        string(REGEX REPLACE ".*\"([0-9]+\\.[0-9]+\\.[0-9]+)\".*" "\\1" IMATH_VERSION "${_imath_version_line}")
    endif()
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Imath
    REQUIRED_VARS IMATH_LIBRARY IMATH_INCLUDE_DIR
    VERSION_VAR IMATH_VERSION
)

if(Imath_FOUND AND NOT TARGET Imath::Imath)
    add_library(Imath::Imath UNKNOWN IMPORTED)
    set_target_properties(Imath::Imath PROPERTIES
        IMPORTED_LOCATION "${IMATH_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${IMATH_INCLUDE_DIR}"
    )
    if(WIN32)
        set_target_properties(Imath::Imath PROPERTIES
            IMPORTED_IMPLIB "${IMATH_LIBRARY}"
        )
        # For Houdini builds on Windows, Imath is a DLL so we need IMATH_DLL
        # to ensure proper dllimport declarations for symbols like imath_half_to_float_table
        if(DCC_HOUDINI_SUPPORT)
            set_target_properties(Imath::Imath PROPERTIES
                INTERFACE_COMPILE_DEFINITIONS "IMATH_DLL"
            )
        endif()
    endif()
endif()

mark_as_advanced(IMATH_INCLUDE_DIR IMATH_LIBRARY)
