#Gatling performance testing

##Gatling and IntelliJ

Setting up the project:  

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
  
In the generated ```pom.xml``` the compiler for the gatling-maven-plugin has to be disabled if the
scala-maven-plugin is present too:  
  ```
  <plugin>  
    <groupId>io.gatling</groupId>
    <artifactId>gatling-maven-plugin</artifactId>
    <configuration>
      <disableCompiler>true</disableCompiler>
    </configuration>
  </plugin>
  ```

New simulation files should be added to the ```src/test/scala``` folder.

Run the tests:
  - with IntelliJ showing the test selector menu:
    ```
    right click on the Engine.scala and select run
    ```
  - with maven scala plugin showing the test selector menu:
    ```
    mvn scala:run -DmainClass=Engine
    ```
  - with maven gatling plugin executing a given test:
    ```
    mvn gatling:test -Dgatling.simulationClass=<package.SimulationClass>
    ```
    
##Gatling and Docker

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
    
###Scaling

  - lunch the gatling instances with the -nr (no reports) option:
    ```
    docker run --rm -v $PWD/src/test/resources:/opt/gatling/conf -v $PWD/src/test:/opt/gatling/user-files -v $PWD/reports:/opt/gatling/results denvazh/gatling -s <package-and-simulation-class> -nr
    ```
  - collect the generated simulation.log files (rename them so they won’t clash)
  - place them into a <simulation-folder-with-the-collected-logs> within the results folder of a Gatling instance
  - generate the reports with the -ro (reports only) option (gatling will consume all the log files within the given folder):
    ```
    docker run --rm -v $PWD/src/test/resources:/opt/gatling/conf -v $PWD/src/test:/opt/gatling/user-files -v $PWD/reports:/opt/gatling/results denvazh/gatling -ro /opt/gatling/results/<simulation-folder-with-the-collected-logs>
    ```

