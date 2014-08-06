(function () {
    try {
        currentView.supermodel.on("update-progress", function (progress) {
            try {
                                  var objectToSend = {"progress":progress};
                webkit.messageHandlers.progressHandler.postMessage(objectToSend);
            } catch (err) {
                console.log("Native context doesn't exist yet");
            }
        });
    } catch (err) {
        window.webkit.messageHandlers.progressHandler.postMessage(err);
    }
 })();
/*
var injectProgressListener = function () {
  if (currentView) {
    progressListener();
  }
  else {
    setTimeout(injectProgressListener, 200);
  }
};
injectProgressListener();
*/