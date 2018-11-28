package tarsij.performance.springboot.controller;

import java.util.concurrent.ThreadLocalRandom;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.request.async.DeferredResult;
import tarsij.performance.springboot.service.AsyncService;

@RestController
public class AsyncController {

  private static final String DEFAULT_RESPONSE_DURATION = "500";
  private static final String DEFAULT_RESPONSE_DEVIATION = "0";

  private AsyncService<ResponseEntity<String>> asyncService;

  private long defaultResponseDuration;

  private long defaultResponseDeviation;

  public AsyncController(AsyncService<ResponseEntity<String>> asyncService,
      @Value("${service.response.duration:" + DEFAULT_RESPONSE_DURATION + "}") long defaultResponseDuration,
      @Value("${service.response.deviation:" + DEFAULT_RESPONSE_DEVIATION + "}") long defaultResponseDeviation) {
    if (defaultResponseDuration < 0) {
      throw new IllegalArgumentException("Duration should not be negative");
    }
    if (defaultResponseDeviation < 0) {
      throw new IllegalArgumentException("Deviation should not be negative");
    }

    this.asyncService = asyncService;
    this.defaultResponseDuration = defaultResponseDuration;
    this.defaultResponseDeviation = defaultResponseDeviation;
  }

  @GetMapping(path = "/synchello")
  public ResponseEntity<String> getSyncHello(
      @RequestParam(value = "duration", defaultValue = "-1") long duration,
      @RequestParam(value = "deviation", defaultValue = "-1") long deviation) {
    long min = getMinResponseTime(duration, deviation);
    long max = getMaxResponseTime(duration, deviation);

    if (max == 0) {
      return processRequest();
    }
    else {
      return asyncService.syncCall(
          ThreadLocalRandom.current().nextLong(min, max),
          this::processRequest
      );
    }
  }

  @GetMapping(path = "/asynchello")
  public DeferredResult<ResponseEntity<String>> getAsyncHello(
      @RequestParam(value = "duration", defaultValue = "-1") long duration,
      @RequestParam(value = "deviation", defaultValue = "-1") long deviation) {
    DeferredResult<ResponseEntity<String>> deferredResult = new DeferredResult<>();

    long min = getMinResponseTime(duration, deviation);
    long max = getMaxResponseTime(duration, deviation);

    if (max == 0) {
      deferredResult.setResult(processRequest());
    }
    else {
      asyncService.asyncCall(
          ThreadLocalRandom.current().nextLong(min, max),
          this::processRequest,
          deferredResult::setResult
      );
    }

    return deferredResult;
  }

  private ResponseEntity<String> processRequest() {
    return new ResponseEntity<>("Hello", HttpStatus.OK);
  }

  private long getMinResponseTime(long duration, long deviation) {
    if (duration < 0) {
      duration = defaultResponseDuration;
    }
    if (deviation < 0) {
      deviation = defaultResponseDeviation;
    }

    if (duration == 0) {
      return 0;
    }

    long min = duration - deviation;
    if (min <= 1) {
      return 1;
    }
    else {
      return min;
    }
  }

  private long getMaxResponseTime(long duration, long deviation) {
    if (duration < 0) {
      duration = defaultResponseDuration;
    }
    if (deviation < 0) {
      deviation = defaultResponseDeviation;
    }

    if (duration == 0) {
      return 0;
    }

    return duration + deviation + 1;
  }

}
