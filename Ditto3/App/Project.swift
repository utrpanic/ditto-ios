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
      bundleId: "com.example.ditto3",
      infoPlist: .extendingDefault(
        with: [
          "CFBundleDisplayName": .string("Ditto3"),
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
        .platform(target: "Platform"),
        .core(target: "Repository"),
        .core(target: "RepositoryImp"),
        .feature(target: "Bookmarks"),
        .feature(target: "Main"),
        .feature(target: "New"),
        .feature(target: "Podcast"),
        .feature(target: "Search"),
        .feature(target: "TopPodcasts"),
      ]
    ),
    .target(
      name: "AppTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "com.example.ditto3.tests",
      infoPlist: .default,
      sources: ["Tests/**"],
      dependencies: [
        .target(name: "App"),
      ]
    ),
  ],
  schemes: [
    .scheme(
      name: "App",
      buildAction: .buildAction(
        targets: [
          "App",
        ]
      ),
      testAction: .targets([
        .testableTarget(target: "AppTests"),
      ]),
      runAction: .runAction(
        executable: "App"
      )
    ),
  ]
)
