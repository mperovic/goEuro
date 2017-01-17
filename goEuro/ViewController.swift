//
//  ViewController.swift
//  goEuro
//
//  Created by Miroslav Perovic on 1/14/17.
//  Copyright © 2017 Miroslav Perovic. All rights reserved.
//

import UIKit
import ReachabilitySwift
import CoreData
import Nuke
import DFCache

let kScreenWidth: CGFloat = UIScreen.main.bounds.size.width
let kScreenHeight: CGFloat = UIScreen.main.bounds.size.height

enum SortOrder: Int {
	case departure, arrival, duration
	
	func toCoreDataSort() -> NSSortDescriptor {
		switch self {
		case .departure:
			return NSSortDescriptor(
				key: #keyPath(Travel.departure_time),
				ascending: true
			)
			
		case .arrival:
			return NSSortDescriptor(
				key: #keyPath(Travel.arrival_time),
				ascending: true
			)
			
		case .duration:
			return NSSortDescriptor(
				key: #keyPath(Travel.duration),
				ascending: true
			)
		}
	}
}

enum TravelType: String {
	case flights = "Flights"
	case trains = "Trains"
	case buses = "Buses"

	func toCoreDataPredicate() -> NSPredicate {
		return NSPredicate(format: "type == %@", self.rawValue)
	}
}


final class ViewController: UIViewController, MPSegmentControlDelegate, MPSegmentControlCellStateDelegate {
	@IBOutlet weak var segmentControl: MPSegmentedControl?
	@IBOutlet weak var errorConnectionViewBottomLayoutConstraint: NSLayoutConstraint?
	@IBOutlet weak var errorView: UIView?
	@IBOutlet weak var errorLabel: UILabel?
	@IBOutlet weak var activity: UIActivityIndicatorView?
	@IBOutlet weak var tableView: UITableView?
	@IBOutlet weak var dateLabel: UILabel?

	var contentOffsets = [CGPoint.zero, CGPoint.zero, CGPoint.zero]		// Store tableView content offset

	var fetchedResultsController : NSFetchedResultsController<Travel>!
	var coreDataStack: CoreDataStack {
		get {
			return (UIApplication.shared.delegate as! AppDelegate).coreDataStack
		}
	}

	var reachability: Reachability?

	private let borderColor: UIColor = UIColor(hue: 1, saturation: 0, brightness: 1, alpha: 0.5)
	private let backgroundColor: UIColor = UIColor(hue: 1, saturation: 0, brightness: 1, alpha: 0.08)
	let blueColor = UIColor(red: 22/255, green: 98/255, blue: 161/255, alpha: 1.0)
	
