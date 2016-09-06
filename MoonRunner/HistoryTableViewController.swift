//
//  HistoryTableViewController.swift
//  MoonRunner
//
//  Created by Bradley Patton on 9/3/16.
//  Copyright © 2016 Zedenem. All rights reserved.
//

import UIKit
import CoreData

class HistoryTableViewController: UITableViewController {
    
    var runs = [NSManagedObject]()
    
   
    
   
    @IBOutlet weak var navigationBar: UINavigationBar!
    //@IBOutlet weak var navBar: UINavigationBar!
  
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("viewwillload")
        
        
        
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext
        
        let fetchRequestRuns = NSFetchRequest(entityName: "Run")
        
        let sort = NSSortDescriptor(key: "timestamp", ascending: false)
        
        fetchRequestRuns.sortDescriptors = [sort]
        
        do {
            let results =
                try managedContext!.executeFetchRequest(fetchRequestRuns)
            runs = results as! [NSManagedObject]
            var totalTime: Int = 0
            for i in runs {
                let runTime = i.valueForKey("duration") as! Int
                totalTime += runTime
                let (h,m,s) = secondsToHoursMinutesSeconds(totalTime)
                
                let timeLabelText = String(format: "%02d", h) + " : " + String(format: "%02d", m) + " : " + String(format: "%02d", s)
                
               // navigationBar.topItem!.title = "Total :  \(timeLabelText)"
            }
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return runs.count
    }
    
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    

  
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("CustomTableViewCell") as! CustomTableViewCell
        let run = runs[indexPath.row]
        
        cell.paceLabel.text = "Pace"
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = NSDateFormatterStyle.ShortStyle
        formatter.timeStyle = .ShortStyle
        
        if run.valueForKey("timestamp") != nil {
            
            let dateString = formatter.stringFromDate(run.valueForKey("timestamp") as! NSDate)
            cell.dateLabel.text = dateString
            
        }
        
        let (h,m,s) = secondsToHoursMinutesSeconds(run.valueForKey("duration") as! Int)
        
        let timeLabelText = String(format: "%02d", h) + " : " + String(format: "%02d", m) + " : " + String(format: "%02d", s)
        
        
        cell.timeLabel.text = timeLabelText
        return cell

    }
   

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
