# Gatling performance testing

## Gatling and IntelliJ

Setting up a project in IntelliJ:  

  - Create a new Project
  - Select 'Maven' as the project type
  - Select 'Create from archetype'
  - Select 'Add Archetype'
  - Use the following maven dependency information (use the latest version)
    ```
    groupId:     io.gatling.highcharts
    artifactId:  gatling-highcharts-maven-archetype
    version:     3.0.1
    ```
  - Specify the artifact details
  - Specify the maven settings
  - Specify the project details
  
Run:
  - with IntelliJ showing the test selector menu:
    ```
    right click on the Engine.scala and select run
    ```

New simulation files should be added to the ```src/test/scala``` folder.


## Gatling and maven
  
The project comes with two plugins in place: the ```scala-maven-plugin``` and the ```gatling-maven-plugin```.
Both plugins have their pros and cons.

To omit double compilation we have to disable the compiler for the ```gatling-maven-plugin```:  
  ```
  <plugin>
    <groupId>io.gatling</groupId>
    <artifactId>gatling-maven-plugin</artifactId>
    <configuration>
      <disableCompiler>true</disableCompiler>
    </configuration>
  </plugin>
  ```

### Gatling with the scala-maven-plugin

Check at http://davidb.github.io/scala-maven-plugin/run-mojo.html

Run:
  - with main class showing the test selector menu:  
    ```
    mvn scala:run -DmainClass=<MainClass>
    ```
  - with launchers showing the test selector menu:  
    ```
    mvn scala:run -Dlauncher=<LauncherId>
    ```
  - with launchers, executing the first and showing the test selector menu:  
    ```
    mvn scala:run
    ```
  - with the workaround for the system properties executing a given test
    ```
    <any of the commands above> -Dgatling.simulationClass=<package.SimulationClass>
    ```

Pros:
  - Runs as a plain scala application
  - Can show a list of available simulations from which the user can select which one to run
  - with the launchers it is possible to configure multiple configurations
  - with the launchers it is not necessary to specify the main class. If no launcher is selected
    then the first one is executed
  - with the workaround used for the system properties it is possible to pass in the simulation
    class name
  
Cons:
  - The maven properties/command line parameters are not passed through the system properties
    A workaround for this issue is to use the properties-maven-plugin to generate a properties
    file containing the maven properties, then loading the properties in the Engine/IDEPathHelper
    classes and adding those values to the System properties. The possible command line arguments
    have to be added to the properties in order to be saved in the file.
  - Cannot run all the tests in one run
  - less configurable

### Gatling with the gatling-maven-plugin

Check at https://gatling.io/docs/3.0/extensions/maven_plugin/

Run:
  - executing a given test:
    ```
    mvn gatling:test -Dgatling.simulationClass=<package.SimulationClass>
    ```
  - executing all the tests (the ```runMultipleSimulations``` configuration has to be true):
    ```
    mvn gatling:test
    ```

Pros:
  - The system properties are propagated by default so no workaround is needed
  - It can execute a single test without any workaround
  - It can execute all the tests in a single command (the ```runMultipleSimulations``` configuration has to be true)
  - more configurable
  
Cons:
  - Doesn't have the simulation selector menu option. Either run one predefined test or all the tests
    
## Gatling and Docker

Configure the gatling.conf file to reflect the maven structure:
  ```
  gatling {
    ...
    core {
      ...
      directory {
        ...
        simulations = user-files/scala
        resources = user-files/resources
  ```
  
Run the tests with docker:
  - showing the test selector menu:
    ```
    docker run --rm -v $PWD/src/test/resources:/opt/gatling/conf -v $PWD/src/test:/opt/gatling/user-files -v $PWD/reports:/opt/gatling/results denvazh/gatling
    ```
  - executing a given test:
    ```
    docker run --rm -v $PWD/src/test/resources:/opt/gatling/conf -v $PWD/src/test:/opt/gatling/user-files -v $PWD/reports:/opt/gatling/results denvazh/gatling -s <package-and-simulation-class>
    ```
    
### Scaling

  - launch the gatling instances with the -nr (no reports) option:
    ```
    docker run --rm -v $PWD/src/test/resources:/opt/gatling/conf -v $PWD/src/test:/opt/gatling/user-files -v $PWD/reports:/opt/gatling/results denvazh/gatling -s <package-and-simulation-class> -nr
    ```
  - collect the generated simulation.log files (rename them so they won’t clash)
  - place them into a <simulation-folder-with-the-collected-logs> within the results folder of a Gatling instance
  - generate the reports with the -ro (reports only) option (gatling will consume all the log files within the given folder):
    ```
    docker run --rm -v $PWD/src/test/resources:/opt/gatling/conf -v $PWD/src/test:/opt/gatling/user-files -v $PWD/reports:/opt/gatling/results denvazh/gatling -ro /opt/gatling/results/<simulation-folder-with-the-collected-logs>
    ```

