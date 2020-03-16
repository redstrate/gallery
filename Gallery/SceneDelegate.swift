import UIKit
import CoreData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
            if !configure(window: window, with: userActivity) {
                print("Failed to restore from \(userActivity)")
            }
        }
        
        #if targetEnvironment(macCatalyst)
            guard let windowScene = (scene as? UIWindowScene) else {
                return
            }
        
            let toolbar = NSToolbar(identifier: "Toolbar")
            toolbar.delegate = (window?.rootViewController as! UINavigationController).topViewController as? NSToolbarDelegate
            toolbar.allowsUserCustomization = true

            windowScene.titlebar!.toolbar = toolbar
            windowScene.titlebar!.titleVisibility = .visible
            
            (window?.rootViewController as! UINavigationController).navigationBar.isHidden = true
        #endif
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    
    func configure(window: UIWindow?, with activity: NSUserActivity) -> Bool {
        if activity.activityType == "post" {
            if let photoID = activity.userInfo?["name"] as? String {
                if let photoDetailViewController = PostViewController.loadFromStoryboard() {
                    guard let appDelegate =
                        UIApplication.shared.delegate as? AppDelegate else {
                            return false
                    }
                    
                    let managedContext = appDelegate.persistentContainer.viewContext
                    
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Post")
                    
                    request.predicate = NSPredicate(format: "name = %@", photoID)
                    request.returnsObjectsAsFaults = false
                    
                    do {
                        let result = try managedContext.fetch(request)
                        
                        guard let object = result[0] as? NSManagedObject else {
                            return false
                        }
                        
                        photoDetailViewController.post = object
                        photoDetailViewController.isPopup = true
                        
                        if let navigationController = window?.rootViewController as? UINavigationController {
                            navigationController.pushViewController(photoDetailViewController, animated: false)
                            
                            return true
                        }
                    } catch _ as NSError {
                        return false
                    }
                }
            }
        }
        
        return false
    }
}
