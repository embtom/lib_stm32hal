######################################################################################
# Support functions
######################################################################################

######################################################################################
# \brief Get of available software components form the HAL framework
#
# \param _InHalSrcDir [IN]      : Source path of the HAL framework
# \param _InStm32Prefix [IN]    : STM32 HAL file prefix
# \param _OutHalComp [OUT]      : List of provided hal components
# \param _OutHalCompEx [OUT]    : List of provided extenstions form the hal components
#
######################################################################################
FUNCTION (STM32HAL_GET_AVAILABLE_COMPONENTS _InHalSrcDir _InStm32Prefix _OutHalComp _OutHalCompExt) 
   SET(INT_HAL_COMPONENTS "")
   SET(INT_HAL_EXT_COMPONENTS "")
   FILE(GLOB srclist "${_InHalSrcDir}/*.c")
   FOREACH (cmp ${srclist})
      get_filename_component(cmp ${cmp} NAME)

      if("${cmp}" MATCHES "${_InStm32Prefix}_hal_([a-z0-9]*)\\.c")
         LIST(APPEND INT_HAL_COMPONENTS ${CMAKE_MATCH_1})
      endif()

      if("${cmp}" MATCHES "${_InStm32Prefix}_hal_([a-z0-9]*)_ex\\.c")
         LIST(APPEND INT_HAL_EXT_COMPONENTS ${CMAKE_MATCH_1})
      endif()
   ENDFOREACH()  
   SET(${_OutHalComp} ${INT_HAL_COMPONENTS} PARENT_SCOPE)
   SET(${_OutHalCompExt} ${INT_HAL_EXT_COMPONENTS} PARENT_SCOPE)
ENDFUNCTION()

######################################################################################
# \brief For HAL framework operation some basic components are required and 
#        these will be added if not actived
#
# \param _InBasicComp [IN]   : List of basic components needed for operation
# \param _InUsedComp [IN]    : List of components which are used 
# \param _OutUsedComp [OUT]  : Combined list of basic components and the selected onces
#
######################################################################################
FUNCTION(STM32HAL_ADD_BASIC_COMPONENTS _InBasicComp _InUsedComp _OutUsedComp)
   SET(INT_USED_COMPONENTS ${_InUsedComp})
   FOREACH(cmp ${_InBasicComp})
      LIST(FIND _InUsedComp ${cmp} STM32HAL_FOUND_INDEX)
      IF(${STM32HAL_FOUND_INDEX} LESS 0)
         LIST(APPEND INT_USED_COMPONENTS ${cmp})
      ENDIF()
   ENDFOREACH()
   LIST(REMOVE_DUPLICATES INT_USED_COMPONENTS)
   SET(${_OutUsedComp} ${INT_USED_COMPONENTS} PARENT_SCOPE)
ENDFUNCTION()

######################################################################################
# \brief Generation of the HAL config file depending of the activated components
#
# \param _InUsedComp [IN]           : List of basic components needed for operation
# \param _InStm32Prefix [IN]        : STM32 HAL file prefix
# \param _InConfigTemplate [OUT]    : Basic config template
#
######################################################################################
FUNCTION(STM32HAL_GENERATE_HAL_CONFIG_FILE _InUsedComp _InStm32Prefix _InConfigTemplate)
   FOREACH(cmp ${_InUsedComp})
      string(TOUPPER ${cmp} CMP)
      string(APPEND GEN_STM32_MODULE_ENABLE "#define HAL_${CMP}_MODULE_ENABLED\\")
   ENDFOREACH()
   string (REPLACE "\\" "\n" GEN_STM32_MODULE_ENABLE "${GEN_STM32_MODULE_ENABLE}")
   configure_file(${_InConfigTemplate} ${PROJECT_BINARY_DIR}/${_InStm32Prefix}_hal_conf.h)
ENDFUNCTION()

######################################################################################
# \brief Build up list of source and header files used at thes HAL framework configuration
#
# \param _InHalComp [IN]           : List of provided hal components
# \param _InHalCompExt [IN]        : List of provided extenstions form the hal components
# \param _InUsedComp [IN]          : List of components which are used
# \param _InStm32Prefix [IN]       : STM32 HAL file prefix
# \param _OutHeaderList [OUT]      : Generated header list represents current configuration
# \param _OutSrcList [OUT]         : Generated source list represents current configuration
######################################################################################
FUNCTION(STM32HAL_BUILDUP_SRC_AND_HEADER_LIST _InHalComp _InHalCompExt _InUsedComp _InStm32Prefix _OutHeaderList _OutSrcList)
   SET(IN_SRC_FILES 	   ${_InStm32Prefix}_hal.c)
   SET(IN_HEADER_FILES  "")
   FOREACH(cmp ${_InUsedComp})
      LIST(FIND _InHalComp ${cmp} STM32HAL_FOUND_INDEX)
      IF(${STM32HAL_FOUND_INDEX} LESS 0)
         MESSAGE(FATAL_ERROR "Unknown STM32HAL component: ${cmp}. Available components: ${_InUsedComp}")
	   ELSE()
         LIST(APPEND IN_HEADER_FILES ${_InStm32Prefix}_hal_${cmp}.h)
         LIST(APPEND IN_SRC_FILES ${_InStm32Prefix}_hal_${cmp}.c)
      ENDIF()
    
      LIST(FIND _InHalCompExt ${cmp} STM32HAL_FOUND_INDEX)
      IF(NOT (${STM32HAL_FOUND_INDEX} LESS 0))
         LIST(APPEND IN_HEADER_FILES ${_InStm32Prefix}_hal_${cmp}_ex.h)
         LIST(APPEND IN_SRC_FILES ${_InStm32Prefix}_hal_${cmp}_ex.c)
      ENDIF()
   ENDFOREACH()
   LIST(REMOVE_DUPLICATES IN_HEADER_FILES)
   LIST(REMOVE_DUPLICATES IN_SRC_FILES)

   SET(${_OutHeaderList} ${IN_HEADER_FILES} PARENT_SCOPE)
   SET(${_OutSrcList} ${IN_SRC_FILES} PARENT_SCOPE)
ENDFUNCTION()

######################################################################################
# \brief Get available target specific startup files form the HAL framework
#
# \param _InStartUpDir [IN]      : Source path of the startup files provided by the HAL framework
# \param _OutStartupList [OUT]   : List of provided startup files
######################################################################################
FUNCTION (STM32HAL_GET_AVAILABLE_STARTUP _InStartUpDir _OutStartupList) 
   SET(INT_STARTUP_LIST "")
   FILE(GLOB startuplist "${_InStartUpDir}/*.s")

   FOREACH (cmp ${startuplist})
      get_filename_component(cmp ${cmp} NAME)

      if("${cmp}" MATCHES "startup_([a-z0-9]*)\\.s")
         LIST(APPEND INT_STARTUP_LIST ${CMAKE_MATCH_1})
      endif()
   ENDFOREACH()  
   SET(${_OutStartupList} ${INT_STARTUP_LIST} PARENT_SCOPE)
ENDFUNCTION()

