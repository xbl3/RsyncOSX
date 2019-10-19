//
//  ViewControllerEdit.swift
//  RsyncOSXver30
//
//  Created by Thomas Evensen on 05/09/2016.
//  Copyright © 2016 Thomas Evensen. All rights reserved.
//
// swiftlint:disable line_length

import Foundation
import Cocoa

class ViewControllerRestore: NSViewController, SetConfigurations, Abort, Connected, Setcolor, VcMain, Checkforrsync {

    @IBOutlet weak var restoretable: NSTableView!
    @IBOutlet weak var working: NSProgressIndicator!
    @IBOutlet weak var gotit: NSTextField!

    @IBOutlet weak var transferredNumber: NSTextField!
    @IBOutlet weak var transferredNumberSizebytes: NSTextField!
    @IBOutlet weak var newfiles: NSTextField!
    @IBOutlet weak var deletefiles: NSTextField!
    @IBOutlet weak var totalNumber: NSTextField!
    @IBOutlet weak var totalDirs: NSTextField!
    @IBOutlet weak var totalNumberSizebytes: NSTextField!
    @IBOutlet weak var restorebutton: NSButton!
    @IBOutlet weak var tmprestore: NSTextField!
    @IBOutlet weak var selecttmptorestore: NSButton!
    @IBOutlet weak var checkbutton: NSButton!

    var index: Int?
    var maxcount: Int = 0
    var outputprocess: OutputProcess?
    var diddissappear: Bool = false
    weak var sendprocess: SendProcessreference?

