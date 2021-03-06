#-----------------------------------------------------------------------------
#
# Ryzom Core
#  Authors: Nevrax and the Ryzom Core Community
#  Version: 0.12.0
#
# Notes:
#   * Changing install location: add -DCMAKE_INSTALL_PREFIX:PATH=/my/new/path
#   * Changing specific install location variables:
#       * NL_ETC_PREFIX (default: $CMAKE_INSTALL_PREFIX/etc)
#       * NL_SHARE_PREFIX (default: $CMAKE_INSTALL_PREFIX/share)
#       * NL_BIN_PREFIX (default: $CMAKE_INSTALL_PREFIX/bin)
#       * NL_SBIN_PREFIX  (default: $CMAKE_INSTALL_PREFIX/sbin)
#       * NL_LIB_PREFIX  (default: $CMAKE_INSTALL_PREFIX/lib)
#       * NL_DRIVER_PREFIX  (default: $CMAKE_INSTALL_PREFIX/lib (windows) or $CMAKE_INSTALL_PREFIX/lib/nel)
#   * Enable building of documentation: add -DBUILD_DOCUMENTATION:BOOL=ON - new make target: DoxygenDoc
#   * Updating version: update header (above) but also update NL_VERSION below.
#   * To build binary archive, use the 'package' target.
#     To build source archive, use the 'package_source' target.

