import UIKit
import CoreData
import AVFoundation

extension UIActivity.ActivityType {
    static let reverseImageSearch =
        UIActivity.ActivityType("jorg.Gallery.reverseImage")
}

class ReverseImageSearchService: UIActivity {
    var viewController: UIViewController?
    var post: Post?
    
    override class var activityCategory: UIActivity.Category {
        return .action
   }

   override var activityType: UIActivity.ActivityType? {
        return .reverseImageSearch
   }

   override var activityTitle: String? {
       return NSLocalizedString("Reverse Image Search", comment: "activity title")
   }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override var activityViewController: UIViewController? {
        return ReverseImageViewController.loadFromStoryboard(post: self.post!)
    }
}

func generateThumbnail(path: URL) -> UIImage? {
    do {
        let asset = AVURLAsset(url: path, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
        let thumbnail = UIImage(cgImage: cgImage)
        return thumbnail
    } catch let error {
        print("*** Error generating thumbnail: \(error.localizedDescription)")
        return nil
    }
}

class PostsManager: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDropDelegate, UICollectionViewDragDelegate {
    var viewController: UIViewController?
    var collectionView : UICollectionView?
    var managedContext: NSManagedObjectContext?
    
    var posts: [NSManagedObject] = []
    
    private let itemsPerRow: CGFloat = 4
    
    private let sectionInsets = UIEdgeInsets(top: 10.0,
        left: 10.0,
        bottom: 10.0,
        right: 10.0)
        
    let documentsPath : URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].absoluteURL
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let post = posts[indexPath.row]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "postCell", for: indexPath as IndexPath) as! PostViewCell
        
        cell.name = post.value(forKey: "name") as? String
        
        let imagePath = documentsPath.appendingPathComponent(post.value(forKey: "name") as! String).path
        
        if(FileManager.default.fileExists(atPath: imagePath)) {
            let type = (post.value(forKey: "type") as? String)
            
            if(type == "public.mpeg-4") {
                let imagePath = documentsPath.appendingPathComponent(post.value(forKey: "name") as! String).path
              cell.imageView.image = generateThumbnail(path: URL(fileURLWithPath: imagePath))
            } else {
                cell.imageView.image = UIImage(contentsOfFile: imagePath)
            }
        } else {
            print("could not read " + imagePath)
        }
        
        return cell
    }
    
    init(viewController: UIViewController, collectionView: UICollectionView, tag: String?) {
        super.init()
        
        self.viewController = viewController
        self.collectionView = collectionView
        
        collectionView.dragInteractionEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.dropDelegate = self
        collectionView.dragDelegate = self
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        managedContext = appDelegate.persistentContainer.viewContext
        
        setTag(tag: tag)
    }
    
    func reload(request: NSFetchRequest<NSManagedObject>) {
        do {
            posts = try managedContext!.fetch(request)
            
            DispatchQueue.main.async {
                self.collectionView!.reloadData()
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func setTag(tag: String?) {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: managedContext)
        
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Post")
        
        if(tag != nil) {
            let predicate = NSPredicate(format: "ANY tags.name in %@", [tag])
            
            fetchRequest.predicate = predicate
        }
        
        reload(request: fetchRequest)
    }
    
    @objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Post")
        reload(request: fetchRequest)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = collectionView.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            return self.makeContextMenu(post: self.posts[indexPath.row])
        })
    }
    
    func makeContextMenu(post: NSManagedObject) -> UIMenu {
        let newWindow = UIAction(title: "Open in New Window", image: UIImage(systemName: "plus.square.on.square")) { action in
            let activity = NSUserActivity(activityType: "post")
            activity.userInfo = ["name": post.value(forKey: "name") as! String]
            activity.isEligibleForHandoff = true
            
            UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
        }
        
        let share = UIAction(title: "Share", image: UIImage(systemName: "square.and.arrow.up")) { action in
            let index = self.posts.firstIndex(of: post)
            
            let cell = self.collectionView?.cellForItem(at: IndexPath(row: index!, section: 0)) as! PostViewCell
            
            let imageSearch = ReverseImageSearchService()
            imageSearch.viewController = self.collectionView?.window?.rootViewController
            imageSearch.post = self.posts[index!] as? Post
                        
            let activityViewController = UIActivityViewController(activityItems: [cell.imageView.image!], applicationActivities: [imageSearch])
            activityViewController.popoverPresentationController?.sourceView = cell.contentView
            
            self.viewController?.present(activityViewController, animated: true, completion:nil)
        }
        
        let editTags = UIAction(title: "Tags", image: UIImage(systemName: "tag")) { action in
            #if targetEnvironment(macCatalyst)
                let activity = NSUserActivity(activityType: "tags")
                activity.userInfo = ["name": post.value(forKey: "name") as! String]
                activity.isEligibleForHandoff = true
                
                UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil, errorHandler: nil)
            #else
                let viewController = EditTagsViewController.loadFromStoryboard()
                viewController!.post = post as? Post
                
                self.viewController?.present(viewController!, animated: true)
            #endif
        }
        
        let info = UIAction(title: "Info", image: UIImage(systemName: "info.circle")) { action in
            let index = self.posts.firstIndex(of: post)

            let cell = self.collectionView?.cellForItem(at: IndexPath(row: index!, section: 0)) as! PostViewCell
            
            let viewController = PostInfoViewController.loadFromStoryboard()
            viewController!.post = post as? Post
            viewController!.image = cell.imageView.image
            
            self.viewController?.present(viewController!, animated: true)
        }
        
        let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { action in
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                    return
            }
            
            let managedContext = appDelegate.persistentContainer.viewContext
            
            managedContext.delete(post)
            self.posts.removeAll { (obj: NSManagedObject) -> Bool in
                return obj == post
            }
            
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
        
        #if targetEnvironment(macCatalyst)
        return UIMenu(title: "", children: [info, editTags, share, delete])
        #else
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIMenu(title: "", children: [newWindow, share, info, editTags, delete])
        } else {
            return UIMenu(title: "", children: [share, info, editTags, delete])
        }
        #endif
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        for item in coordinator.items {
            item.dragItem.itemProvider.loadObject(ofClass: UIImage.self,
            completionHandler: {(newImage, error)  -> Void in
                if let image = newImage as? UIImage {
                    if let data = image.jpegData(compressionQuality: 0.8) {
                        DispatchQueue.main.async {
                            guard let appDelegate =
                                UIApplication.shared.delegate as? AppDelegate else {
                                    return
                            }
                            
                            let managedContext = appDelegate.persistentContainer.viewContext
                            
                            let entity = NSEntityDescription.entity(forEntityName: "Post", in: managedContext)!
                            
                            let post = NSManagedObject(entity: entity, insertInto: managedContext)
                            
                            let uuid = UUID().uuidString

                            let filename = uuid + ".jpg"
                            
                            let newPath = self.documentsPath.appendingPathComponent(filename)
                            
                            try? data.write(to: newPath)
                            
                            post.setValue(filename, forKeyPath: "name")
                            
                            try? managedContext.save()
                            self.posts.append(post)
                        
                            collectionView.reloadData()
                        }
                    }
                }
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let model = posts[indexPath.item]
        
        let activity = NSUserActivity(activityType: "post")
        activity.userInfo = ["name":  model.value(forKey: "name")!]
        activity.isEligibleForHandoff = true
        
        let itemProvider = NSItemProvider(object: (collectionView.cellForItem(at: indexPath) as! PostViewCell).imageView.image!)
        itemProvider.suggestedName = model.value(forKey: "name") as? String
        itemProvider.registerObject(activity, visibility: .all)
        
        return [UIDragItem(itemProvider: itemProvider)]
    }
}
