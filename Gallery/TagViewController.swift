import UIKit
import CoreData

class TagViewController: UIViewController {
    var tag: String?
    
    @IBOutlet weak var collectionView: PostCollectionView!
        
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.actualInit(tag: self.tag)
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
}
