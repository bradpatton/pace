import UIKit
import CoreData
import CoreLocation
import HealthKit
import MapKit
import AudioToolbox


let DetailSegueName = "RunDetails"

class NewRunViewController: UIViewController, AKPickerViewDataSource, AKPickerViewDelegate  {
  var managedObjectContext: NSManagedObjectContext?

  var run: Run!

@IBOutlet weak var heartratePickerView: AKPickerView!
 
@IBOutlet weak var pacePickerView: AKPickerView!
    
  var upcomingBadge : Badge?
  @IBOutlet weak var nextBadgeLabel: UILabel!
  @IBOutlet weak var nextBadgeImageView: UIImageView!

  @IBOutlet weak var promptLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var distanceLabel: UILabel!
  @IBOutlet weak var paceLabel: UILabel!
  @IBOutlet weak var startButton: UIButton!
  @IBOutlet weak var stopButton: UIButton!

  @IBOutlet weak var mapView: MKMapView!

  var seconds = 0.0
  var distance = 0.0
  var paceSpeed = 0.0
    var hRate = 0

  lazy var locationManager: CLLocationManager = {
    var _locationManager = CLLocationManager()
    _locationManager.delegate = self
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest
    _locationManager.activityType = .Fitness

    // Movement threshold for new events
    _locationManager.distanceFilter = 10.0
    return _locationManager
    }()

  lazy var locations = [CLLocation]()
  lazy var timer = NSTimer()

    
    var pace = [String]()
    var heartrate = [String]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        
        heartrateArray(190)
        paceArray(30)
        
         self.heartratePickerView.delegate = self
         self.heartratePickerView.dataSource = self
         
         self.heartratePickerView.font = UIFont(name: "HelveticaNeue-Light", size: 20)!
         self.heartratePickerView.highlightedFont = UIFont(name: "HelveticaNeue-Light", size: 20)!
         self.heartratePickerView.pickerViewStyle = .Wheel
         self.heartratePickerView.maskDisabled = false
         
         self.heartratePickerView.reloadData()
         self.heartratePickerView.selectItem(2, animated: false)
    
         self.pacePickerView.delegate = self
         self.pacePickerView.dataSource = self
         
         self.pacePickerView.font = UIFont(name: "HelveticaNeue-Light", size: 20)!
         self.pacePickerView.highlightedFont = UIFont(name: "HelveticaNeue-Light", size: 20)!
         self.pacePickerView.pickerViewStyle = .Wheel
         self.pacePickerView.maskDisabled = false
         
