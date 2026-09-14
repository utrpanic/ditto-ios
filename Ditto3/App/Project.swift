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
          "UIBackgroundModes": .array([
            .string("audio"),
          ]),
        ]
      ),
      sources: ["Sources/**"],
      resources: ["Resources/**"],
      dependencies: [
        .platform(target: "Platform"),
        .platform(target: "PlaybackImp"),
        .core(target: "Playback"),
        .core(target: "Repository"),
        .core(target: "RepositoryImp"),
        .feature(target: "Discover"),
        .feature(target: "Episode"),
        .feature(target: "Main"),
        .feature(target: "Latest"),
        .feature(target: "Library"),
        .feature(target: "Podcast"),
        .feature(target: "Player"),
        .feature(target: "Search"),
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
