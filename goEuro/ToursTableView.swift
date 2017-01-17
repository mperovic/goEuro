//
//  ToursTableView.swift
//  goEuro
//
//  Created by Miroslav Perovic on 1/14/17.
//  Copyright © 2017 Miroslav Perovic. All rights reserved.
//

import Foundation
import UIKit
import Nuke

extension ViewController: UITableViewDelegate, UITableViewDataSource {	
	func numberOfSections(in tableView: UITableView) -> Int {
		guard let sections = fetchedResultsController.sections else { return 0 }
		
		return sections.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let sectionInfo = fetchedResultsController.sections?[section] else { return 0 }
		
		return sectionInfo.numberOfObjects
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "TravelCell", for: indexPath)
		configure(cell: cell, for: indexPath)

		return cell
	}

	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let sectionInfo = fetchedResultsController.sections?[section]
		return sectionInfo?.name
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let alertController = UIAlertController(
			title: "goEuro",
			message: "Offer details are not yet implemented!",
			preferredStyle: .alert
		)
		let action = UIAlertAction(title: "OK", style: .default, handler: nil)
		alertController.addAction(action)
		DispatchQueue.main.async {
			self.present(
				alertController,
				animated: false,
				completion: nil
			)
		}
	}
}

// MARK: - Internal
extension ViewController {
	func configure(cell: UITableViewCell, for indexPath: IndexPath) {
		guard let cell = cell as? TravelCell else { return }
		
		let tour = fetchedResultsController.object(at: indexPath)
		
		// Price
		let price = Double(tour.price_in_euros!)?.format(f: ".2")
		cell.price?.text = "€\(price!)"
		Nuke.loadImage(with: URL(string: tour.provider_logo!)!, into: cell.logo!)
		
		let calendar = Calendar.current
		// Departure
		let departureDate = tour.departure_time
		let departureHour = String(format: "%02d", calendar.component(.hour, from: departureDate as! Date))
		let departureMinutes = String(format: "%02d", calendar.component(.minute, from: departureDate as! Date))
		
		// Arrival
		let arrivalDate = tour.arrival_time
		let arrivalHour = String(format: "%02d", calendar.component(.hour, from: arrivalDate as! Date))
		let arrivalMinutes = String(format: "%02d", calendar.component(.minute, from: arrivalDate as! Date))

		cell.travelTime?.text = "\(departureHour):\(departureMinutes) - \(arrivalHour):\(arrivalMinutes)"
		
		switch tour.number_of_stops {
		case 0:
			cell.numberOfChanges?.text = "Direct"
			
		case 1:
			cell.numberOfChanges?.text = "1 Change"
			
		default:
			cell.numberOfChanges?.text = "\(tour.number_of_stops) Changes"
		}
		
		let (h, m, _) = secondsToHoursMinutesSeconds (seconds: Int(tour.duration))
		cell.duration?.text = String(format: "%02d", h) + ":" + String(format: "%02d", m)
	}

	func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
		return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
	}
}

extension ViewController: UIScrollViewDelegate {
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		self.contentOffsets[(self.segmentControl?.selectedSegmentIndex)!] = scrollView.contentOffset
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		self.contentOffsets[(self.segmentControl?.selectedSegmentIndex)!] = scrollView.contentOffset
	}
}
