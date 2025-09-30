# - Find Gurobi Optimizer
#
# This module finds an installed Gurobi Optimizer library.
# It is an independent implementation that is not based on the script
# provided by Gurobi GmbH.
#
# USAGE:
#   In your CMakeLists.txt, add the following:
#   1. list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake") # Path to this file
#   2. find_package(GUROBI REQUIRED)
#   3. target_link_libraries(your_target PRIVATE Gurobi::gurobi)
#
# This module will define the following IMPORTED target:
#   Gurobi::gurobi  - An interface library that links to Gurobi's C and C++
#                     libraries and includes its headers.
#
# It also defines these variables, though using the target is preferred:
#   GUROBI_FOUND          - True if Gurobi was found.
#   GUROBI_INCLUDE_DIRS   - The Gurobi include directories.
#   GUROBI_LIBRARIES      - A list of the Gurobi C and C++ libraries.
#
# The search for Gurobi is controlled by the following variables:
#   GUROBI_HOME           - An environment variable pointing to the Gurobi
#                           installation root (e.g., /opt/gurobi1003/linux64).
#   GUROBI_ROOT_DIR       - A CMake variable that can be set to the Gurobi
#                           installation root. Overrides GUROBI_HOME.

# Step 1: Find the Gurobi Root Directory
# --------------------------------------------------------------------
if(DEFINED ENV{GUROBI_HOME})
    set(GUROBI_ROOT_DIR "$ENV{GUROBI_HOME}")
endif()

# Allow the user to override the environment variable with a CMake variable
set(GUROBI_ROOT_DIR "${GUROBI_ROOT_DIR}" CACHE PATH "Gurobi installation root directory")

if(NOT EXISTS "${GUROBI_ROOT_DIR}")
    message(FATAL_ERROR "Gurobi root directory not found. Please set GUROBI_HOME in your environment or GUROBI_ROOT_DIR in your CMake configuration.")
endif()


# Step 2: Extract the Gurobi Version from the Path
# --------------------------------------------------------------------
# This regex looks for "gurobi" followed by a sequence of digits (e.g., 1003)
# in the path and captures the digits.
string(REGEX MATCH "gurobi([0-9]+)" _ "${GUROBI_ROOT_DIR}")
if(NOT CMAKE_MATCH_1)
    message(WARNING "Could not determine Gurobi version from path: ${GUROBI_ROOT_DIR}. Assuming version 90 for library search.")
    set(GUROBI_VERSION "90") # Fallback to a common older version
else()
    set(GUROBI_VERSION "${CMAKE_MATCH_1}")
    # Gurobi library names don't use the patch number, e.g. 10.0.3 -> 100
    string(SUBSTRING "${GUROBI_VERSION}" 0 3 GUROBI_VERSION_MAJOR_MINOR)
    set(GUROBI_VERSION ${GUROBI_VERSION_MAJOR_MINOR})
endif()


# Step 3: Find the Required Components (Include directory and Libraries)
# --------------------------------------------------------------------
find_path(GUROBI_INCLUDE_DIR
    NAMES gurobi_c++.h
    HINTS "${GUROBI_ROOT_DIR}/include"
    DOC "Path to the Gurobi C++ header file"
)

find_library(GUROBI_LIBRARY
    NAMES gurobi${GUROBI_VERSION} # e.g., searches for libgurobi100.so
    HINTS "${GUROBI_ROOT_DIR}/lib"
    DOC "Gurobi C library"
)

find_library(GUROBI_CPP_LIBRARY
    NAMES gurobi_c++
    HINTS "${GUROBI_ROOT_DIR}/lib"
    DOC "Gurobi C++ library"
)


# Step 4: Handle standard arguments and report result
# --------------------------------------------------------------------
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GUROBI
    FOUND_VAR GUROBI_FOUND
    REQUIRED_VARS GUROBI_LIBRARY GUROBI_CPP_LIBRARY GUROBI_INCLUDE_DIR
    VERSION_VAR GUROBI_VERSION
)


# Step 5: Create Imported Target and set variables if found
# --------------------------------------------------------------------
if(GUROBI_FOUND)
    # --- Create the modern IMPORTED target ---
    if(NOT TARGET Gurobi::gurobi)
        add_library(Gurobi::gurobi INTERFACE IMPORTED)
        set_property(TARGET Gurobi::gurobi PROPERTY
            INTERFACE_INCLUDE_DIRECTORIES "${GUROBI_INCLUDE_DIR}")

        # Set system-specific libraries
        set(GUROBI_SYSTEM_LIBS "")
        if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
            set(GUROBI_SYSTEM_LIBS m pthread)
        endif()

        set_property(TARGET Gurobi::gurobi PROPERTY
            INTERFACE_LINK_LIBRARIES "${GUROBI_CPP_LIBRARY};${GUROBI_LIBRARY};${GUROBI_SYSTEM_LIBS}")
    endif()

    # --- Set classic variables for compatibility ---
    set(GUROBI_INCLUDE_DIRS "${GUROBI_INCLUDE_DIR}")
    set(GUROBI_LIBRARIES "${GUROBI_CPP_LIBRARY}" "${GUROBI_LIBRARY}")

    if(NOT GUROBI_FIND_QUIETLY)
      message(STATUS "Found Gurobi: ${GUROBI_ROOT_DIR} (version ${GUROBI_VERSION})")
      message(STATUS "  - Gurobi C++ Library: ${GUROBI_CPP_LIBRARY}")
      message(STATUS "  - Gurobi C Library: ${GUROBI_LIBRARY}")
    endif()

endif()

# Mark internal variables as advanced so they don't show up in the default CMake GUI
mark_as_advanced(GUROBI_ROOT_DIR GUROBI_INCLUDE_DIR GUROBI_LIBRARY GUROBI_CPP_LIBRARY)
