import RIBsLite

@MainActor
protocol PlayerRouting: Routing {}

@MainActor
final class PlayerRouter: Router<ViewControllable>, PlayerRouting {}
