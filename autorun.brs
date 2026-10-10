' autorun.brs - launches the HTML app in sd:/app/ and enables the Local DWS
' with no password.

Sub Main()
    msgPort = CreateObject("roMessagePort")

    if EnableLocalDWS() then
        print "LDWS settings changed - rebooting to apply"
        RebootSystem()
    end if

    ' Full-screen widget sized to the current video mode
    vm = CreateObject("roVideoMode")
    rect = CreateObject("roRectangle", 0, 0, vm.GetResX(), vm.GetResY())

    config = {
        url: "file:///sd:/app/index.html",
        port: msgPort,
        javascript_enabled: true,
        brightsign_js_objects_enabled: true, ' required for BSIRReceiver
        mouse_enabled: false,
        storage_path: "SD:/app-storage/",
        ' Chrome DevTools on port 2999; also needs registry html/enable_web_inspector = "1"
        inspector_server: { port: 2999 },
    }

    html = CreateObject("roHtmlWidget", rect, config)
    html.Show()

    ' Keep the script (and therefore the widget) alive
    while true
        ev = wait(0, msgPort)
        if type(ev) = "roHtmlWidgetEvent" then
            data = ev.GetData()
            if type(data) = "roAssociativeArray" and type(data.reason) = "roString" then
                print "roHtmlWidgetEvent: " + data.reason
                if data.reason = "load-error" then
                    print "  load-error: " + data.message
                end if
            end if
        end if
    end while
End Sub

' Enables the Local DWS on the default port with an empty password (user "admin").
' Returns true only if a reboot is needed for the change to take effect, so this
' is safe to run on every boot without causing a reboot loop.
Function EnableLocalDWS() As Boolean
    needReboot = false

    ' LDWS is off by default on newer BOS releases; networking/dwse turns it on
    reg = CreateObject("roRegistrySection", "networking")
    dwse = LCase(reg.Read("dwse"))
    if dwse <> "yes" and dwse <> "true" and dwse <> "1" and dwse <> "on" then
        reg.Write("dwse", "yes")
        reg.Flush()
        needReboot = true
    end if

    ' DWS settings are global; any existing interface object can apply them
    nc = CreateObject("roNetworkConfiguration", 0)
    if nc = invalid then nc = CreateObject("roNetworkConfiguration", 1)
    if nc <> invalid then
        ' "open" with an empty string = LDWS with no password protection.
        ' SetupDWS returns true only when the port changed and a restart is required.
        if nc.SetupDWS({ open: "", port: "default" }) then needReboot = true
        if nc.GetFailureReason() <> "" then print "SetupDWS failed: " + nc.GetFailureReason()
    else
        print "No network interface available - LDWS not configured"
    end if

    return needReboot
End Function
