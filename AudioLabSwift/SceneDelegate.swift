

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        //This method is used to configure and attach the app's `UIWindow` to the provided `UIWindowScene` when launching, especially if not using a storyboard, ensuring the app's interface is displayed.
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // This method is called when the system releases a scene, allowing you to release resources, as the scene may re-connect later or its session may be discarded.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // This method is called when the scene becomes active, allowing you to restart any tasks that were paused or not started during the inactive state.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // This method is called when the scene moves to the background, allowing you to save data, release resources, and store state information to restore the scene later.
    }


}

