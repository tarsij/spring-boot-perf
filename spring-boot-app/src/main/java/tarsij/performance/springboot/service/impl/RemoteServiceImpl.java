package tarsij.performance.springboot.service.impl;

import tarsij.performance.springboot.service.RemoteService;
import java.util.Map.Entry;
import java.util.Queue;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.ConcurrentSkipListMap;
import java.util.function.Consumer;
import java.util.function.Supplier;
import org.springframework.stereotype.Service;

@Service
public class RemoteServiceImpl<T> implements RemoteService<T> {

  public static class QueueEntry<T> {
    private Supplier<T> supplier;
    private Consumer<T> consumer;

    public QueueEntry(Supplier<T> supplier, Consumer<T> consumer) {
      this.supplier = supplier;
      this.consumer = consumer;
    }

    public Supplier<T> getSupplier() {
      return supplier;
    }

    public Consumer<T> getConsumer() {
      return consumer;
    }
  }

  private ConcurrentSkipListMap<Long, Queue<QueueEntry<T>>> map = new ConcurrentSkipListMap<>();

  public RemoteServiceImpl() {

    new Thread(
        () -> {
          while (true) {
            if (!map.isEmpty()) {
              Entry<Long, Queue<QueueEntry<T>>> entry = map.firstEntry();
              if (entry.getKey() <= System.currentTimeMillis()) {
                entry = map.pollFirstEntry();
                Queue<QueueEntry<T>> queue = entry.getValue();

                for (QueueEntry<T> queueEntry : queue) {
                  queueEntry.getConsumer().accept(queueEntry.getSupplier().get());
                }
              }
            }
            else {
              try {
                Thread.sleep(1);
              } catch (InterruptedException ignored) { /* ignored */ }
            }
          }
        }).start();
  }

  @Override
  public T syncCall(long processLenght, Supplier<T> supplier) {
    try {
      Thread.sleep(processLenght);
    } catch (InterruptedException ignored) { /* ignored */ }
    return supplier.get();
  }

  @Override
  public void asyncCall(long processLenght, Supplier<T> supplier, Consumer<T> consumer) {
    if (processLenght <= 0) {
      throw new IllegalArgumentException("The process length should last longer than 0");
    }
    Queue<QueueEntry<T>> newQueue = new ConcurrentLinkedQueue<>();
    Queue<QueueEntry<T>> oldQueue = map.putIfAbsent(System.currentTimeMillis() + processLenght, newQueue);
    if (oldQueue != null) {
      newQueue = oldQueue;
    }
    newQueue.offer(new QueueEntry<>(supplier, consumer));
  }
}
