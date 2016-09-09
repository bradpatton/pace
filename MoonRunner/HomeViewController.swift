/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import CoreData

class HomeViewController: UIViewController {
  var managedObjectContext: NSManagedObjectContext?

    
    let titles = ["Rain", "Fire", "Forest", "Ocean", "Silent"]
    var time = [String]()
    var scene = String()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        timeArray(120)
        
        self.pickerView.delegate = self
        self.pickerView.dataSource = self
        
        self.pickerView.font = UIFont(name: "HelveticaNeue-Light", size: 20)!
        self.pickerView.highlightedFont = UIFont(name: "HelveticaNeue-Light", size: 20)!
        self.pickerView.pickerViewStyle = .Wheel
        self.pickerView.maskDisabled = false
        
        self.pickerView.reloadData()
        self.pickerView.selectItem(2, animated: false)
        
        self.timePickerView.delegate = self
        self.timePickerView.dataSource = self
        
        self.timePickerView.font = UIFont(name: "HelveticaNeue-Light", size: 20)!
        self.timePickerView.highlightedFont = UIFont(name: "HelveticaNeue-Light", size: 20)!
        self.timePickerView.pickerViewStyle = .Wheel
        self.timePickerView.maskDisabled = false
        
        self.timePickerView.reloadData()
        self.timePickerView.selectItem(2, animated: false)
        
    }

    
    func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int {
        
        if(pickerView.tag == 2){
            return self.titles.count
        }else{
            return self.time.count
        }
    }
    
    func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> String {
        
        if(pickerView.tag == 2){
            
            scene = self.titles[item]
            return self.titles[item]
            
        }else {
            
            self.totalSeconds = itemToSeconds(self.time[item])
            return self.time[item]
            
        }
    }
    
    func timeArray(numberOfMinutes: Int) {
        
        for var index = 5;index < numberOfMinutes+1; index = index + 5 {
            
            time.append(String(index) + " min")
            
        }
    }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.destinationViewController.isKindOfClass(NewRunViewController) {
      if let newRunViewController = segue.destinationViewController as? NewRunViewController {
        newRunViewController.managedObjectContext = managedObjectContext
      }
    }
    else if segue.destinationViewController.isKindOfClass(BadgesTableViewController) {
      let fetchRequest = NSFetchRequest(entityName: "Run")

      let sortDescriptor = NSSortDescriptor(key: "timestamp", ascending: false)
      fetchRequest.sortDescriptors = [sortDescriptor]

      let runs = (try! managedObjectContext!.executeFetchRequest(fetchRequest)) as! [Run]

      let badgesTableViewController = segue.destinationViewController as! BadgesTableViewController
      badgesTableViewController.badgeEarnStatusesArray = BadgeController.sharedController.badgeEarnStatusesForRuns(runs)
    }

  }
}