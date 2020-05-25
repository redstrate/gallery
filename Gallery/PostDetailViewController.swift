import UIKit
import CoreData
import AVFoundation
import AVKit

class PostDetailViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var shareButton: UIBarButtonItem?

    var post: NSManagedObject?
    var image: UIImage?
    var isPopup: Bool = false
    
    let documentsPath : URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].absoluteURL
    
    func updateWindowTitle() {
        var windowTitle = "Untagged Post"

        var tagList = ""
        
        guard let postObject = post as? Post else {
            return
        }
        
        for (i, tag) in postObject.tags!.enumerated() {
            if !tagList.isEmpty && i != postObject.tags!.count - 1 {
                tagList += ", "
            }
            
            tagList += (tag as! Tag).name!
        }
        
        if !tagList.isEmpty {
            windowTitle = tagList
        }
        
        self.view.window?.windowScene!.title = windowTitle
        navigationItem.title = windowTitle
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if post != nil {
            if image == nil {
                let imagePath = documentsPath.appendingPathComponent(post!.value(forKey: "name") as! String).path
                
                if((post?.value(forKey: "type") as? String) == "public.mpeg-4") {
                    self.image = generateThumbnail(path: URL(fileURLWithPath: imagePath))
                } else {
                    self.image = UIImage(contentsOfFile: imagePath)
                }
            }
            
            imageView?.image = self.image
            
            if(isPopup) {
                #if targetEnvironment(macCatalyst)
                navigationItem.leftBarButtonItem = UIBarButtonItem(title: nil, style: .done, target: nil, action: nil)
                #else
                navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(closePopup))

                #endif
            }
        }
            
        updateWindowTitle()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateWindowTitle()
    }
    
    @objc func closePopup() {
        UIApplication.shared.requestSceneSessionDestruction((self.view.window?.windowScene!.session)!, options: nil, errorHandler: nil)
    }
    
    @IBAction func shareAction(_ sender: Any) {
        let imageSearch = ReverseImageSearchService()
        imageSearch.viewController = parent
        imageSearch.post = self.post as? Post
                    
        let activityViewController = UIActivityViewController(activityItems: [self.image!], applicationActivities: [imageSearch])
        activityViewController.popoverPresentationController?.barButtonItem = shareButton
        
        self.present(activityViewController, animated: true, completion:nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTags" {
            guard let newViewController = segue.destination as? EditTagsViewController else {
                return
            }
            
            newViewController.post = self.post as? Post
            
            segue.destination.popoverPresentationController?.delegate = self
        } else if segue.identifier == "showInfo" {
            guard let newViewController = segue.destination as? PostInfoViewController else {
                return
            }
            
            newViewController.post = self.post as? Post
            newViewController.image = self.image
        }
    }
    
    @IBAction func playAction(_ sender: Any) {
        if((post?.value(forKey: "type") as? String) == "public.mpeg-4") {
            let imagePath = documentsPath.appendingPathComponent(post!.value(forKey: "name") as! String).path
            
            let player = AVPlayer(url: URL(fileURLWithPath: imagePath))
            
            let controller = AVPlayerViewController()
            controller.player = player
            
            present(controller, animated: true) {
                player.play()
            }
        }
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        updateWindowTitle()
    }
}

extension PostDetailViewController {
    static func loadFromStoryboard() -> PostDetailViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        return storyboard.instantiateViewController(withIdentifier: "PostViewController") as? PostDetailViewController
    }
}
