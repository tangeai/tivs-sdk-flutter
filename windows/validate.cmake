function(rapid_windows_sdk_validate ROOT RESULT MISSING)
  set(REQUIRED_FILES
    core/include/rapid/core/api/initialize.h
    media/include/rapid/media/api/player.h
    sdl/include/rapid/sdl/api/sdl_vout.h
    lib/libRapidCore.dll
    lib/libRapidCore.dll.a
    lib/libRapidMedia.dll
    lib/libRapidMedia.dll.a
    lib/libRapidSDL.dll
    lib/libRapidSDL.dll.a
    lib/PPCS_API.dll
    lib/webrtc.dll
    lib/libxlog.dll
    lib/avcodec-60.dll
    lib/avformat-60.dll
    lib/avutil-58.dll
    lib/swresample-4.dll
    lib/swscale-7.dll
    lib/glfw3.dll
    lib/libEGL.dll
    lib/libGLESv2.dll
  )

  set(MISSING_FILES "")
  foreach(REQUIRED_FILE IN LISTS REQUIRED_FILES)
    if(NOT EXISTS "${ROOT}/${REQUIRED_FILE}")
      list(APPEND MISSING_FILES "${REQUIRED_FILE}")
    endif()
  endforeach()

  if(MISSING_FILES)
    set(${RESULT} FALSE PARENT_SCOPE)
  else()
    set(${RESULT} TRUE PARENT_SCOPE)
  endif()
  set(${MISSING} "${MISSING_FILES}" PARENT_SCOPE)
endfunction()
