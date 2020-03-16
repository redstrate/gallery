import UIKit
import CoreData

class ViewController: UIViewController, UIDocumentPickerDelegate {
    @IBOutlet weak var collectionView: PostCollectionView!
    
    let documentsPath : URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].absoluteURL
    
    let windowTitle = "Home"
    
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
            try FileManager.default.copyItem(at: oldPath, to: newPath)
            
            if let resourceValues = try? path.resourceValues(forKeys: [.typeIdentifierKey]),
                let uti = resourceValues.typeIdentifier {
                post.setValue(uti, forKeyPath: "type")
            }
            
            post.setValue(Date(), forKeyPath: "date")
            post.setValue(path.lastPathComponent, forKeyPath: "name")
            
            try managedContext.save()
            collectionView.posts.append(post)
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.actualInit(tag: nil)
        collectionView.viewController = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.view.window?.windowScene!.title = windowTitle
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
            let newViewController = segue.destination as! PostViewController
            let index = self.collectionView.indexPathsForSelectedItems?.first
            
            newViewController.post = self.collectionView.posts[index!.row]
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

#if targetEnvironment(macCatalyst)
private let OurButtonToolbarIdentifier = NSToolbarItem.Identifier(rawValue: "OurButton")
private let OurButtonToolbarIdentifier2 = NSToolbarItem.Identifier(rawValue: "OurButton2")
private let TitlebarToolbarIdentifier = NSToolbarItem.Identifier(rawValue: "Titlebar")

extension ViewController: NSToolbarDelegate {
    @objc func searchAction() {
        if(navigationController?.topViewController != self) {
            navigationController?.popViewController(animated: true)
        } else {
            performSegue(withIdentifier: "search", sender: nil)
        }
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [OurButtonToolbarIdentifier2, NSToolbarItem.Identifier.flexibleSpace, OurButtonToolbarIdentifier]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }
        
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if (itemIdentifier == OurButtonToolbarIdentifier2) {
            let barButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add,
                              target: self,
                              action: #selector(self.importAction))
            let button = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            button.label = "Add";
            
            return button
        }

        if (itemIdentifier == OurButtonToolbarIdentifier) {
            let barButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.search,
                  target: self,
                  action: #selector(self.searchAction))
            let button = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            button.label = "Search";
            return button
        }
        return nil
    }
}
#endif
