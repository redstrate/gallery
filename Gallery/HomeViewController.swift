import UIKit
import CoreData

class HomeViewController: UIViewController, UIDocumentPickerDelegate {
    @IBOutlet weak var collectionView: UICollectionView!
    
    var collectionManager: PostsManager?
    
    let documentsPath : URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].absoluteURL
    
    var tags: String?
    
    func updateWindowTitle() {
        let windowTitle = tags ?? "All Posts"
        
        self.view.window?.windowScene!.title = windowTitle
        navigationItem.title = windowTitle
    }
    
    func importFile(path: URL) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Post", in: managedContext)!
        
        let post = NSManagedObject(entity: entity, insertInto: managedContext)
        
        let oldPath = path
        let newPath = documentsPath.appendingPathComponent(path.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: newPath.path) {
                try FileManager.default.removeItem(at: newPath)
            }

            try FileManager.default.copyItem(at: oldPath, to: newPath)
            
            if let resourceValues = try? path.resourceValues(forKeys: [.typeIdentifierKey]),
                let uti = resourceValues.typeIdentifier {
                post.setValue(uti, forKeyPath: "type")
            }
            
            post.setValue(Date(), forKeyPath: "date")
            post.setValue(path.lastPathComponent, forKeyPath: "name")
            
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        collectionManager = PostsManager(viewController: self, collectionView: collectionView, tag: tags)
        
        updateWindowTitle()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateWindowTitle()
    }
    
    @IBAction func importAction(_ sender: Any) {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.image", "public.movie"], in: .import)
        documentPicker.delegate = self as UIDocumentPickerDelegate
        documentPicker.allowsMultipleSelection = true
        
        present(documentPicker, animated: true)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            importFile(path: url)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPost" {
            let newViewController = segue.destination as! PostDetailViewController
            let index = self.collectionView.indexPathsForSelectedItems?.first
            
            newViewController.post = self.collectionManager?.posts[index!.row]
            newViewController.image = (self.collectionView.cellForItem(at: index!) as! PostViewCell).imageView.image;
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showPost" {
            #if targetEnvironment(macCatalyst)
                guard let cell = sender as? PostViewCell else {
                    return false
                }
         
                guard let name = cell.name else {
                    return false
                }
                
                let activity = NSUserActivity(activityType: "post")
                activity.userInfo = ["name": name]
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

extension HomeViewController {
    static func loadFromStoryboard() -> HomeViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        return storyboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController
    }
}
