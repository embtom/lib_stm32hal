project(lib_stm32hal)
include(halBuildSupport.cmake)

SET(STM32HAL_BASIC_SETTING cortex pwr rcc)

######################################################################################
# Build configurator
######################################################################################
if("${STM32CHIP_FAMILY}" STREQUAL "F1")
   SET(STM32HAL_DIR "STM32Cube_FW_F1_V1.23.0")
   SET(STM32HAL_DIR_SRC "${STM32HAL_DIR}/Drivers/STM32F1xx_HAL_Driver/Src")
   SET(STM32HAL_PREFIX stm32f1xx)
   SET(STM32HAL_PUBLIC_HEADERS "${STM32HAL_DIR}/Drivers/STM32F1xx_HAL_Driver/Inc" 
                               "${STM32HAL_DIR}/Drivers/CMSIS/Include" 
                               "${STM32HAL_DIR}/Drivers/CMSIS/Device/ST/STM32F1xx/Include")
   SET(STM32HAL_DIR_STARTUP    "${STM32HAL_DIR}/Drivers/CMSIS/Device/ST/STM32F1xx/Source/Templates/gcc")
   SET(STM32HAL_CONFIG_TEMPLATE "STM32Cube_Config/stm32f1xx_hal_conf.h_in")
   if(NOT STM32HAL_SYSTEM_FILE)
      SET(STM32HAL_SYSTEM_FILE "${STM32HAL_DIR}/Drivers/CMSIS/Device/ST/STM32F1xx/Source/Templates/system_stm32f1xx.c")
   endif()

elseif("${STM32CHIP_FAMILY}" STREQUAL "F4")
   SET(STM32HAL_DIR "STM32Cube_FW_F4_V1.23.0")
   SET(STM32HAL_DIR_SRC "${STM32HAL_DIR}/Drivers/STM32F4xx_HAL_Driver/Src")
   SET(STM32HAL_PREFIX stm32f4xx)
   SET(STM32HAL_PUBLIC_HEADERS "${STM32HAL_DIR}/Drivers/STM32F4xx_HAL_Driver/Inc" 
                               "${STM32HAL_DIR}/Drivers/CMSIS/Include" 
                               "${STM32HAL_DIR}/Drivers/CMSIS/Device/ST/STM32F4xx/Include")
   SET(STM32HAL_DIR_STARTUP    "${STM32HAL_DIR}/Drivers/CMSIS/Device/ST/STM32F4xx/Source/Templates/gcc")                              
   SET(STM32HAL_CONFIG_TEMPLATE "STM32Cube_Config/stm32f4xx_hal_conf.h_in")
   if(NOT STM32HAL_SYSTEM_FILE)
      SET(STM32HAL_SYSTEM_FILE "${STM32HAL_DIR}/Drivers/CMSIS/Device/ST/STM32F4xx/Source/Templates/system_stm32f4xx.c")
   endif()
else()
   message(FATAL_ERROR "No STM32 Family is selected")
endif()

SET(STM32HAL_VERSION STM32HAL_${STM32CHIP_FAMILY})

######################################################################################
# Evaluation of the adjusted configuration
######################################################################################

#Get list of available STM32 HAL components
STM32HAL_GET_AVAILABLE_COMPONENTS(${STM32HAL_DIR_SRC} ${STM32HAL_PREFIX} HAL_COMPONENTS HAL_EXT_COMPONENTS)

#Check if any comonents are preselected if not all are chosen
IF(NOT STM32HAL_USED_COMPONENTS)
     SET(STM32HAL_USED_COMPONENTS ${HAL_COMPONENTS})
     MESSAGE(STATUS "No STM32HAL components selected, using all: ${STM32HAL_USED_COMPONENTS}")
ENDIF()

#Creation of a combined list of selected compontent and the basic necessary ones
STM32HAL_ADD_BASIC_COMPONENTS("${STM32HAL_BASIC_SETTING}" "${STM32HAL_USED_COMPONENTS}" STM32HAL_USED_COMPONENTS)

#Creation of the HAL configuration file
STM32HAL_GENERATE_HAL_CONFIG_FILE("${STM32HAL_USED_COMPONENTS}" ${STM32HAL_PREFIX} ${STM32HAL_CONFIG_TEMPLATE})

#Creation of the header and source list depending of the configuration
STM32HAL_BUILDUP_SRC_AND_HEADER_LIST("${HAL_COMPONENTS}" "${HAL_EXT_COMPONENTS}" "${STM32HAL_USED_COMPONENTS}" 
                                      ${STM32HAL_PREFIX} STM32HAL_HEADERS_FILES STM32HAL_SRC_FILES)


STM32HAL_GET_AVAILABLE_STARTUP(${STM32HAL_DIR_STARTUP} TARGET_STARTUP_LIST)
string(TOLOWER ${STM32TARGET} stm32target)
LIST(FIND TARGET_STARTUP_LIST ${stm32target} TARGET_STARTUP_FOUND)
IF (${TARGET_STARTUP_FOUND} LESS 0)
   MESSAGE(FATAL_ERROR "For Target ${STM32TARGET} no startup code is available")
else()
   SET(STARTUP_FILE "startup_${stm32target}.s")
   STRING(MAKE_C_IDENTIFIER "${STARTUP_FILE}" HAL_STARTUP_FILE_CLEAN)
   SET(HAL_${HAL_STARTUP_FILE_CLEAN}_FILE HAL_STARTUP_FILE-NOTFOUND)
   FIND_FILE(HAL_${HAL_STARTUP_FILE_CLEAN}_FILE ${STARTUP_FILE} HINTS ${STM32HAL_DIR_STARTUP} CMAKE_FIND_ROOT_PATH_BOTH )
   SET(STM32_STARTUP_FILE ${HAL_${HAL_STARTUP_FILE_CLEAN}_FILE})

ENDIF()



message(STATUS "###### ${stm32target}")

FOREACH(HAL_SRC ${STM32HAL_SRC_FILES})
   STRING(MAKE_C_IDENTIFIER "${HAL_SRC}" HAL_SRC_CLEAN)
   SET(HAL_${HAL_SRC_CLEAN}_FILE HAL_SRC_FILE-NOTFOUND)
   FIND_FILE(HAL_${HAL_SRC_CLEAN}_FILE ${HAL_SRC} PATH_SUFFIXES src HINTS ${STM32HAL_DIR_SRC} CMAKE_FIND_ROOT_PATH_BOTH )
   LIST(APPEND STM32HAL_SOURCES ${HAL_${HAL_SRC_CLEAN}_FILE})
ENDFOREACH()

#message (STATUS "############${STM32HAL_SOURCES}")

######################################################
#Build target settings
######################################################

ENABLE_LANGUAGE(ASM)

#set(STARTUP_SRC STM32Cube_FW_F4_V1.23.0/Drivers/CMSIS/Device/ST/STM32F4xx/Source/Templates/gcc//startup_stm32f401xe.s)
add_library(${PROJECT_NAME} STATIC ${STM32HAL_SOURCES} ${STM32_STARTUP_FILE} ${STM32HAL_SYSTEM_FILE})
target_include_directories(${PROJECT_NAME} PUBLIC ${STM32HAL_PUBLIC_HEADERS} ${PROJECT_BINARY_DIR} )
target_compile_options(${PROJECT_NAME} PUBLIC -D${STM32HAL_VERSION} -D${STM32TARGET})
target_compile_options(${PROJECT_NAME} PRIVATE -O2) # only internal

UNSET(STM32CHIP_FAMILY CACHE)
UNSET(STM32HAL_SYSTEM_FILE CACHE)