    @IBAction func totinfo(_ sender: NSButton) {
        guard self.checkforrsync() == false else { return }
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerRemoteInfo!)
        })
    }

    @IBAction func quickbackup(_ sender: NSButton) {
        guard self.checkforrsync() == false else { return }
        self.openquickbackup()
    }

    @IBAction func automaticbackup(_ sender: NSButton) {
        self.presentAsSheet(self.viewControllerEstimating!)
    }

    // Selecting profiles
    @IBAction func profiles(_ sender: NSButton) {
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerProfile!)
        })
    }

    // Userconfiguration button
    @IBAction func userconfiguration(_ sender: NSButton) {
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerUserconfiguration!)
        })
    }

    @IBAction func restore(_ sender: NSButton) {
        guard self.checkforrsync() == false else { return }
        let question: String = NSLocalizedString("Do you REALLY want to start a RESTORE ?", comment: "Restore")
        let text: String = NSLocalizedString("Cancel or Restore", comment: "Restore")
        let dialog: String = NSLocalizedString("Restore", comment: "Restore")
        let answer = Alerts.dialogOrCancel(question: question, text: text, dialog: dialog)
        if answer {
            if let index = self.index {
                self.gotit.textColor = setcolor(nsviewcontroller: self, color: .white)
                let gotit: String = NSLocalizedString("Executing restore...", comment: "Restore")
                self.gotit.stringValue = gotit
                self.restorebutton.isEnabled = false
                self.outputprocess = OutputProcess()
                switch self.selecttmptorestore.state {
                case .on:
                    _ = RestoreTask(index: index, outputprocess: self.outputprocess, dryrun: false,
                                    tmprestore: true, updateprogress: self)
                case .off:
                    _ = RestoreTask(index: index, outputprocess: self.outputprocess, dryrun: false,
                                    tmprestore: false, updateprogress: self)
                default:
                    return
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.restoretable.delegate = self
        self.restoretable.dataSource = self
        ViewControllerReference.shared.setvcref(viewcontroller: .vcrestore, nsviewcontroller: self)
        self.sendprocess = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard self.diddissappear == false else { return }
        self.restorebutton.isEnabled = false
        self.checkbutton.isEnabled = false
        let setuserconfig: String = NSLocalizedString(" ... set in User configuration ...", comment: "Restore")
        self.tmprestore.stringValue = ViewControllerReference.shared.restorePath ?? setuserconfig
        if (ViewControllerReference.shared.restorePath ?? "").isEmpty == true {
            self.selecttmptorestore.state = .off
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.diddissappear = true
    }

    private func setNumbers(outputprocess: OutputProcess?) {
        globalMainQueue.async(execute: { () -> Void in
            let infotask = RemoteinfonumbersOnetask(outputprocess: outputprocess)
            self.transferredNumber.stringValue = infotask.transferredNumber!
            self.transferredNumberSizebytes.stringValue = infotask.transferredNumberSizebytes!
            self.totalNumber.stringValue = infotask.totalNumber!
            self.totalNumberSizebytes.stringValue = infotask.totalNumberSizebytes!
            self.totalDirs.stringValue = infotask.totalDirs!
            self.newfiles.stringValue = infotask.newfiles!
            self.deletefiles.stringValue = infotask.deletefiles!
            self.working.stopAnimation(nil)
            self.restorebutton.isEnabled = true
            self.gotit.textColor = self.setcolor(nsviewcontroller: self, color: .green)
            let gotit: String = NSLocalizedString("Got it...", comment: "Restore")
            self.gotit.stringValue = gotit
        })
    }

    @IBAction func prepareforrestore(_ sender: NSButton) {
        if let index = self.index {
            if self.connected(config: self.configurations!.getConfigurations()[index]) == true {
                self.gotit.textColor = setcolor(nsviewcontroller: self, color: .white)
                let gotit: String = NSLocalizedString("Getting info, please wait...", comment: "Restore")
                self.gotit.stringValue = gotit
                self.checkbutton.isEnabled = false
                self.working.startAnimation(nil)
                self.outputprocess = OutputProcess()
                self.sendprocess?.sendoutputprocessreference(outputprocess: self.outputprocess)
                if ViewControllerReference.shared.restorePath != nil && self.selecttmptorestore.state == .on {
                    _ = RestoreTask(index: index, outputprocess: self.outputprocess, dryrun: true,
                                    tmprestore: true, updateprogress: self)
                } else {
                    self.selecttmptorestore.state = .off
                    _ = RestoreTask(index: index, outputprocess: self.outputprocess, dryrun: true,
                                    tmprestore: false, updateprogress: self)
                }
            } else {
                self.gotit.stringValue = NSLocalizedString("Seems not to be connected...", comment: "Remote Info")
                self.gotit.textColor = self.setcolor(nsviewcontroller: self, color: .green)
            }
        }
    }

    // setting which table row is selected
    func tableViewSelectionDidChange(_ notification: Notification) {
        let myTableViewFromNotification = (notification.object as? NSTableView)!
        let indexes = myTableViewFromNotification.selectedRowIndexes
        if let index = indexes.first {
            self.checkbutton.isEnabled = true
            self.index = index
        } else {
            self.checkbutton.isEnabled = false
            self.index = nil
        }
        self.restorebutton.isEnabled = false
    }
}

extension ViewControllerRestore: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.configurations?.getConfigurationsDataSourceSynchronize()?.count ?? 0
    }
}

extension ViewControllerRestore: NSTableViewDelegate {

   func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard row < self.configurations!.getConfigurationsDataSourceSynchronize()!.count  else { return nil }
        let object: NSDictionary = self.configurations!.getConfigurationsDataSourceSynchronize()![row]
        switch tableColumn!.identifier.rawValue {
        case "offsiteServerCellID":
            if (object[tableColumn!.identifier] as? String)!.isEmpty {
                return "localhost"
            } else {
                return object[tableColumn!.identifier] as? String
            }
        default:
            return object[tableColumn!.identifier] as? String
        }
    }
}

extension ViewControllerRestore: UpdateProgress {
    func processTermination() {
        self.setNumbers(outputprocess: self.outputprocess)
        self.maxcount = self.outputprocess?.getMaxcount() ?? 0
    }

    func fileHandler() {
        weak var outputeverythingDelegate: ViewOutputDetails?
        outputeverythingDelegate = ViewControllerReference.shared.getvcref(viewcontroller: .vctabmain) as? ViewControllerMain
        if outputeverythingDelegate?.appendnow() ?? false {
            outputeverythingDelegate?.reloadtable()
        }
    }
}

extension ViewControllerRestore: OpenQuickBackup {
    func openquickbackup() {
        globalMainQueue.async(execute: { () -> Void in
            self.presentAsSheet(self.viewControllerQuickBackup!)
        })
    }
}

extension ViewControllerRestore: DismissViewController {
    func dismiss_view(viewcontroller: NSViewController) {
        self.dismiss(viewcontroller)
        globalMainQueue.async(execute: { () -> Void in
            self.restoretable.reloadData()
        })
    }
}

extension ViewControllerRestore: Count {
    func maxCount() -> Int {
        return self.maxcount
    }

    func inprogressCount() -> Int {
        return self.outputprocess?.count() ?? 0
    }
}
