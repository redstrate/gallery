import UIKit
import CoreData

class TagViewController: UIViewController {
    var tag: String?
    
    var collectionManager: PostsManager?
    
    @IBOutlet weak var collectionView: UICollectionView!
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionManager = PostsManager(collectionView: collectionView, tag: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        collectionManager?.setTag(tag: self.tag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPost" {
            let newViewController = segue.destination as! PostViewController
            let index = self.collectionView.indexPathsForSelectedItems?.first
            
            newViewController.post = self.collectionManager?.posts[index!.row]
            newViewController.image = (self.collectionView.cellForItem(at: index!) as! PostViewCell).imageView.image;
        }
    }
}