	override func awakeFromNib() {
		super.awakeFromNib()
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle {
		return .lightContent
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		let fetchRequest: NSFetchRequest<Travel> = Travel.fetchRequest()
		fetchRequest.sortDescriptors = [SortOrder.departure.toCoreDataSort()]
		fetchRequest.predicate = TravelType.trains.toCoreDataPredicate()
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
		                                                      managedObjectContext: coreDataStack.mainContext,
		                                                      sectionNameKeyPath: nil,
		                                                      cacheName: nil)
		fetchedResultsController.delegate = self

		self.segmentControl?.layer.borderColor = self.borderColor.cgColor
		self.segmentControl?.backgroundColor = self.backgroundColor
		self.segmentControl?.stateDelegate = self
		self.segmentControl?.delegate = self
		
		self.segmentControl?.insertSegment(withTitle: "Train", andImage: #imageLiteral(resourceName: "Transport-Train"), at: 0, animated: true)
		self.segmentControl?.insertSegment(withTitle: "Bus", andImage: #imageLiteral(resourceName: "Transport-Bus"), at: 1, animated: true)
		self.segmentControl?.insertSegment(withTitle: "Flight", andImage: #imageLiteral(resourceName: "Transport-Airplane"), at: 2, animated: true)
		
		// Start reachability without a hostname intially
		setupReachability("myjson.com", useClosures: true)
		startNotifier()
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "MMM dd"
		self.dateLabel?.text = dateFormatter.string(from: Date())
		
		self.tableView?.delegate = self
		if self.reachability?.currentReachabilityStatus == .notReachable {
			// Load data from persistant storage
			do {
				try fetchedResultsController.performFetch()
			} catch let error as NSError {
				print("Fetching error: \(error), \(error.userInfo)")
			}
		} else {
			// Get data from server
			DispatchQueue.global().async {
				self.getData()
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	deinit {
		stopNotifier()
	}

	
	fileprivate func showConnectionWarning(_ message: String, showActivityIndicator show: Bool = false) {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.5, animations: { () -> Void in
				self.errorLabel?.text = message
				self.activity?.isHidden = !show
				if show {
					self.activity?.startAnimating()
				}
				self.errorView?.isHidden = false
				self.errorView?.frame.origin.y = kScreenHeight + 44.0
				self.errorConnectionViewBottomLayoutConstraint?.constant =  44.0
				self.errorView?.updateConstraints()
			})
		}
	}
	
	fileprivate func hideConnectionWarning() {
		DispatchQueue.main.async {
			UIView.animate(withDuration: 0.5, animations: { () -> Void in
				self.activity?.stopAnimating()
				self.errorView?.frame.origin.y = kScreenHeight
				self.errorConnectionViewBottomLayoutConstraint?.constant = 0.0
				self.errorView?.updateConstraints()
			}, completion: { (finished) -> Void in
				self.errorView?.isHidden = true
			})
		}
	}
}

//MARK: - MPSegmentControlCellStateDelegate
extension ViewController {
	func segmentControlCellSelectedState(_ segmentControlCell: MPSegmentedControlCell, forIndex index: Int) {
		MPAnimation.animate(withDuration: 0.1, animations: {
			segmentControlCell.imageView.tintColor = self.blueColor
		})
		
		UIView.transition(with: segmentControlCell.label, duration: 0.1, options: [.transitionCrossDissolve, .beginFromCurrentState], animations: {
			segmentControlCell.label.textColor = self.blueColor
		}, completion: nil)
		
		switch index {
		case 0:
			fetchedResultsController.fetchRequest.predicate = TravelType.trains.toCoreDataPredicate()
			
		case 1:
			fetchedResultsController.fetchRequest.predicate = TravelType.buses.toCoreDataPredicate()
			
		case 2:
			fetchedResultsController.fetchRequest.predicate = TravelType.flights.toCoreDataPredicate()

		default:
			fetchedResultsController.fetchRequest.predicate = TravelType.trains.toCoreDataPredicate()
		}
		do {
			try fetchedResultsController.performFetch()
			DispatchQueue.main.async {
				self.tableView?.reloadData()
				self.tableView?.contentOffset = self.contentOffsets[(self.segmentControl?.selectedSegmentIndex)!]
			}
		} catch let error as NSError {
			print("Fetching error: \(error), \(error.userInfo)")
		}
	}
	
	func segmentControlCellNormalState(_ segmentControlCell: MPSegmentedControlCell, forIndex index: Int) {
		MPAnimation.animate(withDuration: 0.1, animations: {
			segmentControlCell.imageView.tintColor = UIColor.white
		})
		
		UIView.transition(with: segmentControlCell.label, duration: 0.1, options: [.transitionCrossDissolve, .beginFromCurrentState], animations: {
			segmentControlCell.label.textColor = UIColor.white
		}, completion: nil)
	}
	
	//MARK: - MPSegmentControlDelegate
	func indicatorViewRelativeTo(position: CGFloat, onSegmentControl segmentControl: MPSegmentedControl) {
		let percentPosition = position / (segmentControl.frame.width - position) / CGFloat(segmentControl.numberOfSegments - 1) * 100
		let intPercentPosition = Int(percentPosition)
		print("scrolling: \(intPercentPosition)%")
	}
}

// Reachability
extension ViewController {
	func setupReachability(_ hostName: String?, useClosures: Bool) {
		let hostName = hostName != nil ? hostName : "No host name"
		
		print("--- set up with host name: \(hostName!)")
		
		let reachability = hostName == nil ? Reachability() : Reachability(hostname: hostName!)
		self.reachability = reachability
		
		if useClosures {
			reachability?.whenReachable = { reachability in
				DispatchQueue.main.async {
					self.hideConnectionWarning()
				}
			}
			reachability?.whenUnreachable = { reachability in
				DispatchQueue.main.async {
					self.showConnectionWarning("Unable to connect. Check your network connection.")
				}
			}
		} else {
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(ViewController.reachabilityChanged(_:)),
				name: ReachabilityChangedNotification,
				object: reachability
			)
		}
	}
	
	func startNotifier() {
		print("--- start notifier")
		do {
			try reachability?.startNotifier()
		} catch {
			self.showConnectionWarning("Unable to start notifier")
		}
	}
	
	func stopNotifier() {
		print("--- stop notifier")
		reachability?.stopNotifier()
		NotificationCenter.default.removeObserver(
			self,
			name: ReachabilityChangedNotification,
			object: nil
		)
		reachability = nil
	}
	
	func reachabilityChanged(_ note: Notification) {
		let reachability = note.object as! Reachability
		
		if reachability.isReachable {
			DispatchQueue.main.async {
				self.hideConnectionWarning()
			}
			if reachability.isReachableViaWiFi {
				print("Reachable via WiFi")
			} else {
				print("Reachable via Cellular")
			}
		} else {
			DispatchQueue.main.async {
				self.showConnectionWarning("Unable to connect. Check your network connection.")
			}
			print("Network not reachable")
		}
	}
}

// MARK: - NSFetchedResultsControllerDelegate
extension ViewController: NSFetchedResultsControllerDelegate {
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView?.beginUpdates()
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			tableView?.insertRows(at: [newIndexPath!], with: .automatic)
		case .delete:
			tableView?.deleteRows(at: [indexPath!], with: .automatic)
		case .update:
			let cell = tableView?.cellForRow(at: indexPath!) as! TravelCell
			configure(cell: cell, for: indexPath!)
		case .move:
			tableView?.deleteRows(at: [indexPath!], with: .automatic)
			tableView?.insertRows(at: [newIndexPath!], with: .automatic)
		}
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView?.endUpdates()
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
		let indexSet = IndexSet(integer: sectionIndex)
		
		switch type {
		case .insert:
			tableView?.insertSections(indexSet, with: .automatic)
		case .delete:
			tableView?.deleteSections(indexSet, with: .automatic)
		default: break
		}
	}
}

// MARK: - IBActions
extension ViewController {
	@IBAction func changeSortOrder(_ sender: Any) {
		let alertController = UIAlertController(
			title: "Order by",
			message: nil,
			preferredStyle: .actionSheet
		)
		
		let departureAction = UIAlertAction(title: "Departure", style: .default) { _ in
			self.fetchedResultsController.fetchRequest.sortDescriptors = [SortOrder.departure.toCoreDataSort()]
			do {
				try self.fetchedResultsController.performFetch()
				DispatchQueue.main.async {
					self.tableView?.reloadData()
					self.tableView?.contentOffset = CGPoint.zero
				}
			} catch let error as NSError {
				print("Fetching error: \(error), \(error.userInfo)")
			}
		}
		alertController.addAction(departureAction)
		
		let arrivalAction = UIAlertAction(title: "Arrival", style: .default) { _ in
			self.fetchedResultsController.fetchRequest.sortDescriptors = [SortOrder.arrival.toCoreDataSort()]
			do {
				try self.fetchedResultsController.performFetch()
				DispatchQueue.main.async {
					self.tableView?.reloadData()
					self.tableView?.contentOffset = CGPoint.zero
				}
			} catch let error as NSError {
				print("Fetching error: \(error), \(error.userInfo)")
			}
		}
		alertController.addAction(arrivalAction)
		
		let durationAction = UIAlertAction(title: "Duration", style: .default) { _ in
			self.fetchedResultsController.fetchRequest.sortDescriptors = [SortOrder.duration.toCoreDataSort()]
			do {
				try self.fetchedResultsController.performFetch()
				DispatchQueue.main.async {
					self.tableView?.reloadData()
					self.tableView?.contentOffset = CGPoint.zero
				}
			} catch let error as NSError {
				print("Fetching error: \(error), \(error.userInfo)")
			}
		}
		alertController.addAction(durationAction)
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
		alertController.addAction(cancelAction)
		
		DispatchQueue.main.async {
			self.present(alertController, animated: true, completion: nil)
		}
	}
}