#-----------------------------------------------------------------------------
# Load some macros.
SET(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/CMakeModules;${CMAKE_MODULE_PATH}")
#-----------------------------------------------------------------------------
# Set CMake 2.6 Policies.
IF(COMMAND cmake_policy)
  # Works around warnings libraries linked against that don't
  # have absolute paths (e.g. -lpthread)
  cmake_policy(SET CMP0003 NEW)

  # allow to link to qtmain automatically under Windows
  IF(POLICY CMP0020)
    CMAKE_POLICY(SET CMP0020 NEW)
  ENDIF()
ENDIF()

INCLUDE(nel)
INCLUDE(ConfigureChecks)
INCLUDE(CheckDepends)
INCLUDE(${CMAKE_ROOT}/Modules/Documentation.cmake OPTIONAL)

# Force out of source builds.
CHECK_OUT_OF_SOURCE()

# To be able to specify a different deployment target on Mac OS X :
# export MACOSX_DEPLOYMENT_TARGET=10.6

IF(CMAKE_VERSION VERSION_GREATER "2.8.10")
  STRING(TIMESTAMP CURRENT_YEAR "%Y")
ELSE()
  SET(CURRENT_YEAR "2016")
ENDIF()

CMAKE_MINIMUM_REQUIRED(VERSION 2.6)
PROJECT(RyzomCore CXX C)
SET(NL_VERSION_MAJOR 0)
SET(NL_VERSION_MINOR 12)
SET(NL_VERSION_PATCH 0)
SET(YEAR "2004-${CURRENT_YEAR}")
SET(AUTHOR "Winch Gate and The Ryzom Core Community")

#-----------------------------------------------------------------------------
# Redirect output files
SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# DLL should be in the same directory as EXE under Windows
IF(WIN32)
  SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
ELSE()
  SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
ENDIF()

IF(WIN32)
  IF(WITH_MFC)
    FIND_PACKAGE(MFC QUIET)
  ENDIF()
ENDIF()

#-----------------------------------------------------------------------------
# Set default config options
#
NL_SETUP_DEFAULT_OPTIONS()
NL_SETUP_NEL_DEFAULT_OPTIONS()
NL_SETUP_NELNS_DEFAULT_OPTIONS()
NL_SETUP_RYZOM_DEFAULT_OPTIONS()
NL_SETUP_SNOWBALLS_DEFAULT_OPTIONS()

NL_SETUP_PREFIX_PATHS()
RYZOM_SETUP_PREFIX_PATHS()

NL_SETUP_BUILD()
NL_SETUP_BUILD_FLAGS()

#-----------------------------------------------------------------------------
#Platform specifics

SETUP_EXTERNAL()

IF(WIN32)
  SET(WINSOCK2_LIB ws2_32.lib)

  IF(WITH_MFC)
    FIND_PACKAGE(CustomMFC REQUIRED)
  ENDIF()
ENDIF()

FIND_PACKAGE(ZLIB REQUIRED)
FIND_PACKAGE(LibXml2 REQUIRED)
FIND_PACKAGE(PNG REQUIRED)
FIND_PACKAGE(OpenSSL REQUIRED)
FIND_PACKAGE(GIF)
FIND_PACKAGE(Jpeg)

IF(WIN32)
  SET(OPENSSL_LIBRARIES ${OPENSSL_LIBRARIES} Crypt32.lib)
ENDIF()

IF(WITH_LIBOVR)
  FIND_PACKAGE(LibOVR)
ENDIF()

IF(WITH_LIBVR)
  FIND_PACKAGE(LibVR)
ENDIF()

NL_CONFIGURE_CHECKS()

IF(WITH_STATIC_LIBXML2)
  SET(LIBXML2_DEFINITIONS ${LIBXML2_DEFINITIONS} -DLIBXML_STATIC)
ENDIF()

IF(WITH_LIBXML2_ICONV)
  FIND_PACKAGE(Iconv REQUIRED)
  INCLUDE_DIRECTORIES(${ICONV_INCLUDE_DIR})
  SET(LIBXML2_LIBRARIES ${LIBXML2_LIBRARIES} ${ICONV_LIBRARIES})
ENDIF()

IF(WITH_STATIC)
  # libxml2 could need winsock2 library
  IF(WINSOCK2_LIB)
    SET(LIBXML2_LIBRARIES ${LIBXML2_LIBRARIES} ${WINSOCK2_LIB})
  ENDIF()

  IF(UNIX)
    # under Linux and OS X, recent libxml2 versions are linked against liblzma
    FIND_PACKAGE(LibLZMA)
    IF(LIBLZMA_LIBRARIES)
      SET(LIBXML2_LIBRARIES ${LIBXML2_LIBRARIES} ${LIBLZMA_LIBRARIES})
    ENDIF()
  ENDIF()
ENDIF()

INCLUDE(${CMAKE_CURRENT_SOURCE_DIR}/CMakeModules/PCHSupport.cmake)

IF(FINAL_VERSION)
  ADD_DEFINITIONS(-DFINAL_VERSION=1)
ENDIF()

IF(WITH_SSE2)
  ADD_DEFINITIONS(-DNL_HAS_SSE2)
  IF(WITH_SSE3)
    ADD_DEFINITIONS(-DNL_HAS_SSE3)
  ENDIF()
ENDIF()

IF(APPLE)
  FIND_LIBRARY(CARBON_FRAMEWORK Carbon)
  FIND_LIBRARY(FOUNDATION_FRAMEWORK Foundation)

  IF(APPLE_CERTIFICATE)
    # Find codesign_allocate

    # Xcode 7.0 and later versions
    SET(CODESIGN_ALLOCATE ${OSX_DEVELOPER_ROOT}/Toolchains/XcodeDefault.xctoolchain/usr/bin/codesign_allocate)

    IF(NOT EXISTS "${CODESIGN_ALLOCATE}")
      # Xcode 6.4 and previous versions
      SET(CODESIGN_ALLOCATE ${CMAKE_OSX_SYSROOT}/usr/bin/codesign_allocate)
    ENDIF()

    IF(NOT EXISTS "${CODESIGN_ALLOCATE}")
      # System path
      SET(CODESIGN_ALLOCATE /usr/bin/codesign_allocate)
    ENDIF()

    IF(NOT EXISTS "${CODESIGN_ALLOCATE}")
      MESSAGE(WARNING "Unable to find codesign_allocate in standard directories")
      SET(CODESIGN_ALLOCATE)
    ENDIF()
  ENDIF()
ENDIF()

MACRO(ADD_QT_LIBRARY _NAME)
  IF(WIN32)
    SET(_PREFIX "Qt5")
    SET(_EXT "lib")
  ELSE()
    SET(_PREFIX "libQt5")
    SET(_EXT "a")
  ENDIF()
  SET(_LIB "${QT_LIBRARY_DIR}/${_PREFIX}${_NAME}.${_EXT}")
  IF(EXISTS ${_LIB})
    SET(QT_LIBRARIES ${QT_LIBRARIES} optimized ${_LIB})
  ENDIF()
  SET(_LIB "${QT_LIBRARY_DIR}/${_PREFIX}${_NAME}d.${_EXT}")
  IF(EXISTS ${_LIB})
    SET(QT_LIBRARIES ${QT_LIBRARIES} debug ${_LIB})
  ENDIF()
ENDMACRO()

MACRO(ADD_QT_PLUGIN _TYPE _NAME)
  IF(WIN32)
    SET(_PREFIX "")
    SET(_EXT "lib")
  ELSE()
    SET(_PREFIX "lib")
    SET(_EXT "a")
  ENDIF()
  SET(_LIB "${QT_PLUGINS_DIR}/${_TYPE}/${_PREFIX}${_NAME}.${_EXT}")
  IF(EXISTS ${_LIB})
    SET(QT_LIBRARIES ${QT_LIBRARIES} optimized ${_LIB})
  ENDIF()
  SET(_LIB "${QT_PLUGINS_DIR}/${_TYPE}/${_PREFIX}${_NAME}d.${_EXT}")
  IF(EXISTS ${_LIB})
    SET(QT_LIBRARIES ${QT_LIBRARIES} debug ${_LIB})
  ENDIF()
ENDMACRO()

IF(WITH_QT5)
  CMAKE_MINIMUM_REQUIRED(VERSION 2.8.11 FATAL_ERROR)

  SET(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${QTDIR} $ENV{QTDIR})

  FIND_PACKAGE(Qt5Core QUIET)

  IF(Qt5Core_FOUND)
    # Check if we are using Qt static or shared libraries
    GET_TARGET_PROPERTY(_FILE Qt5::Core IMPORTED_LOCATION_RELEASE)

    SET(QT_VERSION "${Qt5Core_VERSION_STRING}")
    SET(_VERSION "${QT_VERSION}")

    IF(_FILE MATCHES "\\.(lib|a)$")
      SET(QT_STATIC ON)
      SET(_VERSION "${_VERSION} static version")
    ELSE()
      SET(QT_STATIC OFF)
      SET(_VERSION "${_VERSION} shared version")
    ENDIF()

    MESSAGE(STATUS "Found Qt ${_VERSION}")

    # These variables are not defined with Qt5 CMake modules
    SET(QT_BINARY_DIR "${_qt5Core_install_prefix}/bin")
    SET(QT_LIBRARY_DIR "${_qt5Core_install_prefix}/lib")
    SET(QT_PLUGINS_DIR "${_qt5Core_install_prefix}/plugins")
    SET(QT_TRANSLATIONS_DIR "${_qt5Core_install_prefix}/translations")

    # Fix wrong include directories with Qt 5 under Mac OS X
    INCLUDE_DIRECTORIES("${_qt5Core_install_prefix}/include")

    FIND_PACKAGE(Qt5Gui)
    FIND_PACKAGE(Qt5Widgets)
    FIND_PACKAGE(Qt5OpenGL)
    FIND_PACKAGE(Qt5Xml)
    FIND_PACKAGE(Qt5LinguistTools)
    FIND_PACKAGE(Qt5Network)

    IF(QT_STATIC)
      ADD_DEFINITIONS(-DQT_STATICPLUGIN)

      SET(QT_LIBRARIES Qt5::Widgets)

      # Gui
      SET(QT_LIBRARIES ${QT_LIBRARIES} Qt5::Gui Qt5::OpenGL)

      ADD_QT_LIBRARY(PrintSupport)

      IF(WIN32)
        SET(QT_LIBRARIES ${QT_LIBRARIES}
          ${WINSDK_LIBRARY_DIR}/Imm32.lib
          ${WINSDK_LIBRARY_DIR}/OpenGL32.lib
          ${WINSDK_LIBRARY_DIR}/WinMM.Lib)
        ADD_QT_PLUGIN(platforms qwindows)
        ADD_QT_LIBRARY(PlatformSupport)
      ELSEIF(APPLE)
        # Cups needs .dylib
        SET(OLD_CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})
        SET(CMAKE_FIND_LIBRARY_SUFFIXES .dylib)
        FIND_LIBRARY(CUPS_LIBRARY cups)
        SET(CMAKE_FIND_LIBRARY_SUFFIXES ${OLD_CMAKE_FIND_LIBRARY_SUFFIXES})

        FIND_LIBRARY(IOKIT_FRAMEWORK IOKit)
        FIND_LIBRARY(COCOA_FRAMEWORK Cocoa)
        FIND_LIBRARY(SYSTEMCONFIGURATION_FRAMEWORK SystemConfiguration)
        FIND_LIBRARY(OPENGL_FRAMEWORK NAMES OpenGL)

        SET(QT_LIBRARIES ${QT_LIBRARIES}
          ${CUPS_LIBRARY}
          ${COCOA_FRAMEWORK}
          ${SYSTEMCONFIGURATION_FRAMEWORK}
          ${IOKIT_FRAMEWORK}
          ${OPENGL_FRAMEWORK})

        ADD_QT_PLUGIN(printsupport cocoaprintersupport)
        ADD_QT_PLUGIN(platforms qcocoa)
        ADD_QT_LIBRARY(PlatformSupport)
      ELSE()
        # order is very important there
        ADD_QT_PLUGIN(platforms qxcb)
        ADD_QT_PLUGIN(xcbglintegrations qxcb-glx-integration)

        ADD_QT_LIBRARY(XcbQpa)
        ADD_QT_LIBRARY(PlatformSupport)
        SET(QT_LIBRARIES ${QT_LIBRARIES} -lX11-xcb -lXi -lSM -lICE -lxcb -lGL -lxcb-glx)
        IF(EXISTS "${QT_LIBRARY_DIR}/libxcb-static.a")
          SET(QT_LIBRARIES ${QT_LIBRARIES} "${QT_LIBRARY_DIR}/libxcb-static.a")
        ENDIF()
        SET(QT_LIBRARIES ${QT_LIBRARIES} -lfontconfig)
        ADD_QT_LIBRARY(DBus)
      ENDIF()

      ADD_QT_PLUGIN(imageformats qgif)
      ADD_QT_PLUGIN(imageformats qicns)
      ADD_QT_PLUGIN(imageformats qico)
      ADD_QT_PLUGIN(imageformats qjpeg)

      # harfbuzz is needed since Qt 5.3
      IF(UNIX)
        SET(HB_LIB "${QT_LIBRARY_DIR}/libqtharfbuzzng.a")
      ELSEIF(WIN32)
        SET(HB_LIB "${QT_LIBRARY_DIR}/qtharfbuzzng.lib")
      ENDIF()
      IF(EXISTS ${HB_LIB})
        SET(QT_LIBRARIES ${QT_LIBRARIES} ${HB_LIB})
      ENDIF()

      # freetype is needed since Qt 5.5
      FIND_PACKAGE(Freetype)

      IF(FREETYPE_FOUND)
        SET(QT_LIBRARIES ${QT_LIBRARIES} ${FREETYPE_LIBRARIES})
      ELSE()
        IF(UNIX)
          SET(FREETYPE_LIB "${QT_LIBRARY_DIR}/libqtfreetype.a")
        ELSEIF(WIN32)
          SET(FREETYPE_LIB "${QT_LIBRARY_DIR}/qtfreetype.lib")
        ENDIF()
        IF(EXISTS ${FREETYPE_LIB})
          SET(QT_LIBRARIES ${QT_LIBRARIES} ${FREETYPE_LIB})
        ENDIF()
      ENDIF()

      ADD_QT_PLUGIN(accessible qtaccessiblewidgets)

      SET(QT_LIBRARIES ${QT_LIBRARIES} ${PNG_LIBRARIES} ${JPEG_LIBRARY})

      # Network
      SET(QT_LIBRARIES ${QT_LIBRARIES} Qt5::Network Qt5::Xml)
      SET(QT_LIBRARIES ${QT_LIBRARIES} ${OPENSSL_LIBRARIES} ${ZLIB_LIBRARIES})

      IF(WIN32)
        SET(QT_LIBRARIES ${QT_LIBRARIES}
          ${WINSDK_LIBRARY_DIR}/Crypt32.lib
          ${WINSDK_LIBRARY_DIR}/WS2_32.Lib
          ${WINSDK_LIBRARY_DIR}/IPHlpApi.Lib)
      ENDIF()

      # Core
      SET(QT_LIBRARIES ${QT_LIBRARIES} Qt5::Core)

      # pcre is needed since Qt 5.5
      IF(UNIX)
        SET(PCRE_LIB "${QT_LIBRARY_DIR}/libqtpcre.a")
      ELSEIF(WIN32)
        SET(PCRE_LIB "${QT_LIBRARY_DIR}/qtpcre.lib")
      ENDIF()
      IF(EXISTS ${PCRE_LIB})
        SET(QT_LIBRARIES ${QT_LIBRARIES} ${PCRE_LIB})
      ENDIF()

      IF(APPLE)
        FIND_LIBRARY(PCRE_LIBRARY pcre16 pcre)

        FIND_LIBRARY(SECURITY_FRAMEWORK Security)

        SET(QT_LIBRARIES ${QT_LIBRARIES}
          ${PCRE_LIBRARY}
          ${FOUNDATION_FRAMEWORK}
          ${CARBON_FRAMEWORK}
          ${SECURITY_FRAMEWORK})
      ELSEIF(UNIX)
        SET(QT_LIBRARIES ${QT_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT} -ldl -lrt)
      ENDIF()
    ELSE()
      SET(QT_LIBRARIES Qt5::Widgets Qt5::Network Qt5::Xml Qt5::Gui Qt5::OpenGL Qt5::Core)
    ENDIF()
  ELSE()
    MESSAGE(WARNING "Unable to find Qt 5")
  ENDIF()
