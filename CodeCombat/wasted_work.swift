//
//  LevelLoadingViewController.swift
//  iPadClient
//
//  Created by Michael Schmatz on 7/28/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//
/*
import UIKit
import WebKit

class LevelLoadingViewController: UIViewController {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var levelLoadingProgressView: UIProgressView!
    var webView: WKWebView?
    let rootURL = WebManager.sharedInstance.rootURL
    let webViewContextPointer = UnsafePointer<()>()
    var injectedListeners:Bool = false
    var spriteMessageBeforeUnveil:SpriteDialogue?
    var reloadDetectionClosure:((Bool) -> Bool)!
    var hasLoggedIn:Bool = false
    var isLoggingIn:Bool = false
    var performedLoginReload:Bool = false
    var hasInjectedScriptMessageHandlers:Bool = false
    
    var loadingProgressWhenLoggingIn:Float?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reloadDetectionClosure = makeDetectReloadClosure()
        let webViewFrame = CGRectMake(0, 0, 563 , 359)
        NSHTTPCookieStorage.sharedHTTPCookieStorage().cookieAcceptPolicy = NSHTTPCookieAcceptPolicy.Always
        webView = WKWebView(frame:webViewFrame,
            configuration:WebManager.sharedInstance.webViewConfiguration)
        
        WebManager.sharedInstance.scriptMessageNotificationCenter?.addObserver(self, selector: Selector("handleProgressUpdate:"), name: "progressHandler", object: WebManager.sharedInstance)
        WebManager.sharedInstance.scriptMessageNotificationCenter?.addObserver(self, selector: Selector("handleLevelStarted"), name: "levelStartedHandler", object: WebManager.sharedInstance)
        WebManager.sharedInstance.scriptMessageNotificationCenter?.addObserver(self, selector: Selector("handleDialogue:"), name: "spriteSpeechUpdatedHandler", object: WebManager.sharedInstance)
        
        let currentLevelSlug = "rescue-mission"
        let requestURL:NSURL = NSURL(string: "/play/level/\(currentLevelSlug)", relativeToURL: rootURL)
        let request = NSMutableURLRequest(URL: requestURL)
        webView!.addObserver(self, forKeyPath: NSStringFromSelector(Selector("loading")), options: nil, context: webViewContextPointer)
        webView!.addObserver(self, forKeyPath: NSStringFromSelector(Selector("estimatedProgress")), options: NSKeyValueObservingOptions.Initial, context: webViewContextPointer)
        webView!.loadRequest(request)
        //webView!.hidden = true
        backgroundImageView.hidden = true
        self.view.addSubview(webView)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pageHasReloaded() -> Bool {
        return reloadDetectionClosure(webView!.loading)
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
    func handleProgressUpdate(notification:NSNotification) {
        let userInfoDict:NSDictionary = notification.userInfo as NSDictionary
        let progress:Float = userInfoDict["progress"] as Float
        levelLoadingProgressView.setProgress(progress, animated: true)
        
        /*if self.hasLoggedIn && self.pageHasReloaded() {
        
        } else if !self.pageHasReloaded() && !hasLoggedIn {
        let loadingProgressLoginScalingFactor:Float = 7.0
        let maxLoginProgress:Float = 1.0/loadingProgressLoginScalingFactor
        if webView!.loading {
        var minimumProgress:Float
        if loadingProgressWhenLoggingIn {
        minimumProgress = max(loadingProgressWhenLoggingIn!,maxLoginProgress)
        } else {
        minimumProgress = maxLoginProgress
        }
        levelLoadingProgressView.setProgress(min(minimumProgress,progress/loadingProgressLoginScalingFactor), animated: true)
        }
        
        }
        let progressScalingFactor:Float = 0.8
        levelLoadingProgressView.setProgress((progress * progressScalingFactor), animated: true)
        */
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        let destinationViewController:PlayViewController = segue.destinationViewController as PlayViewController
        destinationViewController.setWebView(webView)
        let nc:NSNotificationCenter = WebManager.sharedInstance.scriptMessageNotificationCenter!
        nc.removeObserver(self)
        
        if spriteMessageBeforeUnveil {
            println("Setting sprite dialogue on dvc")
            destinationViewController.setSpriteDialogue(spriteMessageBeforeUnveil!)
        }
    }
    
    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafePointer<()>) {
        if context == webViewContextPointer {
            switch keyPath! {
            case NSStringFromSelector(Selector("loading")):
                var hasReloaded:Bool = reloadDetectionClosure(webView!.loading)
                //println("Page has reloaded: \(hasReloaded)")
                /*if pageHasReloaded() && !hasInjectedScriptMessageHandlers {
                hasInjectedScriptMessageHandlers = true
                let timer = NSTimer(timeInterval: 1, target: self, selector: Selector("injectScriptsAndAddScriptHandlers"), userInfo: nil, repeats: false)
                NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
                
                }*/
                
            case NSStringFromSelector(Selector("estimatedProgress")):
                //println("Progress changed to \(webView?.estimatedProgress)")
                //levelLoadingProgressView.setProgress(Float(webView!.estimatedProgress), animated: true)
                let javascriptLoginExecutionProgress:Float = 0.85 //This is the progress point where enough is instantiated to login
                if (webView?.estimatedProgress > 0.85) && !injectedListeners { //&& !isLoggingIn  && !hasLoggedIn{
                    
                    injectScriptsAndAddScriptHandlers()
                    injectedListeners = true
                    //isLoggingIn = true
                    //hasLoggedIn = true
                    //loadingProgressWhenLoggingIn = levelLoadingProgressView.progress
                    //loginMichael()
                    
                }
            default:
                println("\(keyPath) changed")
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    func injectScriptsAndAddScriptHandlers() {
        injectListeners()
        let contentController:WKUserContentController! = webView!.configuration.userContentController
        contentController.addScriptMessageHandler(WebManager.sharedInstance,
            name: "progressHandler")
        contentController.addScriptMessageHandler(WebManager.sharedInstance,
            name: "spriteSpeechUpdatedHandler")
        contentController.addScriptMessageHandler(WebManager.sharedInstance,
            name: "levelStartedHandler");
        println("Injecting listeners!")
        
        hasInjectedScriptMessageHandlers = true
    }
    
    
    func handleLevelStarted() {
        println("Level started!")
        performSegueWithIdentifier("levelStartedSegue", sender: self)
    }
    
    func handleDialogue(notification:NSNotification) {
        let messageBody = notification.userInfo as NSDictionary
        println("Setting speech before unveil!")
        spriteMessageBeforeUnveil  = SpriteDialogue(
            image: UIImage(named: "AnyaPortrait"),
            spriteMessage: messageBody["message"] as String,
            spriteName: messageBody["spriteID"] as String)
        
    }
    
    func injectListeners() {
        if injectedListeners {
            return
        }
        injectProgressListener()
        injectSpriteDialogueListener()
        injectLevelStartedListener()
        //loginMichael()
        injectedListeners = true
    }
    
    func injectProgressListener() {
        var error:NSError? = nil
        let scriptFilePath = NSBundle.mainBundle().pathForResource("progressListener", ofType: "js")
        let scriptFromFile = NSString.stringWithContentsOfFile(scriptFilePath, encoding: NSUTF8StringEncoding, error: &error)
        println("Injecting script \(scriptFromFile)")
        
        webView?.evaluateJavaScript(scriptFromFile, completionHandler: progressListenerInjectionCompletionHandler)
    }
    func progressListenerInjectionCompletionHandler(response:AnyObject!, error:NSError?) {
        if error? {
            println("There was an error injecting the progress listener: \(error)")
        } else {
            println("Injected the progress listener! Response:\(response), error:\(error)")
        }
    }
    
    func injectSpriteDialogueListener() {
        var error:NSError? = nil
        let scriptFilePath = NSBundle.mainBundle().pathForResource("spriteDialogueListener", ofType: "js")
        let scriptFromFile = NSString.stringWithContentsOfFile(scriptFilePath, encoding: NSUTF8StringEncoding, error: &error)
        println("Injecting script \(scriptFromFile)")
        webView?.evaluateJavaScript(scriptFromFile, completionHandler: nil)
        
    }
    
    func injectLevelStartedListener() {
        var error:NSError? = nil
        let scriptFilePath = NSBundle.mainBundle().pathForResource("levelStartedListener", ofType: "js")
        let scriptFromFile = NSString.stringWithContentsOfFile(scriptFilePath, encoding: NSUTF8StringEncoding, error: &error)
        println("Injecting script \(scriptFromFile)")
        webView?.evaluateJavaScript(scriptFromFile, completionHandler: nil)
        
    }
    
    func loginMichael() {
        webView?.evaluateJavaScript("require('/lib/auth').loginUser({'email':'michael@codecombat.com','password':'lololol'})", completionHandler:handleLoginCompletion)
    }
    
    func handleLoginCompletion(returnValue:AnyObject!, error:NSError!) {
        hasLoggedIn = true
        isLoggingIn = false
        println("Logged in!")
        levelLoadingProgressView.setProgress(0.2, animated: true)
    }
    
    
    func makeDetectReloadClosure() -> ((Bool) -> Bool) {
        var valueHasFlippedTimes:Int = 0
        var loadingValue:Bool = false
        // The loading value will initially be false. When the WKWebView starts loading,
        // it will change to true and trigger the first change. Then the login script
        // will be executed and it will change to false. When it starts loading again
        // then it will flip to true, at which time we know the login was successful
        func hasReloaded(isLoadingCurrentValue:Bool) -> (Bool) {
            if loadingValue != isLoadingCurrentValue {
                valueHasFlippedTimes++
                loadingValue = isLoadingCurrentValue
            }
            return (valueHasFlippedTimes > 2)
        }
        return hasReloaded
    }
    
} */
