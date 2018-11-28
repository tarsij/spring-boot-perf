package tarsij.performance.springboot.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.ArrayList;
import java.util.List;
import org.junit.Test;
import org.springframework.http.ResponseEntity;
import org.springframework.web.context.request.async.DeferredResult;
import tarsij.performance.springboot.service.impl.AsyncServiceImpl;

public class AsyncControllerTest {

  private static final long DEFAULT_RESPONSE_DURATION = 500L;
  private static final long DEFAULT_RESPONSE_DEVIATION = 0L;

  private AsyncController asyncController = new AsyncController(
      new AsyncServiceImpl<>(),
      DEFAULT_RESPONSE_DURATION,
      DEFAULT_RESPONSE_DEVIATION);

  @Test
  public void asyncController_WHEN_many_concurrent_calls() {
    int callCount = 100000;
    List<DeferredResult<ResponseEntity<String>>> deferredResults = new ArrayList<>(callCount);
    int respCount = 0;

    long start = System.currentTimeMillis();

    for (int i = 0; i < callCount; i++) {
      deferredResults.add(asyncController.getAsyncHello(-1, -1));
    }

    long inited = System.currentTimeMillis();
    System.out.println("Inited: " + (inited - start));

    while (respCount < callCount) {
      if (deferredResults.get(respCount).hasResult()) {
        respCount++;
      } else {
        try {
          Thread.sleep(0, 1);
        } catch (InterruptedException ignored) { /*ignored*/ }
      }
    }

    long length = System.currentTimeMillis() - inited;
    System.out.println("Length: " + length);

    assertThat(length).isLessThan(DEFAULT_RESPONSE_DURATION + DEFAULT_RESPONSE_DEVIATION + 100);
  }

}
