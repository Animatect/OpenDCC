#
# Copyright 2016 Pixar
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

# Support Houdini's bundled OpenImageIO
# For Houdini builds, prioritize Houdini's libraries to ensure namespace consistency
if(DEFINED HOUDINI_ROOT AND DCC_HOUDINI_SUPPORT)
    # Houdini uses OpenImageIO_sidefx library with HOIIO namespace
    set(_oiio_search_paths "${HOUDINI_ROOT}/toolkit/include" "${HOUDINI_ROOT}/toolkit")
    set(_oiio_lib_paths "${HOUDINI_ROOT}/custom/houdini/dsolib" "${HOUDINI_ROOT}/dsolib")

    find_path(OIIO_BASE_DIR include/OpenImageIO/oiioversion.h HINTS ${_oiio_search_paths})
    find_path(
        OIIO_LIBRARY_DIR
        NAMES OpenImageIO_sidefx.lib
        HINTS ${_oiio_lib_paths}
        DOC "OpenImageIO library path")

    find_path(
        OIIO_INCLUDE_DIR OpenImageIO/oiioversion.h
        HINTS ${_oiio_search_paths}
        PATH_SUFFIXES include/
        DOC "OpenImageIO headers path")

    # For Houdini, only use _sidefx libraries
    find_library(
        OIIO_OpenImageIO_LIBRARY
        NAMES OpenImageIO_sidefx
        HINTS ${_oiio_lib_paths}
        DOC "OIIO's OpenImageIO library path")

    # Houdini also provides OpenImageIO_Util_sidefx library separately
    find_library(
        OIIO_OpenImageIO_Util_LIBRARY
        NAMES OpenImageIO_Util_sidefx
        HINTS ${_oiio_lib_paths}
        DOC "OIIO's OpenImageIO_Util library path")

    if(OIIO_OpenImageIO_LIBRARY)
        list(APPEND OIIO_LIBRARIES ${OIIO_OpenImageIO_LIBRARY})
    endif()
    if(OIIO_OpenImageIO_Util_LIBRARY)
        list(APPEND OIIO_LIBRARIES ${OIIO_OpenImageIO_Util_LIBRARY})
    endif()
else()
    if(DEFINED HOUDINI_ROOT)
        list(APPEND _oiio_search_paths "${HOUDINI_ROOT}/toolkit/include" "${HOUDINI_ROOT}/toolkit")
        list(APPEND _oiio_lib_paths "${HOUDINI_ROOT}/custom/houdini/dsolib" "${HOUDINI_ROOT}/dsolib")
    endif()

    if(UNIX)
        find_path(OIIO_BASE_DIR include/OpenImageIO/oiioversion.h HINTS "${OIIO_LOCATION}" "$ENV{OIIO_LOCATION}"
                                                                        "/opt/oiio" ${_oiio_search_paths})
        find_path(
            OIIO_LIBRARY_DIR libOpenImageIO.so
            HINTS "${OIIO_LOCATION}" "$ENV{OIIO_LOCATION}" "${OIIO_BASE_DIR}" ${_oiio_lib_paths}
            PATH_SUFFIXES lib/
            DOC "OpenImageIO library path")
    elseif(WIN32)
        find_path(OIIO_BASE_DIR include/OpenImageIO/oiioversion.h HINTS "${OIIO_LOCATION}" "$ENV{OIIO_LOCATION}" ${_oiio_search_paths})
        find_path(
            OIIO_LIBRARY_DIR
            NAMES OpenImageIO.lib OpenImageIO_sidefx.lib
            HINTS "${OIIO_LOCATION}" "$ENV{OIIO_LOCATION}" "${OIIO_BASE_DIR}" ${_oiio_lib_paths}
            PATH_SUFFIXES lib/
            DOC "OpenImageIO library path")
    endif()

    find_path(
        OIIO_INCLUDE_DIR OpenImageIO/oiioversion.h
        HINTS "${OIIO_LOCATION}" "$ENV{OIIO_LOCATION}" "${OIIO_BASE_DIR}" ${_oiio_search_paths}
        PATH_SUFFIXES include/
        DOC "OpenImageIO headers path")

    # Support Houdini's _sidefx suffixed libraries
    foreach(OIIO_LIB OpenImageIO OpenImageIO_Util)
        # Try standard names first, then Houdini variants
        find_library(
            OIIO_${OIIO_LIB}_LIBRARY
            NAMES ${OIIO_LIB} ${OIIO_LIB}_sidefx
            HINTS "${OIIO_LOCATION}" "$ENV{OIIO_LOCATION}" "${OIIO_BASE_DIR}" ${_oiio_lib_paths}
            PATH_SUFFIXES lib/
            DOC "OIIO's ${OIIO_LIB} library path")

        if(OIIO_${OIIO_LIB}_LIBRARY)
            list(APPEND OIIO_LIBRARIES ${OIIO_${OIIO_LIB}_LIBRARY})
        endif()
    endforeach(OIIO_LIB)
endif()

list(APPEND OIIO_INCLUDE_DIRS ${OIIO_INCLUDE_DIR})

foreach(
    OIIO_BIN
    iconvert
    idiff
    igrep
    iinfo
    iv
    maketx
    oiiotool)

    find_program(
        OIIO_${OIIO_BIN}_BINARY ${OIIO_BIN}
        HINTS "${OIIO_LOCATION}" "$ENV{OIIO_LOCATION}" "${OIIO_BASE_DIR}" "${HOUDINI_ROOT}/bin"
        PATH_SUFFIXES bin/
        DOC "OIIO's ${OIIO_BIN} binary")
    if(OIIO_${OIIO_BIN}_BINARY)
        list(APPEND OIIO_BINARIES ${OIIO_${OIIO_BIN}_BINARY})
    endif()
endforeach(OIIO_BIN)

if(OIIO_INCLUDE_DIRS AND EXISTS "${OIIO_INCLUDE_DIR}/OpenImageIO/oiioversion.h")
    file(STRINGS ${OIIO_INCLUDE_DIR}/OpenImageIO/oiioversion.h MAJOR REGEX "#define OIIO_VERSION_MAJOR.*$")
    file(STRINGS ${OIIO_INCLUDE_DIR}/OpenImageIO/oiioversion.h MINOR REGEX "#define OIIO_VERSION_MINOR.*$")
    file(STRINGS ${OIIO_INCLUDE_DIR}/OpenImageIO/oiioversion.h PATCH REGEX "#define OIIO_VERSION_PATCH.*$")
    string(REGEX MATCHALL "[0-9]+" MAJOR ${MAJOR})
    string(REGEX MATCHALL "[0-9]+" MINOR ${MINOR})
    string(REGEX MATCHALL "[0-9]+" PATCH ${PATCH})
    set(OIIO_VERSION "${MAJOR}.${MINOR}.${PATCH}")
endif()

# For Houdini builds, FindHoudiniUSD.cmake already sets OIIO variables
# Skip the find if OIIO_LIBRARIES is already set (by FindHoudiniUSD)
if(DCC_HOUDINI_SUPPORT AND OIIO_OpenImageIO_LIBRARY)
    message(STATUS "[FindOpenImageIO] Using pre-set OIIO from FindHoudiniUSD: ${OIIO_OpenImageIO_LIBRARY}")
endif()

# handle the QUIETLY and REQUIRED arguments and set OIIO_FOUND to TRUE if all listed variables are TRUE
include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(
    OpenImageIO
    REQUIRED_VARS OIIO_LIBRARIES OIIO_INCLUDE_DIRS
    VERSION_VAR OIIO_VERSION)