ENDIF()

IF(WITH_QT)
  SET(CMAKE_PREFIX_PATH ${CMAKE_PREFIX_PATH} ${QTDIR} $ENV{QTDIR})

  # Use Qt 4
  FIND_PACKAGE(Qt4 COMPONENTS QtCore QtGui QtXml QtOpenGL REQUIRED)
ENDIF()

IF(WITH_ASSIMP)
  FIND_PACKAGE(assimp REQUIRED)
ENDIF()

IF(WITH_NEL)
  IF(WITH_NEL_TESTS)
    FIND_PACKAGE(CppTest)
  ENDIF()

  IF(WITH_GUI)
    FIND_PACKAGE(Luabind REQUIRED)
    FIND_PACKAGE(CURL REQUIRED)

    IF((WIN32 OR CURL_LIBRARIES MATCHES "\\.a") AND WITH_STATIC_CURL)
      SET(CURL_STATIC ON)
    ELSE()
      SET(CURL_STATIC OFF)
    ENDIF()

    IF(CURL_STATIC)
      SET(CURL_DEFINITIONS -DCURL_STATICLIB)

      SET(CURL_INCLUDE_DIRS ${CURL_INCLUDE_DIRS} ${OPENSSL_INCLUDE_DIR})
      SET(CURL_LIBRARIES ${CURL_LIBRARIES} ${OPENSSL_LIBRARIES})

      IF(UNIX)
        # CURL depends on libidn
        FIND_LIBRARY(IDN_LIBRARY idn)
        IF(IDN_LIBRARY)
          SET(CURL_LIBRARIES ${CURL_LIBRARIES} ${IDN_LIBRARY})
        ENDIF()

        # CURL Macports version depends on libidn, libintl and libiconv too
        IF(APPLE)
          FIND_LIBRARY(INTL_LIBRARY intl)
          IF(INTL_LIBRARY)
            SET(CURL_LIBRARIES ${CURL_LIBRARIES} ${INTL_LIBRARY})
          ENDIF()
        ENDIF()
      ENDIF()
    ENDIF()
  ENDIF()

  INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/nel/include)
  ADD_SUBDIRECTORY(nel)
