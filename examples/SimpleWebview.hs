import           Control.Concurrent
import           Control.Monad
import           Control.Monad.Loops
import           Graphics.LibUI

uiNewLogPanel = do
    e <- uiNewNonWrappingMultilineEntry
    e `setReadOnly` True
    uiSetEnabled e False
    wc <- newChan
    forkIO $ forever $ do
        str <- readChan wc
        uiQueueMain $ do
            e `appendText` str
            e `appendText` "\n"
    return (e, wc)

main :: IO ()
main = do
    uiInit

    webview <- uiNewWebview
    webview `loadHtml`
        ( unlines [ "<div class=\"container text-center\">"
                  , "  <h1>Hello</h1>"
                  , "  <button class=\"btn btn-primary\">Click me</button>"
                  , "  <link href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css\" rel=\"stylesheet\" integrity=\"sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7\" crossorigin=\"anonymous\">"
                  , "  <script src=\"https://code.jquery.com/jquery-3.1.0.slim.min.js\"></script>"
                  , "</div>"
                  ]
        , ""
        )

    -- TODO - Wrap 'webview `onLoad` do stuff'
    forkIO $ do
        threadDelay (1000 * 100)
        uiQueueMain $ do
            c <- webview `evalJs`
                unlines [ "(function() {"
                        , "  $(function() {"
                        , "    var button = $('button');"
                        , "    button.click(function() {"
                        , "      button.text('Click me (last at: ' + new Date().getTime() + ')');"
                        , "    });"
                        , "  });"
                        , "  return 'OK';"
                        , "})();"
                        ]
            print ("JavaScript button starts with", c)

    wn <- uiNewWindow "SimpleCounter.hs" 500 500 True

    hb <- uiNewHorizontalBox
    vb <- uiNewVerticalBox

    hb `appendChildStretchy` vb
    wn `setMargined` True
    wn `setChild` hb

    vb `appendChildStretchy` webview

    (e, wc) <- uiNewLogPanel
    hb `appendChild` e

    btn <- uiNewButton "Click to evaluate JS"
    btn `onClick` do
        r <- webview `evalJs`
            unlines [ "(function() {"
                    , "  var now = new Date().getTime();"
                    , "  var log = document.createElement('div');"
                    , "  log.class = 'container';"
                    , "  var pre = document.createElement('pre');"
                    , "  var code = document.createElement('code');"
                    , "  code.appendChild("
                    , "    document.createTextNode('Hello webview from Haskell ' + now)"
                    , "  );"
                    , "  pre.appendChild(code);"
                    , "  log.appendChild(pre);"
                    , "  document.body.appendChild(log);"
                    , "  return now;"
                    , "})()"
                    ]
        writeChan wc (show ("JavaScript sent us", r))
    vb `appendChild` btn

    wn `onClosing` uiQuit

    uiWindowCenter wn

    uiOnShouldQuit (uiQuit >> return 0)
    uiShow wn
    uiMain
