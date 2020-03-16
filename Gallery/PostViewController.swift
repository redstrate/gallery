import UIKit
import CoreData
import AVFoundation
import AVKit

class PostViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView?
    @IBOutlet weak var shareButton: UIBarButtonItem?

    var post: NSManagedObject?
    var image: UIImage?
    var isPopup: Bool = false
    
    let documentsPath : URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].absoluteURL
    
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
                navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(closePopup))
            }
        }
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
        } else if segue.identifier == "showInfo" {
            guard let newViewController = segue.destination as? InfoViewController else {
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
}

extension PostViewController {
    static func loadFromStoryboard() -> PostViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        return storyboard.instantiateViewController(withIdentifier: "PostViewController") as? PostViewController
    }
}


#if targetEnvironment(macCatalyst)

private let EditButtonToolbarIdentifier = NSToolbarItem.Identifier(rawValue: "OurButton")
private let ShareButtonToolbarIdentifier = NSToolbarItem.Identifier(rawValue: "OurButton2")
private let InfoButtonToolbarIdentifier = NSToolbarItem.Identifier(rawValue: "OurButton3")

extension PostViewController: NSToolbarDelegate {
    @objc func editTagsAction() {
        if(navigationController?.topViewController != self) {
            navigationController?.popViewController(animated: true)
        } else {
            performSegue(withIdentifier: "showTags", sender: nil)
        }
    }
    
    @objc func infoAction() {
        if(navigationController?.topViewController != self) {
            navigationController?.popViewController(animated: true)
        } else {
            performSegue(withIdentifier: "showInfo", sender: nil)
        }
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [NSToolbarItem.Identifier.flexibleSpace, InfoButtonToolbarIdentifier, EditButtonToolbarIdentifier, ShareButtonToolbarIdentifier]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarDefaultItemIdentifiers(toolbar)
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if (itemIdentifier == InfoButtonToolbarIdentifier) {
            let barButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.camera,
                              target: self,
                              action: #selector(self.infoAction))
            let button = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            return button
        }
        
        if (itemIdentifier == EditButtonToolbarIdentifier) {
            let barButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.edit,
                              target: self,
                              action: #selector(self.editTagsAction))
            let button = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            return button
        }
        
        if (itemIdentifier == ShareButtonToolbarIdentifier) {
            let barButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.action,
                              target: self,
                              action: #selector(self.shareAction))
            let button = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            return button
        }
        
        return nil
    }
}

#endif
