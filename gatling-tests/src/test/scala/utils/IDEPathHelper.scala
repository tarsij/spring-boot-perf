package utils

import java.io.FileInputStream
import java.nio.file.Path
import java.util.Properties

import io.gatling.commons.util.PathHelper._

object IDEPathHelper {

  val gatlingConfUrl: Path = getClass.getClassLoader.getResource("gatling.conf")
  val projectRootDir: Path = gatlingConfUrl.ancestor(3)

  val mavenTargetDirectory: Path = projectRootDir / "target"
  val mavenBinariesDirectory: Path = mavenTargetDirectory / "test-classes"

  private val mavenPropertiesFile = IDEPathHelper.mavenBinariesDirectory / "maven.properties"
  private val mavenProperties = new Properties()
  if (mavenPropertiesFile.exists) {
    mavenProperties.load(new FileInputStream(mavenPropertiesFile.toString))
    mavenProperties.forEach((k, v) => System.setProperty(k.toString, v.toString))
  }

  val mavenSourcesDirectory: Path = projectRootDir / System.getProperty("gatling.simulationsFolder", "src/test/scala")
  val mavenResourcesDirectory: Path = projectRootDir / System.getProperty("gatling.resourcesFolder", "src/test/resources")
  val resultsDirectory: Path = projectRootDir / System.getProperty("gatling.resultsFolder", "target/gatling")

  val resourcesDirectory: Path = mavenResourcesDirectory
  val recorderSimulationsDirectory: Path = mavenSourcesDirectory
  val recorderConfigFile: Path = mavenResourcesDirectory / "recorder.conf"
}
