//
//  ViewControllerBatch.swift
//  RsyncOSXver30
//
//  Created by Thomas Evensen on 25/08/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//

import Foundation
import Cocoa

protocol StartBatch : class  {
    // Starts batch run
    func runBatch()
    // ViewController is closed and values 
    // must be reset
    func abortOperations()
    // Close
    func closeOperation()
}


class ViewControllerBatch : NSViewController, RefreshtableViewBatch, StartStopProgressIndicatorViewBatch {
    
    var close:Bool?

    // Main tableview
    @IBOutlet weak var mainTableView: NSTableView!
    @IBOutlet weak var CloseButton: NSButton!
    @IBOutlet weak var working: NSProgressIndicator!
    @IBOutlet weak var label: NSTextField!
    
    // Iniate start of batchrun
    weak var startBatch_delegate:StartBatch?
    // Dismisser
    weak var dismiss_delegate:DismissViewController?

    // ACTIONS AND BUTTONS
    
    @IBAction func Close(_ sender: NSButton) {
        if (self.close!) {
            self.startBatch_delegate?.closeOperation()
        } else {
            self.startBatch_delegate?.abortOperations()
        }
        self.dismiss_delegate?.dismiss_view(viewcontroller: self)
    }
    
    // Execute batch
    @IBAction func Execute(_ sender: NSButton) {
        self.startBatch_delegate?.runBatch()
        self.CloseButton.title = "Abort"
        
    }
    
    // PROTOCOL FUNCTIONS

    // Protocol RefreshtableViewBatch
    func refreshInBatch() {
        GlobalMainQueue.async(execute: { () -> Void in
            self.mainTableView.reloadData()
        })
    }
    
    // Protocol StartStopProgressIndicatorViewBatch
    func stop() {
        self.working.stopAnimation(nil)
        self.label.stringValue = "Working"
    }
    
    func start() {
        self.close = false
        self.working.startAnimation(nil)
        self.label.stringValue = "Estimating"
    }

    func complete() {
        self.label.stringValue = "Completed"
        self.CloseButton.title = "Close"
        self.close = true
    }
    
    // Initial functions viewDidLoad and viewDidAppear
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        // Setting delegates and datasource
        self.mainTableView.delegate = self
        self.mainTableView.dataSource = self
        if (SharingManagerConfiguration.sharedInstance.batchDataQueuecount() > 0 ) {
            GlobalMainQueue.async(execute: { () -> Void in
                self.mainTableView.reloadData()
            })
        }
        if let pvc = self.presenting as? ViewControllertabMain {
            self.startBatch_delegate = pvc
        }
        // Dismisser is root controller
        if let pvc2 = self.presenting as? ViewControllertabMain {
            self.dismiss_delegate = pvc2
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.working.stopAnimation(nil)
        self.close = true
    }


}

extension ViewControllerBatch : NSTableViewDataSource {
        // Delegate for size of table
        func numberOfRows(in tableView: NSTableView) -> Int {
            return SharingManagerConfiguration.sharedInstance.batchDataQueuecount()
        }
}

extension ViewControllerBatch : NSTableViewDelegate {
    
    // TableView delegates
    @objc(tableView:objectValueForTableColumn:row:) func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
            let object : NSMutableDictionary = SharingManagerConfiguration.sharedInstance.getbatchDataQueue()![row]
            if ((tableColumn!.identifier) == "estimatedCellID" || (tableColumn!.identifier) == "completedCellID" ) {
                return object[tableColumn!.identifier] as? Int!
            } else {
                return object[tableColumn!.identifier] as? String
            }
    }
    
    // Toggling batch
    @objc(tableView:setObjectValue:forTableColumn:row:) func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        if (SharingManagerConfiguration.sharedInstance.getConfigurations()[row].task == "backup") {
            SharingManagerConfiguration.sharedInstance.getConfigurationsDataSource()![row].setObject(object!, forKey: (tableColumn?.identifier)! as NSCopying)
            SharingManagerConfiguration.sharedInstance.setBatchYesNo(row)
        }
    }
    
}
