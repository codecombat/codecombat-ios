import UIKit

class LevelPlaybackViewController: PlayViewChildViewController {
  
  @IBOutlet weak var playbackSlider: UISlider!
  @IBOutlet weak var playButton: UIButton!
  
  var totalFrames:Int = 0
  var currentFrame:Int = 0
  var frameRate:Int = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    addScriptMessageNotificationObservers()
  }
  
  private func addScriptMessageNotificationObservers() {
    WebManager.sharedInstance.scriptMessageNotificationCenter.addObserver(self,
      selector: Selector("handleSurfaceFrameChangedNotification:"),
      name: "surfaceFrameChangedHandler",
      object: WebManager.sharedInstance)
  }

  func handleSurfaceFrameChangedNotification(notification:NSNotification) {
    if let MessageBody = notification.userInfo {
      totalFrames = MessageBody["totalFrames"]! as Int
      currentFrame = MessageBody["frame"]! as Int
      frameRate = MessageBody["frameRate"]! as Int
      playbackSlider.maximumValue = Float(totalFrames)
      playbackSlider.value = Float(currentFrame)
    }
    
  }
  
  @IBAction func togglePlay(sender:AnyObject?) {
    sendBackboneEvent("level-toggle-playing", data: nil)
  }
  
  @IBAction func sliderValueChanged(sender:AnyObject?) {
    let EventDictionary = ["time":Float(playbackSlider.value)/Float(frameRate)]
    sendBackboneEvent("level-set-time", data: EventDictionary)
  }
}
