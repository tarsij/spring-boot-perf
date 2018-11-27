import io.gatling.recorder.GatlingRecorder
import io.gatling.recorder.config.RecorderPropertiesBuilder
import utils.IDEPathHelper

object Recorder extends App {

  val props = new RecorderPropertiesBuilder
  props.simulationsFolder(IDEPathHelper.mavenSourcesDirectory.toString)
  props.resourcesFolder(IDEPathHelper.mavenResourcesDirectory.toString)
  props.simulationPackage("simulations")

  GatlingRecorder.fromMap(props.build, Some(IDEPathHelper.recorderConfigFile))
}
