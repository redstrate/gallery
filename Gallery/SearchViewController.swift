import UIKit
import CoreData

class SearchViewController: UIViewController {
    @IBOutlet weak var collectionView: PostCollectionView!
    
    @IBOutlet weak var searchField: UITextField!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.viewController = self
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPost" {
            let newViewController = segue.destination as! PostViewController
            let index = self.collectionView.indexPathsForSelectedItems?.first
            
            newViewController.post = self.collectionView.posts[index!.row]
            newViewController.image = (self.collectionView.cellForItem(at: index!) as! PostViewCell).imageView.image;
        }
    }
    
    @IBAction func searchAction(_ sender: Any) {
        collectionView.actualInit(tag: searchField.text)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showPost" {
            #if targetEnvironment(macCatalyst)
            let index = self.collectionView.indexPathsForSelectedItems?.first
            
            let post = self.collectionView.posts[index!.row]
            
            let activity = NSUserActivity(activityType: "post")
            activity.userInfo = ["name": post.value(forKey: "name") as! String]
            activity.isEligibleForHandoff = true
            
            UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
            
            return false
            #else
            return true
            #endif
        }
        
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
}
