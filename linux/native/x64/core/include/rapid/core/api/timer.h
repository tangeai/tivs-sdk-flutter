#ifndef _RAPID_CORE_API_TIMER_H_
#define _RAPID_CORE_API_TIMER_H_

#ifdef __cplusplus
extern "C" {
#endif

// C API functions (reserved for future use)

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
#include <chrono>
#include <string>

#include "rapid/core/api/glue.h"

class RAPID_Core_FunctionTimer {
 private:
  std::chrono::steady_clock::time_point start_time_;
  const char* tag_;
  std::string function_name_;
  std::string extra_message_;

 public:
  RAPID_Core_FunctionTimer(const char* tag,
                           const std::string& function_name,
                           const std::string& extra_message = "")
      : start_time_(std::chrono::steady_clock::now()),
        tag_(tag),
        function_name_(function_name),
        extra_message_(extra_message) {}

  ~RAPID_Core_FunctionTimer() {
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(
                        std::chrono::steady_clock::now() - start_time_)
                        .count();
    if (extra_message_.empty()) {
      RAPID_LOGI(tag_, "[%s] execution time: %lld ms", function_name_.c_str(), duration);
      return;
    }

    RAPID_LOGI(tag_,
               "[%s][%s] execution time: %lld ms",
               function_name_.c_str(),
               extra_message_.c_str(),
               duration);
  }
};

#endif  // __cplusplus

#endif  // _RAPID_CORE_API_TIMER_H_
