# Save the current encoding and switch to UTF-8.
$prev = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# PowerShell now interprets foo's output correctly as UTF-8-encoded.
# and $output will correctly contain CJK characters.
$output = foo https://example.org -e

# Restore the previous encoding.
[Console]::OutputEncoding = $prev


# IsSingleByte      : True
# BodyName          : ibm850
# EncodingName      : Europe de l'Ouest (DOS)
# HeaderName        : ibm850
# WebName           : ibm850
# WindowsCodePage   : 1252
# IsBrowserDisplay  : False
# IsBrowserSave     : False
# IsMailNewsDisplay : False
# IsMailNewsSave    : False
# EncoderFallback   : System.Text.InternalEncoderBestFitFallback
# DecoderFallback   : System.Text.InternalDecoderBestFitFallback
# IsReadOnly        : True
# CodePage          : 850
