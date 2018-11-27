package tarsij.performance.springboot.service.impl;

import java.util.Map.Entry;
import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.ConcurrentSkipListMap;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.Consumer;
import java.util.function.Supplier;
import org.springframework.stereotype.Service;
import tarsij.performance.springboot.service.AsyncService;

@Service
public class AsyncServiceImpl<T> implements AsyncService<T> {

  private AtomicBoolean stop = new AtomicBoolean(false);
  private ConcurrentSkipListMap<Long, Queue<QueueEntry<T>>> map = new ConcurrentSkipListMap<>();

  public AsyncServiceImpl() {
    new Thread(
        () -> {
          while (!stop.get()) {
            if (!map.isEmpty()) {
              Entry<Long, Queue<QueueEntry<T>>> entry = map.firstEntry();
              if (entry.getKey() <= System.currentTimeMillis()) {
                entry = map.pollFirstEntry();
                Queue<QueueEntry<T>> queue = entry.getValue();

                for (QueueEntry<T> queueEntry : queue) {
                  queueEntry.getResponseProcessor().accept(queueEntry.getResponseGenerator().get());
                }
              }
            } else {
              try {
                Thread.sleep(0, 1);
              } catch (InterruptedException ignored) { /* ignored */ }
            }
          }
        }).start();
  }

  @Override
  public T syncCall(long callDuration, Supplier<T> responseGenerator) {
    try {
      Thread.sleep(callDuration);
    } catch (InterruptedException ignored) { /* ignored */ }
    return responseGenerator.get();
  }

  @Override
  public void asyncCall(long callDuration, Supplier<T> responseGenerator,
      Consumer<T> responseProcessor) {
    if (callDuration <= 0) {
      throw new IllegalArgumentException("The call duration should be grater than 0");
    }
    Queue<QueueEntry<T>> newQueue = new ConcurrentLinkedQueue<>();
    Queue<QueueEntry<T>> oldQueue = map
        .putIfAbsent(System.currentTimeMillis() + callDuration, newQueue);
    if (oldQueue != null) {
      newQueue = oldQueue;
    }
    newQueue.offer(new QueueEntry<>(responseGenerator, responseProcessor));
  }

  private static class QueueEntry<T> {

    private Supplier<T> responseGenerator;
    private Consumer<T> responseProcessor;

    QueueEntry(Supplier<T> responseGenerator, Consumer<T> responseProcessor) {
      this.responseGenerator = responseGenerator;
      this.responseProcessor = responseProcessor;
    }

    Supplier<T> getResponseGenerator() {
      return responseGenerator;
    }

    Consumer<T> getResponseProcessor() {
      return responseProcessor;
    }
  }
}
