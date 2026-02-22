import ProjectDescription
import ProjectDescriptionHelpers

let workspace = Workspace(
  name: AppConfig.projectName,
  projects: [
    "App",
    "Core",
    "Feature",
    "Platform",
  ]
)
