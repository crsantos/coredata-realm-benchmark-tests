//
//  ViewController.swift
//  CRCoreDataStack
//
//  Created by Carlos Santos on 06/02/16.
//  Copyright © 2016 crsantos. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    // MARK: - Properties

    var people = [NSManagedObject]()

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Lifecycle

    override func viewDidLoad() {

        super.viewDidLoad()

        self.setupButtons()

        tableView.registerClass(UITableViewCell.self,
            forCellReuseIdentifier: "Cell")
    }

    override func viewWillAppear(animated: Bool) {

        super.viewWillAppear(animated)

        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate

        let managedContext = appDelegate.managedObjectContext

        let fetchRequest = NSFetchRequest(entityName: "Person")

        do{

            let results =
            try managedContext.executeFetchRequest(fetchRequest)
            people = results as! [Person]

        } catch let error as NSError {

            print("Could not fetch \(error), \(error.userInfo)")
        }
    }

    // MARK: - Private

    func setupButtons(){

        self.navigationItem.rightBarButtonItem =
            UIBarButtonItem.init(
                title: "Add",
                style: .Plain,
                target: self,
                action: "addName:")
        self.navigationItem.leftBarButtonItem =
            UIBarButtonItem.init(
                title: "Delete",
                style: .Plain,
                target: self,
                action: "deleteAllNames:")
    }

    // MARK: UITableViewDelegate / UITableViewDataSource

    func tableView(tableView: UITableView,
        numberOfRowsInSection section: Int) -> Int {
            return people.count
    }

    func tableView(tableView: UITableView,
        cellForRowAtIndexPath
        indexPath: NSIndexPath) -> UITableViewCell {

            let cell =
            tableView.dequeueReusableCellWithIdentifier("Cell")

            let person = people[indexPath.row]

            cell!.textLabel!.text =
                person.valueForKey("name") as? String

            return cell!
    }

    // Override to support conditional editing of the table view.
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    // Override to support editing the table view.
    func tableView(tableView: UITableView,
        commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath) {

        tableView.beginUpdates()
        if editingStyle == .Delete {
            // Delete the row from the data source
            let person = people.removeAtIndex(indexPath.row)
            deleteName(person)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)

        }
        tableView.endUpdates()
    }

    //Implement the addName IBAction
    func addName(sender: AnyObject) {

        let uuid = NSUUID().UUIDString
        self.saveName(uuid)
        self.tableView.reloadData()

        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            let lastOne = self.tableView.numberOfRowsInSection(0)
            let indexPath = NSIndexPath.init(forItem: lastOne - 1, inSection: 0)
            self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
        }
    }

    func deleteName(person: NSManagedObject) {

        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate

        let managedContext = appDelegate.managedObjectContext

        managedContext.deleteObject(person)

        do {
            try managedContext.save()

        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }

    func saveName(name: String) {

        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate

        let managedContext = appDelegate.managedObjectContext

        let entity =  NSEntityDescription.entityForName("Person",
            inManagedObjectContext:managedContext)

        let person:NSManagedObject = NSManagedObject(entity: entity!,
            insertIntoManagedObjectContext: managedContext)

        person.setValue(name, forKey: "name")

        do {
            try managedContext.save()
            people.append(person)
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }

    func deleteAllNames(sender: AnyObject){

        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate

        let managedContext = appDelegate.managedObjectContext

        let fetchRequest = NSFetchRequest(entityName: "Person")

        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try managedContext.executeRequest(deleteRequest)
            try managedContext.save()
            people.removeAll()
            tableView.reloadData()
        } catch {
            print (error)
        }
    }
}
