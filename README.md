# Comparing the performance of synchronous and asynchronous request processing in Spring Boot

The goal is to compare how does a controller perform if it is spending most of its time
waiting for an answer for a blocking call which could have been served asynchronously as well.

Build the app:  
  - build the app without docker images:
    ```
    mvn clean install
    ``` 
  - build the app and create docker image and deployment yamls for the service:
    ```
    mvn clean install -P kubernetes
    ```

Run the service:  
  - with maven:
    ```
    mvn spring-boot:run -pl spring-boot-app
    ```
  - with docker:
    ```
    docker
    ```
  - with minikube:
    ```
    kube
    ```

Run the gatling tests:  

  - with maven
    - shows a list of available tests and you can choose which one to run:
      ``` 
      mvn scala:run -DmainClass=Engine -pl gatling-tests
      ```
    - executes a given test:
      ```
      mvn gatling:test -Dgatling.simulationClass=simulations.AsyncRestFixedUser -pl gatling-tests
      ```
  - with docker
    - shows a list of available tests and you can choose which one to run:
      ```
      docker run -it --rm -v $PWD/src/test/resources:/opt/gatling/conf -v $PWD/src/test:/opt/gatling/user-files -v $PWD/reports:/opt/gatling/results denvazh/gatling
      ```
    - executes a given test:
      ```
      docker run -it --rm -v $PWD/src/test/resources:/opt/gatling/conf -v $PWD/src/test:/opt/gatling/user-files -v $PWD/reports:/opt/gatling/results denvazh/gatling -s simulations.AsyncRestFixedUser
      ```


For the results please visit the following [page](https://tarsij.github.io/spring-boot-perf/)

TODO:
  - ~~pass in the number of threads to be used for the service~~
  - ~~make configurable the simulations (no. of users, test duration, ...)~~
  - ~~create a script to run the tests with different configurations and store the results~~
  - ~~create a script to generate charts (throughput / thread-count, response-time / thread-count)~~
  - experiment with Callable return type with synchronous calls
  - experiment with Fibre light threads with synchronous calls
  - experiment with Spring Boot 2 reactive stack
  - investigate "j.i.IOException: Premature close" exceptions
  - make the test runnable in AWS (free tier)
  - add tracing => kafka consumer
  - add a metric collector (cheat and publish it as a trace data?)
  
