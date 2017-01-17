//
//  DownloadAndParseData.swift
//  goEuro
//
//  Created by Miroslav Perovic on 1/14/17.
//  Copyright © 2017 Miroslav Perovic. All rights reserved.
//

import UIKit
import CoreData

struct TravelData {
	var type: TravelType
	var url: String
}

let flights = TravelData(type: .flights, url: "https://api.myjson.com/bins/w60i")
let trains = TravelData(type: .trains, url: "https://api.myjson.com/bins/3zmcy")
let buses = TravelData(type: .buses, url: "https://api.myjson.com/bins/37yzm")

extension ViewController {
	func getCoreData(_ type: String) -> [Travel] {
		return getTravels(type)
	}
	
	func getData() {
		self.getData(trains)
		self.getData(buses)
		self.getData(flights)
	}
	
	fileprivate func getData(_ travelData: TravelData) {
		let data = self.getJSON(urlToRequest: travelData.url)
		if let array = self.parseJSON(inputData: data) as? Array<NSDictionary> {
			self.deleteOldData(travelData.type.rawValue)
			self.coreDataStack.persistentContainer.performBackgroundTask { (context) in
				context.automaticallyMergesChangesFromParent = true
				for dict in array {
					let travel = self.createRecordForEntity(entity: "Travel", inManagedObjectContext: context) as! Travel
					travel.id = dict["id"]! as! Int64
					let provider_logo = dict["provider_logo"] as! String
					travel.provider_logo = provider_logo.replacingOccurrences(of: "{size}", with: "63")
					if travelData.type == .flights {
						travel.price_in_euros = dict["price_in_euros"] as? String
					} else {
						travel.price_in_euros = String(describing: dict["price_in_euros"] as! Double)
					}
					travel.departure_time = self.convertStringToTime(dict["departure_time"] as! String) as NSDate?
					travel.arrival_time = self.convertStringToTime(dict["arrival_time"] as! String) as NSDate?
					if (travel.arrival_time as! Date) < (travel.departure_time as! Date) {
						self.fixDate(travel: travel)
					}
					travel.number_of_stops = dict["number_of_stops"] as! Int16
					travel.duration = Int64(travel.arrival_time!.timeIntervalSince(travel.departure_time as! Date))
					travel.type = travelData.type.rawValue
				}
				
				context.perform {
					do {
						try context.save()
						self.coreDataStack.saveContext()
						
						if self.fetchedResultsController.fetchRequest.predicate?.predicateFormat == "type == \"" + travelData.type.rawValue + "\"" {
							do {
								try self.fetchedResultsController.performFetch()
								DispatchQueue.main.async {
									self.tableView?.reloadData()
								}
							} catch let error as NSError {
								print("Fetching error: \(error), \(error.userInfo)")
							}
						}
					} catch let error as NSError {
						fatalError("Error: \(error.localizedDescription)")
					}
				}
			}
		}
	}
	
	fileprivate func convertStringToDecimal(_ str: String) -> NSDecimalNumber {
		let formatter = NumberFormatter()
		formatter.generatesDecimalNumbers = true
		
		return formatter.number(from: str) as? NSDecimalNumber ?? 0
	}
	
	fileprivate func convertStringToTime(_ str: String) -> Date {
		var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
		dateComponents.calendar = NSCalendar.current
		let stringComponents = str.components(separatedBy: ":")
		dateComponents.hour = Int(stringComponents[0])
		dateComponents.minute = Int(stringComponents[1])
		dateComponents.second = 0
		
		return dateComponents.date!
	}
	
	fileprivate func fixDate(travel: Travel) {
		var dayComponent = DateComponents()
		dayComponent.day = 1
		
		let nextDay = Calendar.current.date(byAdding: dayComponent, to: (travel.arrival_time as! Date))
		travel.arrival_time = nextDay as NSDate?
	}
	
	fileprivate func getJSON(urlToRequest: String) -> NSData {
		return NSData(contentsOf: NSURL(string: urlToRequest) as! URL)!
	}
	
	fileprivate func parseJSON(inputData: NSData) -> Any? {
		do {
			let boardsDictionary = try JSONSerialization.jsonObject(with: inputData as Data, options: JSONSerialization.ReadingOptions.mutableContainers)
			
			return boardsDictionary
		} catch {
			return nil
		}
	}

	internal func createRecordForEntity(entity: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext) -> NSManagedObject? {
		var result: NSManagedObject? = nil
		
		let entityDescription = NSEntityDescription.entity(forEntityName: entity, in: managedObjectContext)
		
		if let entityDescription = entityDescription {
			result = NSManagedObject(entity: entityDescription, insertInto: managedObjectContext)
		}
		
		return result
	}
	
	private func fetchRecordsForEntity(entity: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) -> [NSManagedObject] {
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
		fetchRequest.predicate = predicate
		fetchRequest.sortDescriptors = sortDescriptors
		
		var result = [NSManagedObject]()
		
		do {
			let records = try managedObjectContext.fetch(fetchRequest)
			
			if let records = records as? [NSManagedObject] {
				result = records
			}
		} catch {
			print("Unable to fetch managed objects for entity \(entity).")
		}
		
		return result
	}
	
	fileprivate func deleteOldData(_ type: String) {
		let travels = self.getTravels(type)
		for travel in travels {
			self.coreDataStack.mainContext.delete(travel)
		}
	}
	
	fileprivate func getTravels(_ type: String) -> [Travel] {
		var result: [Travel] = []
		
		guard let model = self.coreDataStack.mainContext.persistentStoreCoordinator?.managedObjectModel, let fetchRequest = model.fetchRequestTemplate(forName: "Get\(type)") as? NSFetchRequest<Travel> else { return result }
		
		do {
			result = try self.coreDataStack.mainContext.fetch(fetchRequest)
		} catch {
			print("No data.")
		}
		
		return result
	}
}
