import UIKit
import CoreData

class EditTagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    var post: Post?
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tagField: UITextField!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return post!.tags!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tagCell", for: indexPath as IndexPath) as! TagViewCell
                
        cell.label.text = (post?.tags![indexPath.row] as! Tag).name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if(editingStyle == .delete) {
            post?.removeFromTags(post?.tags![indexPath.row] as! Tag)
            
            tableView.reloadData()
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let tag = Tag(context: managedContext)
        tag.name = tagField.text
        
        post?.addToTags(tag)
        
        tableView.reloadData()
        tagField.text?.removeAll()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textFieldDidEndEditing(textField)
        return false
    }
    
    @IBAction func editAction(_ sender: Any) {
        isEditing = !isEditing
        
        tableView.setEditing(isEditing, animated: true)
        
        if isEditing {
            editButton.setTitle("Done", for: UIControl.State.normal)
        } else {
            editButton.setTitle("Edit", for: UIControl.State.normal)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTag" {
            let newViewController = segue.destination as! TagPreviewViewController
            let index = self.tableView.indexPathForSelectedRow
            
            newViewController.tag = (post?.tags![index!.row] as! Tag).name
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showTag" {
            #if targetEnvironment(macCatalyst)
            guard let cell = sender as? TagViewCell else {
                return false
            }
            
            guard let name = cell.label.text else {
                return false
            }
            
            let activity = NSUserActivity(activityType: "postsOf")
            activity.userInfo = ["tags": name]
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

extension EditTagsViewController {
    static func loadFromStoryboard() -> EditTagsViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        return storyboard.instantiateViewController(withIdentifier: "EditTagsViewController") as? EditTagsViewController
    }
}
