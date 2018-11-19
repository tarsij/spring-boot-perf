package tarsij.performance.springboot.service.impl;

import tarsij.performance.springboot.service.RemoteService;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;
import java.util.function.Supplier;

public class ScheduledRemoteServiceImpl<T> implements RemoteService<T> {

  public static class Task<T> implements Runnable {
    private Supplier<T> supplier;
    private Consumer<T> consumer;

    public Task(Supplier<T> supplier, Consumer<T> consumer) {
      this.supplier = supplier;
      this.consumer = consumer;
    }

    @Override
    public void run() {
      consumer.accept(supplier.get());
    }
  }

  private ScheduledExecutorService ses;

  public ScheduledRemoteServiceImpl() {
    ses = new ScheduledThreadPoolExecutor(1);
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
    ses.schedule(new Task<T>(supplier, consumer), processLenght, TimeUnit.MILLISECONDS);
  }

}
