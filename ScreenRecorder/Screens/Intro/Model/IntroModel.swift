//
//  IntroModel.swift
//  ScreenRecorder_Into
//
//  Created by Tonmoy  on 8/31/25.
//

import UIKit


struct IntroModel {
    let imgBG: UIImage?
    let title: String
    let subTitle: String
}

let deviceHeight = UIScreen.main.bounds.height

var intros: [IntroModel] = [
    IntroModel(imgBG: UIImage(named: (deviceHeight <= 667) ? "Intro1SE" : "Intro1"), title: "Capture Everything", subTitle: "Record Your\nScreens Easily"),
    IntroModel(imgBG: UIImage(named: (deviceHeight <= 667) ? "Intro2SE" : "Intro2"), title: "live broadcast", subTitle: "Live Stream\nto All Platforms"),
    IntroModel(imgBG: UIImage(named: (deviceHeight <= 667) ? "Intro3SE" : "Intro3"), title: "video editor", subTitle: "The Video\nEditing Experience"),
    IntroModel(imgBG: UIImage(named: (deviceHeight <= 667) ? "Intro4SE" : "Intro4"), title: "Social Perfect", subTitle: "Optimized\nfor Social Platform"),
    IntroModel(imgBG: UIImage(named: "Review"), title: "Help Us Grow", subTitle: "Show love with a\n5-Star Review")
]
