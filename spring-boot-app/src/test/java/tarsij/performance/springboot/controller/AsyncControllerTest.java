package tarsij.performance.springboot.controller;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.ArrayList;
import java.util.List;
import org.junit.Test;
import org.springframework.http.ResponseEntity;
import org.springframework.web.context.request.async.DeferredResult;
import tarsij.performance.springboot.service.impl.AsyncServiceImpl;

public class AsyncControllerTest {

  private static final long MIN_RESPONSE_TIME = 500L;
  private static final long MAX_RESPONSE_TIME = 501L;

  private AsyncController asyncController = new AsyncController(new AsyncServiceImpl<>());

  @Test
  public void asyncController_WHEN_many_concurrent_calls() {
    int callCount = 100000;
    List<DeferredResult<ResponseEntity<String>>> deferredResults = new ArrayList<>(callCount);
    int respCount = 0;

    long start = System.currentTimeMillis();

    for (int i = 0; i < callCount; i++) {
      deferredResults.add(asyncController.getAsyncHello(MIN_RESPONSE_TIME, MAX_RESPONSE_TIME));
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

    assertThat(length).isLessThan(MAX_RESPONSE_TIME + 100);
  }

}
