@readKeyCombo = (e, preventDefault) ->

    keyChar = ""

    keyCodes = { ESC: 27, backspace: 8, deleteKey: 46, enter: 13, space: 32, shiftKey: 16, f1: 112, f12: 123}

    keyNames = { 37: "left", 38: "up", 39: "right", 40: "down" }

    # This is a mapping of the incorrect keyIdentifiers generated by Webkit on Windows during keydown events to
    # the correct identifiers, which are correctly generated on Mac. We require this mapping to properly handle
    # these keys on Windows. See https://bugs.webkit.org/show_bug.cgi?id=19906 for more details.
    keyIdentifierCorrectionMap = {
        "U+00C0": ["U+0060", "U+007E"], # `~
        "U+00BD": ["U+002D", "U+005F"], # -_
        "U+00BB": ["U+003D", "U+002B"], # =+
        "U+00DB": ["U+005B", "U+007B"], # [{
        "U+00DD": ["U+005D", "U+007D"], # ]}
        "U+00DC": ["U+005C", "U+007C"], # \|
        "U+00BA": ["U+003B", "U+003A"], # ;:
        "U+00DE": ["U+0027", "U+0022"], # '"
        "U+00BC": ["U+002C", "U+003C"], # ,<
        "U+00BE": ["U+002E", "U+003E"], # .>
        "U+00BF": ["U+002F", "U+003F"] # /?
    }

    platform = if navigator.userAgent.indexOf("Mac") isnt -1
                   "Mac"
               else if navigator.userAgent.indexOf("Linux") isnt -1
                   "Linux"
               else
                   "Windows"

    if e.type is 'keydown'

        # handle modifiers being pressed.don't handle shiftKey alone (to avoid / being interpreted as ?
        if (e.metaKey or e.ctrlKey or e.altKey) and e.keyCode > 31

            e.preventDefault() if preventDefault

            # Not a letter
            if e.keyIdentifier.slice(0, 2) isnt "U+"
                # Named key
                if keyNames[e.keyCode]
                    return keyNames[e.keyCode]

                # F-key
                if e.keyCode >= keyCodes.f1 and e.keyCode <= keyCodes.f12
                    return "f" + (1 + e.keyCode - keyCodes.f1)

                return ""

            keyIdentifier = e.keyIdentifier

            # On Windows, the keyIdentifiers for non-letter keys are incorrect. See
            # https://bugs.webkit.org/show_bug.cgi?id=19906 for more details.
            if (platform == "Windows" or platform == "Linux") and keyIdentifierCorrectionMap[keyIdentifier]
                correctedIdentifiers = keyIdentifierCorrectionMap[keyIdentifier]
                keyIdentifier = if e.shiftKey then correctedIdentifiers[0] else correctedIdentifiers[1]

            unicodeKeyInHex = "0x" + keyIdentifier.substring(2)

            keyChar = String.fromCharCode(parseInt(unicodeKeyInHex)).toLowerCase()

            # Again, ignore just modifiers. Maybe this should replace the keyCode > 31 condition.
            if keyChar isnt ""

                keyChar = keyChar.toUpperCase() if e.shiftKey

                modifiers = []
                modifiers.push("M") if e.metaKey
                modifiers.push("C") if e.ctrlKey
                modifiers.push("A") if e.altKey

                keyChar = modifiers.join('-') + (if modifiers.length is 0 then '' else '-') + keyChar

                if modifiers.length > 0 or keyChar.length > 1
                    keyChar = "<" + keyChar + ">"

    else if e.type is 'keypress'

        # Ignore modifier keys by themselves.
        if e.keyCode > 31
            keyChar = String.fromCharCode e.charCode

    console.info 'key char', keyChar
    keyChar

# Gives a string that is a regex representation of the given glob pattern
@globToRegex = (line) ->

    console.info "got line [" + line + "]"
    line = $.trim line
    
    sb = []
    
    # Remove beginning and ending * globs because they're useless
    if line.length > 1 and line[0] is "*"
        line = line.substring(1)

    if line.length > 1 and line[line.length-1] is "*"
        line = line.substring(0, line.length - 1)
    
    i = 0
    len = line.length

    escaping = no
    inCurlies = 0

    while (i < len)
        currentChar = line[i++]
        switch currentChar
            when '*'
                sb.push(if escaping then "\\*" else ".*")
                escaping = no
            when '?'
                sb.push(if escaping then "\\?" else ".")
                escaping = no
            when '.', '(', ')', '+', '|', '^', '$', '@', '%'
                sb.push('\\')
                sb.push(currentChar)
                escaping = no
            when '\\'
                sb.push("\\\\") if escaping
                escaping = not escaping
            when '{'
                sb.push(if escaping then '\\{' else '(')
                inCurlies++ unless escaping
                escaping = no
            when '}'
                if inCurlies > 0 and not escaping
                    sb.push(')')
                    inCurlies--
                else if escaping
                    sb.push("\\}")
                else
                    sb.push("}")
                escaping = no
            when ','
                if inCurlies > 0 and not escaping
                    sb.push('|')
                else if escaping
                    sb.push("\\,")
                else
                    sb.push(",")
            else
                sb.push(currentChar)
                escaping = no

    sb.join ''
