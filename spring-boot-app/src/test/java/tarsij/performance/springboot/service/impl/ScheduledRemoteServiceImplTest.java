package tarsij.performance.springboot.service.impl;

import static org.assertj.core.api.Assertions.assertThat;

import tarsij.performance.springboot.service.RemoteService;
import java.util.concurrent.atomic.AtomicLong;
import org.junit.Test;

public class ScheduledRemoteServiceImplTest {

  private static final long RESPONSE_TIME = 500L;

  @Test
  public void scheduledRemoteService_WHEN_many_concurrent_calls() {
    RemoteService<Object> remoteService = new ScheduledRemoteServiceImpl<>();
    long callCount = 100000;
    AtomicLong respCount = new AtomicLong();

    long start = System.currentTimeMillis();

    for (int i = 0; i < callCount; i++) {
      remoteService.asyncCall(
          RESPONSE_TIME,
          () -> null,
          o -> {
            respCount.incrementAndGet();
          });
    }

    long inited = System.currentTimeMillis();
    System.out.println("Inited: " + (inited - start));

    while (respCount.get() < callCount) {
      try {
        Thread.sleep(0,1);
      } catch (InterruptedException ignored) { /*ignored*/ }
    }

    long length = System.currentTimeMillis() - inited;
    System.out.println("Length: " + length);

    assertThat(length).isLessThan(RESPONSE_TIME + 100);
  }
}