ENDIF()

IF(WITH_RYZOM)
  ADD_SUBDIRECTORY(ryzom)
ENDIF()

IF(WITH_NELNS)
  ADD_SUBDIRECTORY(nelns)
ENDIF()

IF(WITH_SNOWBALLS)
  ADD_SUBDIRECTORY(snowballs2)
ENDIF()

IF(WITH_TOOLS)
  ADD_SUBDIRECTORY(tool)
ENDIF()

IF(WITH_STUDIO)
  ADD_SUBDIRECTORY(studio)
ENDIF()

# To build the documention, you will have to enable it
# and then do the equivalent of "make DoxygenDoc".
IF(BUILD_DOCUMENTATION)
    IF(DOT)
        SET(HAVE_DOT YES)
    ELSE()
        SET(HAVE_DOT NO)
    ENDIF()
    # This processes our Doxyfile.in and substitutes paths to generate
    # a final Doxyfile
    CONFIGURE_FILE(${CMAKE_SOURCE_DIR}/doc/Doxyfile.cmake.in ${CMAKE_BINARY_DIR}/doc/Doxyfile)

    ADD_CUSTOM_TARGET(DoxygenDoc ${DOXYGEN} ${CMAKE_BINARY_DIR}/doc/Doxyfile)
ENDIF()

