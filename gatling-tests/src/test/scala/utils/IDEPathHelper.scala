package utils

import java.io.FileInputStream
import java.nio.file.Path
import java.util.Properties

import io.gatling.commons.util.PathHelper._

object IDEPathHelper {

  val gatlingConfUrl: Path = getClass.getClassLoader.getResource("gatling.conf")
  val projectRootDir = gatlingConfUrl.ancestor(3)

  val mavenTargetDirectory = projectRootDir / "target"
  val mavenBinariesDirectory = mavenTargetDirectory / "test-classes"

  val mavenPropertiesFile = IDEPathHelper.mavenBinariesDirectory / "maven.properties"
  val mavenProperties = new Properties()
  if (mavenPropertiesFile.exists) {
    mavenProperties.load(new FileInputStream(mavenPropertiesFile.toString))
    mavenProperties.forEach((k, v) => System.setProperty(k.toString, v.toString))
  }

  val mavenSourcesDirectory = System.getProperty("gatling.simulationsFolder", (projectRootDir / "src" / "test" / "scala").toString).toAbsolutePath
  val mavenResourcesDirectory = System.getProperty("gatling.resourcesFolder", (projectRootDir / "src" / "test" / "resources").toString).toAbsolutePath
  val resultsDirectory = System.getProperty("gatling.resultsFolder", (mavenTargetDirectory / "gatling").toString).toAbsolutePath

  val resourcesDirectory = mavenResourcesDirectory
  val recorderSimulationsDirectory = mavenSourcesDirectory
  val recorderConfigFile = mavenResourcesDirectory / "recorder.conf"
}