         self.pacePickerView.reloadData()
         self.pacePickerView.selectItem(7, animated: false)
        
    }
    
    
    func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int {
        
        if(pickerView.tag == 2){
            return self.pace.count
        }else{
           
            return self.heartrate.count
        }
    }
    
    func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> String {
        
        if(pickerView.tag == 2){
            
            return self.pace[item] + " mi/min"
            
        }else {
            
            // self.totalSeconds = itemToSeconds(self.time[item])
            return self.heartrate[item] + " bpm"
            
        }
    }
    
    func pickerView(pickerView: AKPickerView, didSelectItem item: Int) {
        
        paceSpeed = Double(self.pace[item])!
        hRate = Int(self.heartrate[item])!
        print(String(paceSpeed))
    }
    
    func paceArray(numberOfMinutes: Int) {
        
        for var index = 4;index < numberOfMinutes+1; index = index + 1 {
            
            pace.append(String(index))
            
        }
    }
    func heartrateArray(numberOfMinutes: Int) {
        
        for var index = 5;index < numberOfMinutes+1; index = index + 5 {
            
            heartrate.append(String(index))
            
        }
    }


  override func viewWillAppear(animated: Bool) {
    
    super.viewWillAppear(animated)

    startButton.hidden = false
    promptLabel.hidden = false
    pacePickerView.hidden = false
    heartratePickerView.hidden = false

    timeLabel.hidden = true
    distanceLabel.hidden = true
    paceLabel.hidden = true
    stopButton.hidden = true

    locationManager.requestAlwaysAuthorization()

    mapView.hidden = true

    nextBadgeLabel.hidden = true
    nextBadgeImageView.hidden = true
    
  }

  override func viewWillDisappear(animated: Bool) {
    
    super.viewWillDisappear(animated)
    timer.invalidate()
    
  }

  func eachSecond(timer: NSTimer) {
    
    seconds = seconds + 1
    let secondsQuantity = HKQuantity(unit: HKUnit.secondUnit(), doubleValue: seconds)
    timeLabel.text = "Time: " + secondsQuantity.description
    let distanceQuantity = HKQuantity(unit: HKUnit.mileUnit(), doubleValue: round(100*distance)/100)
    distanceLabel.text = "Distance: " + String(distanceQuantity)

    let paceUnit = HKUnit.minuteUnit().unitDividedByUnit(HKUnit.mileUnit())
    let paceQuantity = HKQuantity(unit: paceUnit, doubleValue: (seconds/60) / distance)
    let cPace = round(10*paceQuantity.doubleValueForUnit(paceUnit))/10
    paceLabel.text = "Pace: " + String(cPace) + " min/mi"
    
    if (paceSpeed - 0.5) > cPace   {
        playSuccessSound(1)
    }else if (paceSpeed + 0.5) < cPace{
        playSuccessSound(0)
    }
    
   checkNextBadge()
   

    if let upcomingBadge = upcomingBadge {
        
      let nextBadgeDistanceQuantity = HKQuantity(unit: HKUnit.meterUnit(), doubleValue: upcomingBadge.distance! - distance)
      nextBadgeLabel.text = "\(nextBadgeDistanceQuantity.description) until \(upcomingBadge.name!)"
      nextBadgeImageView.image = UIImage(named: upcomingBadge.imageName!)
        
    }

  }

  func startLocationUpdates() {
    // Here, the location manager will be lazily instantiated
    locationManager.startUpdatingLocation()
  }
    
    
  func saveRun() {
    // 1
    let savedRun = NSEntityDescription.insertNewObjectForEntityForName("Run",
      inManagedObjectContext: managedObjectContext!) as! Run
    savedRun.distance = distance
    savedRun.duration = seconds
    savedRun.timestamp = NSDate()

    // 2
    var savedLocations = [Location]()
    for location in locations {
      let savedLocation = NSEntityDescription.insertNewObjectForEntityForName("Location",
        inManagedObjectContext: managedObjectContext!) as! Location
      savedLocation.timestamp = location.timestamp
      savedLocation.latitude = location.coordinate.latitude
      savedLocation.longitude = location.coordinate.longitude
      savedLocations.append(savedLocation)
      
    }

    savedRun.locations = NSOrderedSet(array: savedLocations)
    run = savedRun
    
    
    }
    
    @IBAction func startPressed(sender: AnyObject) {
    startButton.hidden = true
    promptLabel.hidden = true
    pacePickerView.hidden = true
        heartratePickerView.hidden = true
    timeLabel.hidden = false
    distanceLabel.hidden = false
    paceLabel.hidden = false
    stopButton.hidden = false

    seconds = 0.0
    distance = 0.0
    locations.removeAll(keepCapacity: false)
    timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "eachSecond:", userInfo: nil, repeats: true)
    startLocationUpdates()

    mapView.hidden = false
    nextBadgeLabel.hidden = false
    nextBadgeImageView.hidden = false
  }

  @IBAction func stopPressed(sender: AnyObject) {
    let actionSheet = UIActionSheet(title: "Run Stopped", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Save", "Discard")
    actionSheet.actionSheetStyle = .Default
    actionSheet.showInView(view)
  }

    func playSuccessSound(sound: Int) {
        var soundURL: NSURL!
    if sound == 0 {
        soundURL = NSBundle.mainBundle().URLForResource("success", withExtension: "wav")
    }else if sound == 1 {
        soundURL = NSBundle.mainBundle().URLForResource("fast", withExtension: "wav")
    }else{
        soundURL = NSBundle.mainBundle().URLForResource("fast", withExtension: "wav")
        }
    var soundID : SystemSoundID = 0
    AudioServicesCreateSystemSoundID(soundURL!, &soundID)
    AudioServicesPlaySystemSound(soundID)

    //also vibrate
    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate));
  }

  func checkNextBadge() {
    let nextBadge = BadgeController.sharedController.nextBadgeForDistance(distance)

    if let upcomingBadge = upcomingBadge {
      if upcomingBadge.name! != nextBadge.name! {
        playSuccessSound(0)
      }
    }
    
    upcomingBadge = nextBadge
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if let detailViewController = segue.destinationViewController as? DetailViewController {
      detailViewController.run = run
    }
  }
    
    
    
    
    
}

// MARK: - MKMapViewDelegate
extension NewRunViewController: MKMapViewDelegate {
  func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer! {
    if !overlay.isKindOfClass(MKPolyline) {
      return nil
    }

    let polyline = overlay as! MKPolyline
    let renderer = MKPolylineRenderer(polyline: polyline)
    renderer.strokeColor = UIColor.blueColor()
    renderer.lineWidth = 3
    return renderer
  }
}

// MARK: - CLLocationManagerDelegate
extension NewRunViewController: CLLocationManagerDelegate {
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    for location in locations {
      let howRecent = location.timestamp.timeIntervalSinceNow

      if abs(howRecent) < 10 && location.horizontalAccuracy < 20 {
        //update distance
        if self.locations.count > 0 {
          distance += (location.distanceFromLocation(self.locations.last!))*0.000621371

          var coords = [CLLocationCoordinate2D]()
          coords.append(self.locations.last!.coordinate)
          coords.append(location.coordinate)

          let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500)
          mapView.setRegion(region, animated: true)

          mapView.addOverlay(MKPolyline(coordinates: &coords, count: coords.count))
        }

        //save location
        self.locations.append(location)
      }
    }
  }
}

// MARK: - UIActionSheetDelegate
extension NewRunViewController: UIActionSheetDelegate {
  func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
    //save
    if buttonIndex == 1 {
      saveRun()
      performSegueWithIdentifier(DetailSegueName, sender: nil)
    }
      //discard
    else if buttonIndex == 2 {
      navigationController?.popToRootViewControllerAnimated(true)
    }
  }
}
