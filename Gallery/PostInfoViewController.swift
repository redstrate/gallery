import UIKit
import CoreData
import AVFoundation

class PostInfoViewController: UIViewController {
    var post: Post?
    var image: UIImage?
    
    @IBOutlet weak var infoLabel: UILabel!
    
    private func resolutionForLocalVideo(url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
       let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }

    
    let documentsPath : URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].absoluteURL
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var type = "Unavailable"
        if(post!.type != nil) {
            if(post!.type == "public.image") {
                type = "Image"
            } else if(post!.type == "public.mpeg-4") {
                type = "Video"
            }
        }
        
        var date = "Unavailable"
        if(post!.date != nil) {
            date = dateFormatter.string(from: post!.date!)
        }
        
        var size = "Unavailable"
        if(post?.type == "public.mpeg-4") {
            let videoPath = documentsPath.appendingPathComponent(post!.value(forKey: "name") as! String).path
            
            let resolution = resolutionForLocalVideo(url: URL(fileURLWithPath: videoPath))
            
            size = String(format: "%.0f", (resolution?.width)!) + "x" + String(format: "%.0f", (resolution?.height)!)
        } else if(image != nil) {
            size = String(format: "%.0f", (image?.size.width)!) + "x" + String(format: "%.0f", (image?.size.height)!)
        }
        
        infoLabel.text = "Type: " + type + "\nDate: " + date + "\nSize: " + size
    }
    
    @IBAction func exitAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension PostInfoViewController {
    static func loadFromStoryboard() -> PostInfoViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        return storyboard.instantiateViewController(withIdentifier: "PostInfoViewController") as? PostInfoViewController
    }
}
