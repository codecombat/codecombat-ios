//
//  EditorTextViewController.swift
//  CodeCombat
//
//  Created by Michael Schmatz on 9/15/14.
//  Copyright (c) 2014 CodeCombat. All rights reserved.
//

import UIKit

class EditorTextViewController: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate, StringPickerPopoverDelegate {
  let textStorage = EditorTextStorage()
  let textContainer = NSTextContainer()
  
  var draggedLabel:UILabel!
  var draggedCharacterRange:NSRange!
  var highlightedLineNumber = -1
  
  var dragGestureRecognizer:UIPanGestureRecognizer!
  var tapGestureRecognizer:UITapGestureRecognizer!
  var dragOverlayLabels:[Int:UILabel] = Dictionary<Int,UILabel>()
  var originalDragOverlayLabelOffsets:[Int:CGFloat] = Dictionary<Int,CGFloat>()
  
  var textView:EditorTextView!
  var keyboardModeEnabled:Bool {
    return textView.keyboardModeEnabled
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupGestureRecognizers()
    setupWebManagerSubscriptions()
    addNotificationCenterObservers()
  }
  
  private func setupGestureRecognizers() {
    dragGestureRecognizer = UIPanGestureRecognizer(target: self, action: "onDrag:")
    dragGestureRecognizer.delegate = self
    tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "onTap:")
    tapGestureRecognizer.delegate = self
    tapGestureRecognizer.requireGestureRecognizerToFail(dragGestureRecognizer)
  }
  
  func setupWebManagerSubscriptions() {
    WebManager.sharedInstance.subscribe(self, channel: "tome:highlight-line", selector: Selector("onSpellStatementIndexUpdated:"))
    WebManager.sharedInstance.subscribe(self, channel: "problem:problem-created", selector: Selector("onProblemCreated:"))
  }
  
  func addNotificationCenterObservers() {
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onCodeRun"), name: "codeRun", object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("onTextStorageFinishedTopLevelEditing"), name: "textStorageFinishedTopLevelEditing", object: nil)
  }
  
  func onSpellStatementIndexUpdated(note:NSNotification) {
    if let event = note.userInfo {
      var lineIndex = event["line"]! as Int
      lineIndex++
      if lineIndex != highlightedLineNumber {
        highlightedLineNumber = lineIndex
        textView.highlightLineNumber(lineIndex)
      }
    }
  }
  
  func onProblemCreated(note:NSNotification) {
    if let event = note.userInfo {
      var lineIndex = event["line"]! as Int
      var errorText = event["text"]! as String
      lineIndex++
      textView.addUserCodeProblemGutterAnnotationOnLine(lineIndex, message: errorText)
      textView.highlightUserCodeProblemLine(lineIndex)
    }
  }
  
  func onTap(recognizer:UITapGestureRecognizer) {
    if recognizer != tapGestureRecognizer {
      return
    }
    var locationInTextView = recognizer.locationInView(textView)
    let tappedCharacterIndex = textView.layoutManager.characterIndexForPoint(locationInTextView, inTextContainer: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    if textStorage.characterIsPartOfString(tappedCharacterIndex) {
      let stringRange = textStorage.stringRangeContainingCharacterIndex(tappedCharacterIndex)
      
      switch LevelSettingsManager.sharedInstance.level {
      case .TrueNames:
        createStringPickerPopoverWithChoices(["\"Brak\"","\"Treg\""], characterRange: stringRange, delegate: self)
      case .TheRaisedSword:
        createStringPickerPopoverWithChoices(["\"Gurt\"","\"Rig\"","\"Ack\""], characterRange: stringRange, delegate: self)
      default:
        break
      }
    }
  }
  
  func onCodeRun() {
    textView.clearCodeProblemGutterAnnotations()
    textView.clearErrorMessageView()
    textView.removeUserCodeProblemLineHighlights()
  }
  
  func onDrag(recognizer:UIPanGestureRecognizer) {
    if recognizer == textView.panGestureRecognizer {
      return
    }
    
    var locationInParentView = recognizer.locationInView(parentViewController!.view)
    locationInParentView.y += (textView.lineSpacing + textView.font.lineHeight) / 2
    var locationInTextView = recognizer.locationInView(textView)
    switch recognizer.state {
    case .Began:
      var lineFragmentRect = getLineFragmentRectForDrag(locationInTextView)
      var characterRange = getCharacterRangeForLineFragmentRect(lineFragmentRect)
      let fragmentParagraphRange = textStorage.string()!.paragraphRangeForRange(characterRange)
      draggedLabel = createDraggedLabel(lineFragmentRect, loc: locationInParentView, fragmentCharacterRange: characterRange)
      draggedCharacterRange = fragmentParagraphRange
      parentViewController!.view.addSubview(draggedLabel)
      textView.draggedLineNumber = lineNumberForDraggedCharacterRange(characterRange)
      
      textView.createTextViewCoverView()
      textView.createViewsForAllLinesExceptDragged(lineFragmentRect, draggedCharacterRange: characterRange)
      textView.createDeletionOverlayView()
      break
    case .Changed:
      draggedLabel.center = locationInParentView
      textView.adjustLineViewsForDragLocation(locationInTextView)
      scrollWhileDraggingIfNecessary(locationInParentView)
      hideOrShowDeleteOverlay()
      break
    case .Ended:
      textView.clearLineOverlayLabels()
      if draggedLineInDeletionZone() {
        deleteDraggedLine()
      } else {
        shiftAroundLines(locationInTextView)
      }
      //These eventually should run only when the code significantly changes
      textView.removeCurrentLineNumberHighlight()
      textView.clearCodeProblemGutterAnnotations()
      textView.removeUserCodeProblemLineHighlights()
      textView.removeDeletionOverlayView()
      textView.removeTextViewCoverView()
      draggedLabel.removeFromSuperview()
      draggedLabel = nil
      break
    default:
      break
    }
  }
  
  func handleItemPropertyDragBegan() {
    textView.drawDragHintViewOnLastLine()
  }
  
  func handleItemPropertyDragChangedAtLocation(location:CGPoint) {
    textView.dimLineUnderLocation(location)
  }
  
  func handleItemPropertyDragEndedAtLocation(location:CGPoint, code:String) {
    textView.removeLineDimmingOverlay()
    textView.removeDragHintView()
    
    let storage = textStorage as EditorTextStorage
    
    let dragPoint = CGPoint(x: 0, y: location.y)
    let nearestGlyphIndex = textView.layoutManager.glyphIndexForPoint(dragPoint,
      inTextContainer: textContainer) //nearest glyph index
    //This may cause some really really weird bugs if glyphs and character indices don't correspond.
    let nearestCharacterIndex = textView.layoutManager.characterIndexForGlyphAtIndex(nearestGlyphIndex)
    
    let draggedOntoLine = Int(location.y / (textView.font.lineHeight + textView.lineSpacing)) + 1
    var numberOfNewlinesBeforeGlyphIndex = 1
    for var index = 0; index < nearestGlyphIndex; numberOfNewlinesBeforeGlyphIndex++ {
      index = NSMaxRange(storage.string()!.lineRangeForRange(NSRange(location: index, length: 0)))
    }
    
    var totalLinesInDoc = 1
    for var index = 0; index < storage.string()!.length; totalLinesInDoc++ {
      index = NSMaxRange(storage.string()!.lineRangeForRange(NSRange(location: index, length: 0)))
    }
    
    let characterAtGlyphIndex = storage.string()!.characterAtIndex(nearestGlyphIndex)
    let characterBeforeGlyphIndex = storage.string()!.characterAtIndex(nearestGlyphIndex - 1)
    var stringToInsert = code
    var newlinesToInsert = draggedOntoLine - numberOfNewlinesBeforeGlyphIndex
    //Check if dragging onto an empty line in between two other lines of code.
    stringToInsert = textView.fixIndentationLevelForPython(nearestCharacterIndex, lineNumber: draggedOntoLine, rawString: stringToInsert)
    //Adjust code to match indentation level and other languages
    if characterAtGlyphIndex == 10 && characterBeforeGlyphIndex == 10 {
    } else if draggedOntoLine == numberOfNewlinesBeforeGlyphIndex && characterAtGlyphIndex != 10 {
      stringToInsert = stringToInsert + "\n"
    } else if draggedOntoLine == numberOfNewlinesBeforeGlyphIndex && nearestGlyphIndex == storage.string()!.length - 1 {
      stringToInsert = "\n" + stringToInsert
    } else if draggedOntoLine > numberOfNewlinesBeforeGlyphIndex { //adapt to deal with wrapped lines
      for var newlinesToInsertBeforeString = draggedOntoLine - numberOfNewlinesBeforeGlyphIndex; newlinesToInsertBeforeString > 0; newlinesToInsertBeforeString-- {
        stringToInsert = "\n" + stringToInsert  // TODO: figure out why something was prepending newlines in Gems in the Deep; > 0 used to be >= 0, dunno if that works.
      }
    }
    //Check if code contains a placeholder
    if textView.codeContainsPlaceholder(stringToInsert) {
      println(stringToInsert)
      let placeholderReplacement = textView.getPlaceholderWidthString(stringToInsert)
      stringToInsert = textView.replacePlaceholderInString(stringToInsert, replacement: placeholderReplacement)
    }
    
    storage.replaceCharactersInRange(NSRange(location: nearestGlyphIndex, length: 0), withString: stringToInsert)
    textView.setNeedsDisplay()
  }
  
  func getArgumentOverlays() -> [(String, NSRange)] {
    return textStorage.findArgumentOverlays()
  }
  
  func createStringPickerPopoverWithChoices(choices:[String], characterRange:NSRange, delegate:StringPickerPopoverDelegate) {
    let stringPickerViewController = ArgumentStringPickerPopoverViewController(stringChoices: choices, characterRange:characterRange)
    stringPickerViewController.pickerDelegate = delegate
    let glyphRange = textView.layoutManager.glyphRangeForCharacterRange(characterRange, actualCharacterRange: nil)
    var boundingRect = textView.layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: textContainer)
    boundingRect.origin.y += textView.lineSpacing
    let popover = UIPopoverController(contentViewController: stringPickerViewController)
    popover.setPopoverContentSize(CGSize(width: 100, height: stringPickerViewController.rowHeight*choices.count), animated: true)
    popover.presentPopoverFromRect(boundingRect, inView: textView, permittedArrowDirections: .Down | .Up, animated: true)
    
  }
  
  func replaceCharactersInCharacterRange(characterRange:NSRange, str:String) {
    textStorage.replaceCharactersInRange(characterRange, withString: str)
  }
  
  func stringWasSelectedByStringPickerPopover(selected:String, characterRange:NSRange) {
    replaceCharactersInCharacterRange(characterRange, str: selected)
  }
  
  func onTextStorageFinishedTopLevelEditing() {
    ensureNewlineAtEndOfCode()
  }
  
  func toggleKeyboardMode() {
    textView.toggleKeyboardMode()
  }
  
  func ensureNewlineAtEndOfCode() {
    if !textStorage.string()!.hasSuffix("\n") {
      textStorage.beginEditing()
      textStorage.appendAttributedString(NSAttributedString(string: "\n"))
      textStorage.endEditing()
    }
  }
  
  func textViewDidEndEditing(textView: UITextView) {
    ensureNewlineAtEndOfCode()
    toggleKeyboardMode()
  }
  
  private func getLineFragmentRectForDrag(dragLocation:CGPoint) -> CGRect {
    let nearestGlyphIndexToDrag = textView.layoutManager.glyphIndexForPoint(dragLocation, inTextContainer: textContainer)
    var effectiveGlyphRange:NSRange = NSRange(location:0, length:0)
    var lineFragmentRectToDrag = textView.layoutManager.lineFragmentRectForGlyphAtIndex(nearestGlyphIndexToDrag, effectiveRange: &effectiveGlyphRange)
    return lineFragmentRectToDrag
  }
  
  private func getCharacterRangeForLineFragmentRect(lineFragmentRect:CGRect) -> NSRange {
    let glyphRange = textView.layoutManager.glyphRangeForBoundingRect(lineFragmentRect, inTextContainer: textContainer)
    let characterRange = textView.layoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
    return characterRange
  }
  
  func getAttributedStringForCharacterRange(range:NSRange) -> NSAttributedString {
    return textStorage.attributedString!.attributedSubstringFromRange(range)
  }
  
  private func createDraggedLabel(lineFragmentRect:CGRect, loc:CGPoint, fragmentCharacterRange:NSRange) -> UILabel {
    let label = UILabel(frame: lineFragmentRect)
    let fragmentParagraphRange = textStorage.string()!.paragraphRangeForRange(fragmentCharacterRange)
    if fragmentCharacterRange.length == fragmentParagraphRange.length {
      label.attributedText = getAttributedStringForCharacterRange(fragmentParagraphRange)
    } else {
      let attributedStringBeforeLineBreak = NSMutableAttributedString(attributedString: getAttributedStringForCharacterRange(fragmentCharacterRange))
      attributedStringBeforeLineBreak.appendAttributedString(NSAttributedString(string: "\n"))
      let attributedStringAfterLineBreak = getAttributedStringForCharacterRange(NSRange(location: NSMaxRange(fragmentCharacterRange), length: (fragmentParagraphRange.length - fragmentCharacterRange.length)))
      attributedStringBeforeLineBreak.appendAttributedString(attributedStringAfterLineBreak)
      label.lineBreakMode = NSLineBreakMode.ByWordWrapping
      label.numberOfLines = 0
      var paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineSpacing = textView.lineSpacing
      attributedStringBeforeLineBreak.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSRange(location: 0, length: attributedStringBeforeLineBreak.length))
      label.attributedText = attributedStringBeforeLineBreak
      label.frame.size.height += textView.font.lineHeight + textView.lineSpacing
    }
    
    label.sizeToFit()
    label.center = loc
    return label
  }
  
  private func hideOrShowDeleteOverlay() {
    if draggedLineInDeletionZone() {
      textView.showDeletionOverlayView()
    } else {
      textView.hideDeletionOverlayView()
    }
  }
  
  private func draggedLineInDeletionZone() -> Bool {
    return draggedLabel.center.x > parentViewController!.view.bounds.maxX - textView.deletionOverlayWidth
  }
  
  private func deleteDraggedLine() {
    textStorage.beginEditing()
    if draggedCharacterRange.location != 0 {
      textStorage.replaceCharactersInRange(draggedCharacterRange, withString: "")
    } else {
      textStorage.replaceCharactersInRange(draggedCharacterRange, withString: "\n")
    }
    textStorage.endEditing()
    textView.setNeedsDisplay()
  }
  
  private func shiftAroundLines(dragEndLocation:CGPoint) {
    //get the text underneath the drag end
    let lineFragmentRect = getLineFragmentRectForDrag(dragEndLocation);
    let characterRange = getCharacterRangeForLineFragmentRect(lineFragmentRect)
    let replacedString = textStorage.string()!.substringWithRange(characterRange)
    let replacingString = textStorage.string()!.substringWithRange(draggedCharacterRange)
    if !NSEqualRanges(draggedCharacterRange, characterRange) {
      textStorage.beginEditing()
      //edit the latter range first
      let replacingRange = NSRange(location: characterRange.location, length: 0)
      if draggedCharacterRange.location > characterRange.location {
        textStorage.replaceCharactersInRange(draggedCharacterRange, withString: "")
        textStorage.replaceCharactersInRange(replacingRange, withString: replacingString)
      } else {
        textStorage.replaceCharactersInRange(characterRange, withString: replacedString + replacingString)
        textStorage.replaceCharactersInRange(draggedCharacterRange, withString: "")
        //textStorage.replaceCharactersInRange(draggedCharacterRange, withString: "")
      }
      textStorage.endEditing()
      textView.setNeedsDisplay()
    }
  }

  private func lineNumberForDraggedCharacterRange(range:NSRange) -> Int {
    let sourceString = textStorage.string()!.substringWithRange(NSRange(location: 0, length: range.location))
    let errorPointer = NSErrorPointer()
    let regex = NSRegularExpression(pattern: "\\n", options:nil, error: errorPointer)
    let matches = regex!.numberOfMatchesInString(sourceString, options: nil, range: NSRange(location: 0, length: countElements(sourceString)))
    return matches + 1
  }
  
  func scrollWhileDraggingIfNecessary(locationInParentView:CGPoint) {
    let pvc = parentViewController as PlayViewController
    if locationInParentView.y > 760 {
      var newScrollLocation = pvc.scrollView.contentOffset
      newScrollLocation.y = pvc.scrollView.contentSize.height - pvc.scrollView.bounds.size.height
      pvc.scrollView.setContentOffset(newScrollLocation, animated: true)
    }
  }
  
  func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
    if draggedLabel != nil {
      return false
    }
    //find if the nearest glyph is a newline (aka not dragging on a thing)
    let nearestGlyphIndexToDrag = textView.layoutManager.glyphIndexForPoint(gestureRecognizer.locationInView(textView), inTextContainer: textContainer)
    let characterIndex = textView.layoutManager.characterIndexForGlyphAtIndex(nearestGlyphIndexToDrag)
    let character = textStorage.string()!.characterAtIndex(characterIndex)
    if character == 10 {
      return false
    }
    return true
  }
  
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
  func createTextViewWithFrame(frame:CGRect) {
    setupTextKitHierarchy()
    textView = EditorTextView(frame: frame, textContainer: textContainer)
    textView.delegate = self
    textView.parentTextViewController = self
    textView.addGestureRecognizer(dragGestureRecognizer)
    textView.addGestureRecognizer(tapGestureRecognizer)
    textView.panGestureRecognizer.requireGestureRecognizerToFail(tapGestureRecognizer)
    textView.panGestureRecognizer.requireGestureRecognizerToFail(dragGestureRecognizer)
    view.addSubview(textView)
  }
  
  private func setupTextKitHierarchy() {
    let layoutManager = NSLayoutManager()
    layoutManager.allowsNonContiguousLayout = true
    textStorage.addLayoutManager(layoutManager)
    textContainer.lineBreakMode = NSLineBreakMode.ByWordWrapping
    textContainer.widthTracksTextView = true
    layoutManager.addTextContainer(textContainer)
  }
  
  func replaceTextViewContentsWithString(text:String) {
    textStorage.replaceCharactersInRange(NSRange(location: 0, length: textStorage.string()!.length), withString: text)
    textView.setNeedsDisplay()
  }
  
  func textView(textView: UITextView!, shouldChangeTextInRange range: NSRange, replacementText text: String!) -> Bool {
    if text == "\n" {
      textView.setNeedsDisplay()
    }
    return true
  }
  
  func textViewDidChange(textView: UITextView!) {
    self.textView.resizeLineNumberGutter()
  }
  
}
