cmake_minimum_required(VERSION 3.5)
project(sample_project)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

set(SOURCES
    "main.cpp"
)
add_executable(sample_project ${SOURCES})

set_target_properties(sample_project PROPERTIES OUTPUT_NAME "app_sample")
install(TARGETS sample_project RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
