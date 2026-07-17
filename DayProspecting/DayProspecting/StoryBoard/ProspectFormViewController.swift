//
//  ProspectFormViewController.swift
//  DayProspecting
//
//  Created by Domingo Hilario on 7/14/26.
//

import UIKit
import SwiftUI

class ProspectFormViewController: UIViewController {

    override func viewDidLoad(){
        super.viewDidLoad()
    }
    
    // 💡 This runs automatically when the storyboard triggers the segue transition
    @IBSegueAction func showSwiftUIView(_ coder: NSCoder) -> UIViewController? {
        // Replace 'ProspectForm()' with whatever SwiftUI view layout you want to load
        return UIHostingController(coder: coder, rootView: ContentView())
    }
}
