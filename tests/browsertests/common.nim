import os, options, unittest, strutils
import webdriver
import macros

macro with*(obj: typed, code: untyped): untyped =
  ## Execute a set of statements with an object
  expectKind code, nnkStmtList
  result = code

  # Simply inject obj into call
  for i in 0 ..< result.len:
    if result[i].kind in {nnkCommand, nnkCall}:
      result[i].insert(1, obj)

template click*(session: Session, element: string, strategy=CssSelector) =
  let el = session.findElement(element, strategy)
  check el.isSome()
  el.get().click()

template sendKeys*(session: Session, element, keys: string) =
  let el = session.findElement(element)
  check el.isSome()
  el.get().sendKeys(keys)

template clear*(session: Session, element: string) =
  let el = session.findElement(element)
  check el.isSome()
  el.get().clear()

template sendKeys*(session: Session, element: string, keys: varargs[Key]) =
  let el = session.findElement(element)
  check el.isSome()

  # focus
  el.get().click()
  for key in keys:
    session.press(key)

template ensureExists*(session: Session, element: string, strategy=CssSelector) =
  let el = session.findElement(element, strategy)
  check el.isSome()

template check*(session: Session, element: string, function: untyped) =
  let el = session.findElement(element)
  check function(el)

template check*(session: Session, element: string,
                strategy: LocationStrategy, function: untyped) =
  let el = session.findElement(element, strategy)
  check function(el)

template checkIsNone*(session: Session, element: string, strategy=CssSelector) =
  let el = session.findElement(element, strategy)
  check el.isNone()

template checkText*(session: Session, element, expectedValue: string) =
  let el = session.findElement(element)
  check el.isSome()
  check el.get().getText() == expectedValue

proc waitForLoad*(session: Session, timeout=20000) =
  var waitTime = 0
  sleep(2000)

  while true:
    let loading = session.findElement(".loading")
    if loading.isNone: return
    sleep(1000)
    waitTime += 1000

    if waitTime > timeout:
      doAssert false, "Wait for load time exceeded"

proc wait*(session: Session, msTimeout: int = 5000) =
  session.waitForLoad(msTimeout)

proc setUserRank*(session: Session, baseUrl, user, rank: string) =
  with session:
    navigate(baseUrl & "profile/" & user)
    wait()

    click "#settings-tab"

    click "#rank-field"
    click("#rank-field option#rank-" & rank.toLowerAscii)

    click "#save-btn"
    wait()

proc logout*(session: Session) =
  with session:
    click "#profile-btn"
    click "#profile-btn #logout-btn"
    wait()

    # Verify we have logged out by looking for the log in button.
    ensureExists "#login-btn"

proc login*(session: Session, user, password: string) =
  with session:
    click "#login-btn"

    clear "#login-form input[name='username']"
    clear "#login-form input[name='password']"

    sendKeys "#login-form input[name='username']", user
    sendKeys "#login-form input[name='password']", password

    sendKeys "#login-form input[name='password']", Key.Enter

    wait()

    # Verify that the user menu has been initialised properly.
    click "#profile-btn"
    checkText "#profile-btn #profile-name", user
    click "#profile-btn"

proc register*(session: Session, user, password: string) =
  with session:
    click "#signup-btn"

    clear "#signup-form input[name='email']"
    clear "#signup-form input[name='username']"
    clear "#signup-form input[name='password']"

    sendKeys "#signup-form input[name='email']", user & "@" & user & ".com"
    sendKeys "#signup-form input[name='username']", user
    sendKeys "#signup-form input[name='password']", password

    click "#signup-modal .create-account-btn"
    wait()

    # Verify that the user menu has been initialised properly.
    click "#profile-btn"
    checkText "#profile-btn #profile-name", user
    # close menu
    click "#profile-btn"

proc createThread*(session: Session, title, content: string) =
  with session:
    click "#new-thread-btn"
    wait()

    sendKeys "#thread-title", title
    sendKeys "#reply-textarea", content

    click "#create-thread-btn"
    wait()

    checkText "#thread-title", title
    checkText ".original-post div.post-content", content
