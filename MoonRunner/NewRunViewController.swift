import UIKit
import CoreData
import CoreLocation
import HealthKit
import MapKit
import AudioToolbox


let DetailSegueName = "RunDetails"

class NewRunViewController: UIViewController {
  var managedObjectContext: NSManagedObjectContext?

  var run: Run!

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

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    startButton.hidden = false
    promptLabel.hidden = false

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
    let distanceQuantity = HKQuantity(unit: HKUnit.meterUnit(), doubleValue: distance)
    distanceLabel.text = "Distance: " + distanceQuantity.description

    let paceUnit = HKUnit.secondUnit().unitDividedByUnit(HKUnit.meterUnit())
    let paceQuantity = HKQuantity(unit: paceUnit, doubleValue: seconds / distance)
    paceLabel.text = "Pace: " + paceQuantity.description

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
    func takeSnapshot(mapView: MKMapView,imageName: String, withCallback: (UIImage?, NSError?) -> ()) {
        let options = MKMapSnapshotOptions()
        options.region = mapView.region
        options.size = mapView.frame.size
        options.scale = UIScreen.mainScreen().scale
        
        //let fileURL = NSURL(fileURLWithPath: "image.png")
        
        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.startWithCompletionHandler { snapshot, error in
            guard let snapshot = snapshot else {
                print("Snapshot error: \(error)")
                return
            }
            /*
            let data = UIImagePNGRepresentation(snapshot.image)
            let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.PicturesDirectory, inDomains: .UserDomainMask)[0]
            let fileURL = documentsURL.URLByAppendingPathComponent("image.png")
            data?.writeToURL(fileURL, atomically: true)
            print("Done  \(fileURL)")
             */         let pin = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
            let image = snapshot.image
            
            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
            image.drawAtPoint(CGPoint.zero)
            
            let visibleRect = CGRect(origin: CGPoint.zero, size: image.size)
            for annotation in mapView.annotations {
                var point = snapshot.pointForCoordinate(annotation.coordinate)
                if visibleRect.contains(point) {
                    point.x = point.x + pin.centerOffset.x - (pin.bounds.size.width / 2)
                    point.y = point.y + pin.centerOffset.y - (pin.bounds.size.height / 2)
                    pin.image?.drawAtPoint(point)
                }
            }
            
            let compositeImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            let data = UIImagePNGRepresentation(compositeImage)
            let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
            let fileURL = documentsURL.URLByAppendingPathComponent("image.png")
            data?.writeToURL(fileURL, atomically: true)
            print(fileURL)
        }
       /*
        snapshotter.startWithQueue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { snapshot, error in
            guard let snapshot = snapshot else {
                print("Snapshot error: \(error)")
                fatalError()
            }
            
            
        }
 */
        
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
    takeSnapshot(mapView, imageName: String("image")){ (image, error) -> () in
        guard image != nil else {
            print(error)
            return
        }
    var error: NSError?
    let success: Bool
    do {
      try self.managedObjectContext!.save()
      success = true
    } catch let error1 as NSError {
      error = error1
      success = false
    }
    if !success {
      print("Could not save the run!")
    }
    
  }
    }
    
    @IBAction func startPressed(sender: AnyObject) {
    startButton.hidden = true
    promptLabel.hidden = true

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

  func playSuccessSound() {
    let soundURL = NSBundle.mainBundle().URLForResource("success", withExtension: "wav")
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
        playSuccessSound()
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
          distance += location.distanceFromLocation(self.locations.last!)

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
