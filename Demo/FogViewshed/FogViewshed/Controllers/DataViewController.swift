import UIKit
import MapKit

class DataViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var gpsButton: UIButton!
    
    var locationManager: CLLocationManager!
    var isInitialAuthorizationCheck = false
    let arrowPressedImg = UIImage(named: "ArrowPressed")! as UIImage
    let arrowImg = UIImage(named: "Arrow")! as UIImage
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.backgroundColor = UIColor.clearColor();
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.mapView.delegate = self
        
        let onPressGesture = UILongPressGestureRecognizer(target: self, action:#selector(DataViewController.onPress(_:)))
        onPressGesture.minimumPressDuration = 0.15
        mapView.addGestureRecognizer(onPressGesture)
        
        if (self.locationManager == nil) {
            self.locationManager = CLLocationManager()
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.delegate = self
        }
        let status = CLLocationManager.authorizationStatus()
        if (status == .NotDetermined || status == .Denied || status == .Restricted)  {
            // present an alert indicating location authorization required
            // and offer to take the user to Settings for the app via
            self.locationManager.requestWhenInUseAuthorization()
            self.mapView.tintColor = UIColor.blueColor()
        }
        gpsButton.setImage(arrowPressedImg, forState: UIControlState.Normal)
        redraw()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func focusToCurrentLocation(sender: AnyObject) {
        gpsButton.setImage(arrowPressedImg, forState: UIControlState.Normal)
        
        if let coordinate = mapView.userLocation.location?.coordinate {
            // Get the span that the mapView is set to by the user.
            let span = self.mapView.region.span
            // Now setup the region based on the lat/lon and retain the span that already exists.
            let region = MKCoordinateRegion(center: coordinate, span: span)
            //Center the view with some animation.
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        let view = self.mapView.subviews[0]
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if( recognizer.state == UIGestureRecognizerState.Began || recognizer.state == UIGestureRecognizerState.Ended ) {
                    gpsButton.setImage(arrowImg, forState: UIControlState.Normal)
                }
            }
        }
    }
    
    // MARK: - Location Delegate Methods
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if (status == .AuthorizedWhenInUse || status == .AuthorizedAlways) {
            self.locationManager.startUpdatingLocation()
            self.isInitialAuthorizationCheck = true
            self.mapView.showsUserLocation = true
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error: " + error.localizedDescription)
    }
   
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let dataCell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("dataCell", forIndexPath: indexPath)
        dataCell.textLabel!.text = HGTManager.getLocalHGTFiles()[indexPath.row].filename
        dataCell.tag = indexPath.row
        return dataCell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return HGTManager.getLocalHGTFiles().count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let currentCell = tableView.cellForRowAtIndexPath(indexPath)! as UITableViewCell
        
        let hgtFile:HGTFile = HGTManager.getLocalHGTFiles()[currentCell.tag]
        pinAnnotation("Delete " + hgtFile.filename + "?", coordinate:hgtFile.getBoundingBox().getCentroid())
    }
    
    
    func drawDataRegions() {
        var dataRegionOverlays = [MKOverlay]()
        for overlay in mapView.overlays {
            if overlay is MKPolygon {
                dataRegionOverlays.append(overlay)
            }
        }
        mapView.removeOverlays(dataRegionOverlays)
        
        for hgtFile in HGTManager.getLocalHGTFiles() {
            self.mapView.addOverlay(hgtFile.getBoundingBox().asMKPolygon())
        }
    }
    
    func redraw() {
        self.mapView.removeAnnotations(mapView.annotations)
        drawDataRegions()
    }
    
    func refresh() {
        redraw()
        self.tableView?.reloadData()
    }
    
    func pinAnnotation(title: String, subtitle: String = "", coordinate: CLLocationCoordinate2D) {
        // remove all the annotations on the map
        self.mapView.removeAnnotations(mapView.annotations)
        
        // Now setup the region based on the lat/lon and retain the span that already exists.
        let region = MKCoordinateRegion(center: coordinate, span: self.mapView.region.span)
        //Center the view with some animation.
        self.mapView.setRegion(region, animated: true)
        
        let pointAnnotation:MKPointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = coordinate
        pointAnnotation.title = title
        pointAnnotation.subtitle = subtitle
        self.mapView.addAnnotation(pointAnnotation)
    }

    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let defaultOverlay = MKPolygonRenderer()
        if overlay is MKPolygon {
            let polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView.lineWidth = 0.5
            polygonView.fillColor = UIColor.yellowColor().colorWithAlphaComponent(0.4)
            polygonView.strokeColor = UIColor.redColor().colorWithAlphaComponent(0.6)

            return polygonView
        }
        return defaultOverlay
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        // if the annotation is dragged to a different location, handle it
        if newState == MKAnnotationViewDragState.Ending {
            //let droppedAt = view.annotation?.coordinate
            let annotation = view.annotation!
            let title:String = ((view.annotation?.title)!)!
            self.pinAnnotation(title, coordinate: annotation.coordinate)
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var view : MKAnnotationView! = nil
        let t: String = String(annotation.title)
        if (annotation is MKUserLocation) {
            //if annotation is not an MKPointAnnotation (eg. MKUserLocation),
            //return nil so map draws default view for it (eg. blue dot)...
            //let identifier = "downloadFile"
            //view = self.mapViewCalloutAccessoryAction("Download", annotation: annotation, identifier: identifier)
            return nil
        } else if (t.containsString("Download")) {
            let identifier = "downloadFile"
            view = self.mapViewCalloutAccessoryAction("Download", annotation: annotation, identifier: identifier)
        } else {
            let identifier = "deleteFile"
            view = self.mapViewCalloutAccessoryAction("Delete", annotation: annotation, identifier: identifier)
        }
        return view
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let annotation = view.annotation!
        let filename:String = HGTFile.coordinateToFilename(annotation.coordinate, resolution: Srtm.SRTM3_RESOLUTION)
        
        if view.reuseIdentifier == "downloadFile" {
            self.initiateDownload(filename)
        } else if view.reuseIdentifier == "deleteFile" {
            if let hgtFile = HGTManager.getLocalHGTFileByName(filename) {
                self.initiateDelete(hgtFile)
            }
        }
    }
    
    func mapViewCalloutAccessoryAction(calloutAction: String, annotation: MKAnnotation, identifier: String)-> MKAnnotationView? {
        var view : MKAnnotationView! = nil
        view = self.mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            
            let image = UIImage(named:calloutAction)
            let button = UIButton(type: UIButtonType.DetailDisclosure)
            button.setImage(image, forState: UIControlState.Normal)
            view!.leftCalloutAccessoryView = button as UIView
        }
        return view
    }
    
    func initiateDelete(hgtfile: HGTFile) {
        let alertController = UIAlertController(title: "Delete " + hgtfile.filename + "?", message: "", preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Default, handler: {
            (action) -> Void in
            HGTManager.deleteFile(hgtfile)
            self.refresh()
        })
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel) {
            (action) -> Void in
        }
        alertController.addAction(ok)
        alertController.addAction(cancel)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func initiateDownload(filename: String) {
        ActivityIndicator.show("Downloading " + filename)
        let hgtDownloader:HGTDownloader = HGTDownloader(onDownload: { path in
            
            dispatch_async(dispatch_get_main_queue()) {
                () -> Void in
                ActivityIndicator.hide(success: true, animated: true)
                self.refresh()
            }
            
            }, onError: { filename in
                ActivityIndicator.hide(success: false, animated: true, errorMsg: "Could not retrive file")
        })
        hgtDownloader.downloadFile(filename)
    }
    
    func didFailToReceieveResponse(error: String) {
        ActivityIndicator.hide(success: false, animated: true, errorMsg: error)
        print("\(error)")
    }
    
    func onPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.Began {

            let filename:String = HGTFile.coordinateToFilename(mapView.convertPoint(gestureRecognizer.locationInView(mapView), toCoordinateFromView: mapView), resolution: Srtm.SRTM3_RESOLUTION)
            if let hgtFile = HGTManager.getLocalHGTFileByName(filename) {
                pinAnnotation("Delete " + hgtFile.filename + "?", coordinate:hgtFile.getBoundingBox().getCentroid())
            } else {
                let srtmDataRegion:String = HGTRegions().getRegion(filename)
                if (srtmDataRegion.isEmpty == false) {
                    pinAnnotation("Download elevation data?", subtitle: filename, coordinate:mapView.convertPoint(gestureRecognizer.locationInView(mapView), toCoordinateFromView: mapView))
                } else {
                    var style = ToastStyle()
                    style.messageColor = UIColor.redColor()
                    style.backgroundColor = UIColor.whiteColor()
                    style.messageFont = UIFont(name: "HelveticaNeue", size: 16)
                    self.view.makeToast("No data available here.", duration: 1.5, position: .Center, style: style)
                }
            }
        }
    }
}


