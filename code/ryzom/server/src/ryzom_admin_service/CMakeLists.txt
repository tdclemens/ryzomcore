FILE(GLOB SRC *.cpp *.h)

ADD_EXECUTABLE(ryzom_admin_service WIN32 ${SRC})

INCLUDE_DIRECTORIES(${RZ_SERVER_SRC_DIR} ${MYSQL_INCLUDE_DIR})

TARGET_LINK_LIBRARIES(ryzom_admin_service
						ryzom_adminmodules
						nelmisc
						nelnet)

NL_DEFAULT_PROPS(ryzom_admin_service "Ryzom, Services: Ryzom Admin Service (AS)")
NL_ADD_RUNTIME_FLAGS(ryzom_admin_service)

INSTALL(TARGETS ryzom_admin_service RUNTIME DESTINATION sbin COMPONENT services)