IF(WITH_NEL_TESTS)
  ENABLE_TESTING()
  ADD_TEST(nel_unit_test ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/nel_unit_test --html)
  IF(BUILD_DASHBOARD)
    INCLUDE(Dart)
    SET(SVNCOMMAND svn)
    SET(SVNSOURCEDIR http://dev.ryzom.com/svn/trunk/nel)
    SET(GENERATELOGS svn2cl)
  ENDIF()
ENDIF()

# packaging information
SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Ryzom Core MMORPG Framework")
SET(CPACK_PACKAGE_VENDOR "Ryzom Core")
SET(CPACK_PACKAGE_DESCRIPTION_FILE ${CMAKE_SOURCE_DIR}/README)
SET(CPACK_RESOURCE_FILE_LICENSE ${CMAKE_SOURCE_DIR}/COPYING)
SET(CPACK_PACKAGE_VERSION_MAJOR "${NL_VERSION_MAJOR}")
SET(CPACK_PACKAGE_VERSION_MINOR "${NL_VERSION_MINOR}")
SET(CPACK_PACKAGE_VERSION_PATCH "${NL_VERSION_PATCH}")
SET(CPACK_INSTALL_CMAKE_PROJECTS "${CMAKE_BINARY_DIR};NeL;ALL;/")
SET(CPACK_PACKAGE_EXECUTABLES "ryzomcore${NL_VERSION}" "ryzomcore")
SET(CPACK_SET_DESTDIR TRUE)

# NSIS Specific Packing Setup
SET(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "RyzomCore")
SET(CPACK_NSIS_MODIFY_PATH "ON")
SET(CPACK_NSIS_MUI_ICON ${CMAKE_SOURCE_DIR}/resources/nevraxpill.ico)
SET(CPACK_NSIS_MUI_UNIICON ${CMAKE_SOURCE_DIR}/resources/nevraxpill.ico)
SET(CPACK_PACKAGE_ICON ${CMAKE_SOURCE_DIR}/resources\\\\nel.bmp)
SET(CPACK_NSIS_DISPLAY_NAME "${CPACK_PACKAGE_INSTALL_DIRECTORY} RyzomCore")
SET(CPACK_NSIS_HELP_LINK "http:\\\\\\\\dev.ryzom.com")
SET(CPACK_NSIS_URL_INFO_ABOUT "http:\\\\\\\\dev.ryzom.com\\\\projects\\\\nel\\\\wiki")
SET(CPACK_NSIS_CONTACT "matt.raykowski@gmail.com")

## Source Packages
SET(CPACK_PACKAGE_FILE_NAME "ryzomcore-${NL_VERSION}")
SET(CPACK_SOURCE_PACKAGE_FILE_NAME "ryzomcore-${NL_VERSION}")
IF(WIN32)
  #SET(CPACK_GENERATOR "NSIS")
  SET(CPACK_GENERATOR "NSIS;ZIP")
  SET(CPACK_SOURCE_GENERATOR "ZIP")
ELSE()
  SET(CPACK_GENERATOR "TGZ")
  SET(CPACK_SOURCE_GENERATOR "TGZ")
ENDIF()
set(CPACK_SOURCE_IGNORE_FILES
	"~$"
	"\\\\.cvsignore$"
	"^${CMAKE_SOURCE_DIR}.*/CVS/"
	"^${CMAKE_SOURCE_DIR}.*/\\\\.svn/"
	"^${CMAKE_SOURCE_DIR}/debian/"
	"^${CMAKE_SOURCE_DIR}/old/")
IF(WIN32)
  IF(NOT CMAKE_BUILD_TYPE STREQUAL "Release")
    SET(CMAKE_INSTALL_DEBUG_LIBRARIES TRUE)
    IF(WITH_QT)
      INCLUDE(${QT_USE_FILE})
      INSTALL(FILES
        "${QT_LIBRARY_DIR}/../bin/QtGuid4.dll"
        "${QT_LIBRARY_DIR}/../bin/QtXmld4.dll"
        "${QT_LIBRARY_DIR}/../bin/QtCored4.dll"
        DESTINATION ${NL_BIN_PREFIX})
    ENDIF()
  ELSE()
    IF(WITH_QT)
      INCLUDE(${QT_USE_FILE})
      INSTALL(FILES
        "${QT_LIBRARY_DIR}/../bin/QtGui4.dll"
        "${QT_LIBRARY_DIR}/../bin/QtXml4.dll"
        "${QT_LIBRARY_DIR}/../bin/QtCore4.dll"
        DESTINATION ${NL_BIN_PREFIX})
    ENDIF()
  ENDIF()

  # Install CEGUI and its dependencies.
  IF(WITH_NEL_CEGUI)
    INSTALL(FILES "${CEGUI_LIB_DIR}/CEGUIBase.dll" DESTINATION ${NL_BIN_PREFIX})
    INSTALL(FILES "${CEGUI_LIB_DIR}/CEGUIDevilImageCodec.dll" DESTINATION ${NL_BIN_PREFIX})
    INSTALL(FILES "${CEGUI_LIB_DIR}/CEGUIExpatParser.dll" DESTINATION ${NL_BIN_PREFIX})
    INSTALL(FILES "${CEGUI_LIB_DIR}/CEGUIFalagardWRBase.dll" DESTINATION ${NL_BIN_PREFIX})
    INSTALL(FILES "${CEGUI_LIB_DIR}/Devil.dll" DESTINATION ${NL_BIN_PREFIX})
    INSTALL(FILES "${CEGUI_LIB_DIR}/ILU.dll" DESTINATION ${NL_BIN_PREFIX})
  ENDIF()

  # Only the tools require MFC.
  IF(WITH_TOOLS)
    SET(CMAKE_INSTALL_MFC_LIBRARIES TRUE)
  ENDIF()
  #INCLUDE(InstallRequiredSystemLibraries)
ENDIF()

INCLUDE(CPack)

INCLUDE(CMakePackaging.txt)

## Debian Packages
#INCLUDE(UseDebian)
#IF(DEBIAN_FOUND)
#  ADD_DEBIAN_TARGETS(nel)
#ENDIF()
