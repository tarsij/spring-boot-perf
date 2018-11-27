import io.gatling.app.Gatling
import io.gatling.core.config.GatlingPropertiesBuilder
import utils.IDEPathHelper

object Engine extends App {

  val gatlingProperties = new GatlingPropertiesBuilder()
    .simulationsDirectory(IDEPathHelper.mavenSourcesDirectory.toString)
    .resourcesDirectory(IDEPathHelper.mavenResourcesDirectory.toString)
    .binariesDirectory(IDEPathHelper.mavenBinariesDirectory.toString)
    .resultsDirectory(IDEPathHelper.resultsDirectory.toString)

  val simulationClass = System.getProperty("gatling.simulationClass", "")
  if (simulationClass.nonEmpty) {
    gatlingProperties.simulationClass(simulationClass)
  }

  val runDescription = System.getProperty("gatling.runDescription", "")
  if (runDescription.nonEmpty) {
    gatlingProperties.runDescription(runDescription)
  }

  val noReports = System.getProperty("gatling.noReports", "false")
  if (noReports.nonEmpty && noReports.toBoolean) {
    gatlingProperties.noReports()
  }

  val reportsOnly = System.getProperty("gatling.reportsOnly", "")
  if (reportsOnly.nonEmpty) {
    gatlingProperties.reportsOnly(reportsOnly)
  }

  Gatling.fromMap(gatlingProperties.build)
}
