package tarsij.performance.springboot.service;

import java.util.function.Consumer;
import java.util.function.Supplier;

public interface RemoteService<T> {

  T syncCall(long processLenght, Supplier<T> supplier);

  void asyncCall(long processLenght, Supplier<T> supplier, Consumer<T> consumer);

}
