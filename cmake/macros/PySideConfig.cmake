# Macro to get various pyside / python include / link flags and paths. Uses the not entirely supported
# utils/pyside2_config.py file.

# For Houdini builds, set PYTHONPATH to include Houdini's site-packages-forced
# which contains PySide2, shiboken2, and shiboken2_generator
# Can be overridden by setting DCC_PYSIDE2_PATH and DCC_SHIBOKEN_GENERATOR_PATH
if(DCC_HOUDINI_SUPPORT AND DEFINED HOUDINI_ROOT)
    # Detect Python version from PYTHON_EXECUTABLE path
    # Extract pythonXX directory name (e.g., python39, python310, python311)
    get_filename_component(_python_dir "${PYTHON_EXECUTABLE}" DIRECTORY)
    get_filename_component(_python_version_dir "${_python_dir}" NAME)
    message(STATUS "Detected Houdini Python directory: ${_python_version_dir}")

    # Allow override via CMake variables (useful when using separate PySide2 installation)
    if(DEFINED ENV{DCC_PYSIDE2_PATH})
        set(_pyside_pythonpath "$ENV{DCC_PYSIDE2_PATH}")
        message(STATUS "Using custom PySide2 path from DCC_PYSIDE2_PATH: ${_pyside_pythonpath}")
    else()
        # Houdini stores PySide2/shiboken2 in site-packages-forced
        set(_pyside_pythonpath "${HOUDINI_ROOT}/${_python_version_dir}/lib/site-packages-forced")
        message(STATUS "Using Houdini PySide2 path: ${_pyside_pythonpath}")
    endif()

    if(DEFINED ENV{DCC_SHIBOKEN_GENERATOR_PATH})
        set(_shiboken_generator_dir "$ENV{DCC_SHIBOKEN_GENERATOR_PATH}")
        message(STATUS "Using custom shiboken generator path from DCC_SHIBOKEN_GENERATOR_PATH: ${_shiboken_generator_dir}")
    else()
        # Also set the generator directory environment variable
        set(_shiboken_generator_dir "${HOUDINI_ROOT}/${_python_version_dir}/lib/site-packages-forced/shiboken2_generator")
        message(STATUS "Using Houdini shiboken generator path: ${_shiboken_generator_dir}")
    endif()
endif()

macro(pyside2_config option output_var)
    if(${ARGC} GREATER 2)
        set(is_list ${ARGV2})
    else()
        set(is_list "")
    endif()

    # Set up environment for Houdini builds
    if(DCC_HOUDINI_SUPPORT AND DEFINED _pyside_pythonpath)
        set(_pyside_env "PYTHONPATH=${_pyside_pythonpath}" "SHIBOKEN_GENERATOR_DIR=${_shiboken_generator_dir}")
        execute_process(
            COMMAND ${CMAKE_COMMAND} -E env ${_pyside_env}
                    ${PYTHON_EXECUTABLE} "${PROJECT_SOURCE_DIR}/cmake/macros/pyside2_config.py" ${option}
            OUTPUT_VARIABLE ${output_var}
            OUTPUT_STRIP_TRAILING_WHITESPACE)
    else()
        execute_process(
            COMMAND ${PYTHON_EXECUTABLE} "${PROJECT_SOURCE_DIR}/cmake/macros/pyside2_config.py" ${option}
            OUTPUT_VARIABLE ${output_var}
            OUTPUT_STRIP_TRAILING_WHITESPACE)
    endif()

    if("${${output_var}}" STREQUAL "")
        message(FATAL_ERROR "Error: Calling pyside2_config.py ${option} returned no output.")
    endif()
    if(is_list)
        string(REPLACE " " ";" ${output_var} "${${output_var}}")
    endif()
endmacro()

pyside2_config(--shiboken2-module-path SHIBOKEN_PYTHON_MODULE_DIR)
pyside2_config(--shiboken2-module-path shiboken2_module_path) # TODO not sure why it needed by build, investigate
pyside2_config(--shiboken2-generator-path shiboken2_generator_path)
pyside2_config(--pyside2-path PYSIDE_PYTHONPATH)
pyside2_config(--pyside2-path pyside2_path) # TODO not sure why it needed by build, investigate
pyside2_config(--pyside2-include-path PySide2_INCLUDE_DIR)
pyside2_config(--pyside2-shared-libraries-cmake pyside2_shared_libraries 0)
pyside2_config(--python-include-path python_include_dir)
pyside2_config(--shiboken2-generator-include-path shiboken_include_dir)
pyside2_config(--shiboken2-module-shared-libraries-cmake shiboken_shared_libraries 0)
pyside2_config(--python-link-flags-cmake python_linking_data 0)

set(shiboken_path "${shiboken2_generator_path}/shiboken2${CMAKE_EXECUTABLE_SUFFIX}")
if(NOT EXISTS "${shiboken_path}")
    message(FATAL_ERROR "Shiboken executable not found at path: ${shiboken_path}")
endif()

set(PYSIDE_TYPESYSTEMS "${pyside2_path}/typesystems")
set(PYSIDE_GLUE "${pyside2_path}/glue")

add_library(Shiboken2::libshiboken SHARED IMPORTED)
set_target_properties(Shiboken2::libshiboken PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${shiboken_include_dir}")
set_property(
    TARGET Shiboken2::libshiboken
    APPEND
    PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO RELEASE)

if(MSVC)
    set_target_properties(Shiboken2::libshiboken PROPERTIES IMPORTED_IMPLIB_RELWITHDEBINFO "${shiboken_shared_libraries}"
                                                            IMPORTED_IMPLIB_RELEASE "${shiboken_shared_libraries}")
else()
    set_target_properties(
        Shiboken2::libshiboken PROPERTIES IMPORTED_LOCATION_RELWITHDEBINFO "${shiboken_shared_libraries}"
                                          IMPORTED_LOCATION_RELEASE "${shiboken_shared_libraries}")
endif()

add_executable(Shiboken2::shiboken2 IMPORTED)
set_property(
    TARGET Shiboken2::shiboken2
    APPEND
    PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO RELEASE)
set_target_properties(Shiboken2::shiboken2 PROPERTIES IMPORTED_LOCATION_RELWITHDEBINFO "${shiboken_path}"
                                                      IMPORTED_LOCATION_RELEASE "${shiboken_path}")

add_library(PySide2::pyside2 SHARED IMPORTED)
set_target_properties(PySide2::pyside2 PROPERTIES INTERFACE_INCLUDE_DIRECTORIES "${PySide2_INCLUDE_DIR}")

set_property(
    TARGET PySide2::pyside2
    APPEND
    PROPERTY IMPORTED_CONFIGURATIONS RELWITHDEBINFO RELEASE)
set_target_properties(
    PySide2::pyside2
    PROPERTIES IMPORTED_LINK_DEPENDENT_LIBRARIES_RELWITHDEBINFO "Shiboken2::libshiboken;Qt5::Qml;Qt5::Core"
               IMPORTED_LINK_DEPENDENT_LIBRARIES_RELEASE "Shiboken2::libshiboken;Qt5::Qml;Qt5::Core")
if(MSVC)
    set_target_properties(PySide2::pyside2 PROPERTIES IMPORTED_IMPLIB_RELWITHDEBINFO "${pyside2_shared_libraries}"
                                                      IMPORTED_IMPLIB_RELEASE "${pyside2_shared_libraries}")
else()
    set_target_properties(PySide2::pyside2 PROPERTIES IMPORTED_LOCATION_RELWITHDEBINFO "${pyside2_shared_libraries}"
                                                      IMPORTED_LOCATION_RELEASE "${pyside2_shared_libraries}")
endif()
