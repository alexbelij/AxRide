//
//  MainDriverViewController.swift
//  AxRide
//
//  Created by Administrator on 7/19/18.
//  Copyright © 2018 Administrator. All rights reserved.
//

import UIKit
import GoogleMaps
import GeoFire
import Firebase

class MainDriverViewController: BaseHomeViewController {
    
    @IBOutlet weak var mSwitch: UISwitch!
    @IBOutlet weak var mViewInfo: UIView!
    
    @IBOutlet weak var mViewPanel: UIView!
    
    var mqueryRequest: DatabaseReference?
    var mUserIds: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        mViewInfo.makeRound(r: 16)
        mSwitch.transform = CGAffineTransform(scaleX: 0.7, y: 0.7);
        
        // empty title
        self.navigationItem.title = " "
        
        let userCurrent = User.currentUser!
        
        // broken state
        self.mSwitch.setOn(!userCurrent.broken, animated: false)
        
        // wait for user request
        mqueryRequest = FirebaseManager.ref().child(Order.TABLE_NAME_ACCEPT).child(userCurrent.id)
        mqueryRequest?.observe(.childAdded, with: { (snapshot) in
            if !snapshot.exists() {
                return
            }
            
            //
            // a request has been added
            //
//            if !userCurrent.accepted {
//                // not approved driver
//                self.alertOk(title: "Not approved yet",
//                             message: "Your driver account should be accepted by Admin",
//                             cancelButton: "OK",
//                             cancelHandler: nil)
//                return
//            }
            
            let userId = snapshot.key
            
            // popup request page
            let requestVC = JobRequestViewController(nibName: "JobRequestViewController", bundle: nil)
            requestVC.userId = userId
            requestVC.parentVC = self
            
            let nav = UINavigationController(rootViewController: requestVC)
            self.present(nav, animated: true, completion: nil)
        })
        
        // fetch current order
        getOrderInfo()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        showNavbar(show: false)
        
        //
        // check banned
        //
        
    }
    
    deinit {
        // remove observers
        mqueryRequest?.removeAllObservers()
    }
    
    func setOrder(_ order: Order?) {
        mOrder = order
        
        updateOrder()
    }
    
    override func updateOrder() {
        super.updateOrder()
        
        // in order
        if let order = mOrder {
            mViewInfo.isHidden = true
            mViewPanel.isHidden = false
            
            // fetch driver
            if order.customer == nil {
                User.readFromDatabase(withId: order.customerId) { (user) in
                    order.customer = user
                    
                    self.showLoadingView(show: false)
                }
            }
            else {
                showLoadingView(show: false)
            }
        }
        else {
            mViewInfo.isHidden = false
            mViewPanel.isHidden = true
        }
    }
    
    @IBAction func onSwitchChanged(_ sender: Any) {
        let userCurrent = User.currentUser!
        
        userCurrent.broken = !mSwitch.isOn
        userCurrent.saveToDatabase(withField: User.FIELD_BROKEN, value: userCurrent.broken)
    }
    
    @IBAction func onButComplete(_ sender: Any) {
    }
    
    @IBAction func onButChat(_ sender: Any) {
    }
    
    @IBAction func onButCancel(_ sender: Any) {
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    /// Called when location has updated
    ///
    /// - Parameters:
    ///   - location: <#location description#>
    ///   - updateForce: <#updateForce description#>
    /// - Returns: <#return value description#>
    override func showMyLocation(location: CLLocationCoordinate2D?, updateForce: Bool = false) -> Bool {
        
        let _ = super.showMyLocation(location: location, updateForce: updateForce)
        
        guard let l = location else {
            return false
        }
        
        let cLoc = CLLocation(latitude: l.latitude, longitude: l.longitude)
        
        // update location driver status
        let driverStatusRef = FirebaseManager.ref().child(DriverStatus.TABLE_NAME)
        let geoFire = GeoFire(firebaseRef: driverStatusRef)
        geoFire.setLocation(cLoc, forKey: User.currentUser!.id)
        
        return true
    }

}
