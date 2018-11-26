package tarsij.performance.springboot.service;

import java.util.function.Consumer;
import java.util.function.Supplier;

public interface AsyncService<T> {

  T syncCall(long callDuration, Supplier<T> responseGenerator);

  void asyncCall(long callDuration, Supplier<T> responseGenerator, Consumer<T> responseProcessor);

}
