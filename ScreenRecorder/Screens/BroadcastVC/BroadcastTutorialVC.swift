//
//  BroadcastTutorialVC.swift
//  ScreenRecorder
//
//  Created by Sajjad Hosain on 11/3/25.
//

import UIKit
import AVKit
import AVFoundation

class BroadcastTutorialVC: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func playVideo(url: URL){
        
        DispatchQueue.main.async { [self] in
            let player = AVPlayer(url: url)
            let controller = AVPlayerViewController()
            controller.player = player
            present(controller, animated: true) {
                player.play()
            }
        }
    }
    
    // MARK: - Private Methods -
    
    @IBAction func dismiss(){
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func fb(){
        guard let url = Bundle.main.url(forResource: "facebook", withExtension: "mp4") else {
            debugPrint("video.m4v not found")
            return
        }
        playVideo(url: url)
    }
    @IBAction func rtmp(){
        guard let url = Bundle.main.url(forResource: "facebook", withExtension: "mp4") else {
            debugPrint("video.m4v not found")
            return
        }
        // playVideo(url: url)
    }
    @IBAction func youTube(){
        guard let url = Bundle.main.url(forResource: "youtube", withExtension: "mp4") else {
            debugPrint("video.m4v not found")
            return
        }
        playVideo(url: url)
    }
    @IBAction func twitch(){
        guard let url = Bundle.main.url(forResource: "twitch", withExtension: "mp4") else {
            debugPrint("video.m4v not found")
            return
        }
        playVideo(url: url)
    }

}
