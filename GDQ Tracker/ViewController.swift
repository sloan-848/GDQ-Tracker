//
//  ViewController.swift
//  GDQ Tracker
//
//  Created by Will Sloan on 7/4/16.
//  Copyright © 2016 Will Sloan. All rights reserved.
//

import UIKit
import Fuzi
import Alamofire

class ViewController: UIViewController {

    @IBOutlet var currentGameLabel: UILabel?
    @IBOutlet var currentTimeStartLabel: UILabel?
    @IBOutlet var currentTimeEndLabel: UILabel?
    @IBOutlet var nextGameLabel: UILabel?
    @IBOutlet var nextTimeStartLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.startUpdate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func reloadData() {
        self.startUpdate()
    }
    
    func startUpdate() {
        // Kick off Network request and parsing logic
        Alamofire.request(.GET, "https://gamesdonequick.com/tracker/runs/sgdq2016")
            .validate()
            .responseString { response in
                let results = self.parseHTML(response.result.value!)
                self.updateGameUI(results)
        }
    }
    
    func updateGameUI(data: [String:String]) {
        print("Updating UI")
        dispatch_async(dispatch_get_main_queue(), {
            self.currentGameLabel!.text = data["currentName"]
            self.currentTimeStartLabel!.text = data["currentStartTime"]
            self.currentTimeEndLabel!.text = data["currentEndTime"]
            self.nextGameLabel!.text = data["nextName"]
            self.nextTimeStartLabel!.text = data["nextStartTime"]
            
        })
    }
    
    func parseHTML(data: String) -> [String:String] {
        var returnData = [String:String]()
        
        do {
            let doc = try HTMLDocument(string: data, encoding: NSUTF8StringEncoding)

            /* Initalize utility tracking variable */
            var foundFirst = false
            
            /* Initialize Date Formatters for Input and Output */
            let dateWriter = NSDateFormatter()
            dateWriter.setLocalizedDateFormatFromTemplate("hh:mm")
            
            let incomingDateParser = NSDateFormatter()
            incomingDateParser.dateFormat = "MM/dd/yyyy HH:mm:ss +0000"
            incomingDateParser.timeZone = NSTimeZone(abbreviation: "UTC")
            
            /* Iterate through all elements on the table containing game info */
            for element in (doc.root!.firstChild(tag: "body")?.children[3].firstChild(tag: "table")?.children)! {
                /* Skip Header */
                if (element.tag == "thead") {
                    continue
                }
                
                /* Parse name, players, Start Time and Ending Time from HTML */
                let name = element.children[0].children[0].stringValue.stringByTrimmingCharactersInSet(
                    NSCharacterSet.whitespaceAndNewlineCharacterSet()
                )
                let players = element.children[1].stringValue.stringByTrimmingCharactersInSet(
                    NSCharacterSet.whitespaceAndNewlineCharacterSet()
                )

                let startTime = element.children[3].stringValue.stringByTrimmingCharactersInSet(
                    NSCharacterSet.whitespaceAndNewlineCharacterSet()
                )

                let endTime = element.children[4].stringValue.stringByTrimmingCharactersInSet(
                    NSCharacterSet.whitespaceAndNewlineCharacterSet()
                )
            
                /* No need to parse new time, since all time comparisons are donw with UTC */
                let parseStartDate = incomingDateParser.dateFromString(startTime)
                let parseEndDate = incomingDateParser.dateFromString(endTime)
                let currentDate = NSDate()
                
                /* Compare game's time to current time to decide if this is the currently running game */
                if (parseStartDate?.timeIntervalSince1970 < currentDate.timeIntervalSince1970 &&
                        parseEndDate?.timeIntervalSince1970 > currentDate.timeIntervalSince1970) {
                    returnData["currentName"] = name
                    returnData["currentPlayers"] = players
                    returnData["currentStartTime"] = dateWriter.stringFromDate(parseStartDate!)
                    returnData["currentEndTime"] = dateWriter.stringFromDate(parseEndDate!)
                    foundFirst = true
                }
                /* After current game is found, we will also grab the next game's information */
                else if (foundFirst){
                    returnData["nextName"] = name
                    returnData["nextPlayers"] = players
                    returnData["nextStartTime"] = dateWriter.stringFromDate(parseStartDate!)
                    returnData["nextEndTime"] = dateWriter.stringFromDate(parseEndDate!)
                    
                    /* After finding the current game and the next game, stop iterating through the games */
                    break
                }
                
            }
        } catch let error {
            print(error)
        }
        
        return returnData
    }

}

