#ifndef _RAPID_CORE_BLOCKING_QUEUE_H_
#define _RAPID_CORE_BLOCKING_QUEUE_H_

#ifdef __cplusplus

#include <chrono>
#include <condition_variable>
#include <deque>
#include <iterator>
#include <mutex>
#include <utility>
#include <vector>

namespace rapid {
namespace core {

template <typename T>
class BlockingQueue {
 public:
  void enqueue_front(T item);
  void enqueue(T item);
  bool try_enqueue(T item, size_t max_size);
  bool dequeue(T &item, int timeout_ms = 0);
  void shutdown();
  void start();
  bool is_shutdown() const;
  void clear();
  size_t size() const;
  bool is_empty() const;
  std::vector<T> as_list() const;
  std::vector<T> drain();
  template <typename Predicate>
  std::vector<T> extract_if(Predicate predicate);
  template <typename Predicate>
  std::vector<T> extract_before_last(Predicate predicate);
  bool peek(T &item) const;

 private:
  mutable std::mutex mutex_;
  std::deque<T> queue_;
  std::condition_variable cond_var_;
  bool shutdown_ = false;
};

template <typename T>
void BlockingQueue<T>::enqueue_front(T item) {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (shutdown_) {
      return;
    }
    queue_.emplace_front(std::move(item));
  }
  cond_var_.notify_one();
}

template <typename T>
void BlockingQueue<T>::enqueue(T item) {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (shutdown_) {
      return;
    }
    queue_.emplace_back(std::move(item));
  }
  cond_var_.notify_one();
}

template <typename T>
bool BlockingQueue<T>::try_enqueue(T item, size_t max_size) {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    if (shutdown_ || max_size == 0 || queue_.size() >= max_size) {
      return false;
    }
    queue_.emplace_back(std::move(item));
  }
  cond_var_.notify_one();
  return true;
}

template <typename T>
bool BlockingQueue<T>::dequeue(T &item, int timeout_ms) {
  std::unique_lock<std::mutex> lock(mutex_);
  if (shutdown_) {
    return false;
  }
  if (timeout_ms > 0) {
    if (!cond_var_.wait_for(lock, std::chrono::milliseconds(timeout_ms), [this] {
          return !queue_.empty() || shutdown_;
        })) {
      return false;
    }
  } else {
    while (queue_.empty() && !shutdown_) {
      cond_var_.wait(lock);
    }
  }
  if (shutdown_ || queue_.empty()) {
    return false;
  }
  item = std::move(queue_.front());
  queue_.pop_front();
  return true;
}

template <typename T>
void BlockingQueue<T>::shutdown() {
  {
    std::lock_guard<std::mutex> lock(mutex_);
    shutdown_ = true;
  }
  cond_var_.notify_all();
}

template <typename T>
void BlockingQueue<T>::start() {
  std::lock_guard<std::mutex> lock(mutex_);
  shutdown_ = false;
}

template <typename T>
bool BlockingQueue<T>::is_shutdown() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return shutdown_;
}

template <typename T>
void BlockingQueue<T>::clear() {
  std::unique_lock<std::mutex> lock(mutex_);
  queue_.clear();
}

template <typename T>
size_t BlockingQueue<T>::size() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return queue_.size();
}

template <typename T>
bool BlockingQueue<T>::is_empty() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return queue_.empty();
}

template <typename T>
std::vector<T> BlockingQueue<T>::as_list() const {
  std::lock_guard<std::mutex> lock(mutex_);
  return std::vector<T>(queue_.begin(), queue_.end());
}

template <typename T>
std::vector<T> BlockingQueue<T>::drain() {
  std::lock_guard<std::mutex> lock(mutex_);
  std::vector<T> drained;
  drained.reserve(queue_.size());
  while (!queue_.empty()) {
    drained.emplace_back(std::move(queue_.front()));
    queue_.pop_front();
  }
  return drained;
}

template <typename T>
template <typename Predicate>
std::vector<T> BlockingQueue<T>::extract_if(Predicate predicate) {
  std::lock_guard<std::mutex> lock(mutex_);
  std::vector<T> extracted;
  for (auto it = queue_.begin(); it != queue_.end();) {
    if (predicate(*it)) {
      extracted.emplace_back(std::move(*it));
      it = queue_.erase(it);
    } else {
      ++it;
    }
  }
  return extracted;
}

template <typename T>
template <typename Predicate>
std::vector<T> BlockingQueue<T>::extract_before_last(Predicate predicate) {
  std::lock_guard<std::mutex> lock(mutex_);
  auto last_match = queue_.end();
  for (auto it = queue_.begin(); it != queue_.end(); ++it) {
    if (predicate(*it)) {
      last_match = it;
    }
  }
  if (last_match == queue_.end() || last_match == queue_.begin()) {
    return {};
  }

  std::vector<T> extracted;
  extracted.reserve(static_cast<size_t>(std::distance(queue_.begin(), last_match)));
  for (auto it = queue_.begin(); it != last_match; ++it) {
    extracted.emplace_back(std::move(*it));
  }
  queue_.erase(queue_.begin(), last_match);
  return extracted;
}

template <typename T>
bool BlockingQueue<T>::peek(T &item) const {
  std::lock_guard<std::mutex> lock(mutex_);
  if (shutdown_ || queue_.empty()) {
    return false;
  }
  item = queue_.front();
  return true;
}

}  // namespace core
}  // namespace rapid

#endif  // __cplusplus

#endif  //_RAPID_CORE_BLOCKING_QUEUE_H_
