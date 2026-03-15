import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "App",
  options: .default,
  targets: [
    .target(
      name: "App",
      destinations: .iOS,
      product: .app,
      bundleId: AppConfig.bundleId("app"),
      infoPlist: .extendingDefault(
        with: [
          "CFBundleDisplayName": .string(AppConfig.displayName),
          "UIApplicationSceneManifest": [
            "UIApplicationSupportsMultipleScenes": false,
            "UISceneConfigurations": [
              "UIWindowSceneSessionRoleApplication": [
                [
                  "UISceneConfigurationName": "Default Configuration",
                  "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate",
                ],
              ],
            ],
          ],
          "UILaunchStoryboardName": .string("LaunchScreen"),
        ]
      ),
      sources: ["Sources/**"],
      resources: ["Resources/**"],
      dependencies: [
        .project(target: "Repository", path: "../Core"),
        .project(target: "RepositoryImp", path: "../Core"),
        .project(target: "Platform", path: "../Platform"),
        .project(target: "TopPodcasts", path: "../Feature"),
      ]
    ),
    .target(
      name: "AppTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: AppConfig.bundleId("app.tests"),
      infoPlist: .default,
      sources: ["Tests/**"],
      dependencies: [
        .target(name: "App"),
      ]
    ),
  ]
)
