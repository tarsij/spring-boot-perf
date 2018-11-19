package tarsij.performance.springboot.controller;

import tarsij.performance.springboot.service.RemoteService;
import java.util.concurrent.ThreadLocalRandom;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.request.async.DeferredResult;

@RestController
public class AsyncController {

  private static final String MIN_RESPONSE_TIME = "500";
  private static final String MAX_RESPONSE_TIME = "501";

  private RemoteService<ResponseEntity<String>> remoteService;

  public AsyncController(RemoteService<ResponseEntity<String>> remoteService) {
    this.remoteService = remoteService;
  }

  @GetMapping(path = "/synchello")
  public ResponseEntity<String> getSyncHello(
      @RequestParam(value = "min", defaultValue = MIN_RESPONSE_TIME) Long min,
      @RequestParam(value = "max", defaultValue = MAX_RESPONSE_TIME) Long max) {
    return remoteService.syncCall(
        ThreadLocalRandom.current().nextLong(min, max),
        () -> new ResponseEntity<>("Hello", HttpStatus.OK)
    );
  }

  @GetMapping(path = "/asynchello")
  public DeferredResult<ResponseEntity<String>> getAsyncHello(
      @RequestParam(value = "min", defaultValue = MIN_RESPONSE_TIME) Long min,
      @RequestParam(value = "max", defaultValue = MAX_RESPONSE_TIME) Long max) {
    DeferredResult<ResponseEntity<String>> deferredResult = new DeferredResult<>();

    remoteService.asyncCall(
        ThreadLocalRandom.current().nextLong(min, max),
        () -> new ResponseEntity<>("Hello", HttpStatus.OK),
        deferredResult::setResult
      );

    return deferredResult;
  }

}
