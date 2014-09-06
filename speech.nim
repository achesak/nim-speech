# Nimrod wrapper around Google's Speech API.

# Written by Adam Chesak.
# Released under the MIT open source license.


import httpclient
import json
import strutils


type
    GoogleSpeech* = tuple[results : seq[GoogleSpeechResult], resultIndex : string, final : bool]
    GoogleSpeechResult* = tuple[transcript : string, confidence : float]


proc getTextFromSpeech*(audio : TFile, audioType : string = "audio/flac", rate : int = 44100, key : string,
                        lang : string = "en-us", app : string = "", client : string = ""): GoogleSpeech = 
    ## Gets the text from the specified audio file.
    ##
    ## - ``audio`` is the file object
    ## - ``audioType`` is the mimetype of the audio file (defaults to "audio/flac" for FLAC)
    ## - ``rate`` is the sample rate of the audio (defaults to 44100 for FLAC)
    ## - ``key`` is the Google Developer Key, available from the `Google Developers Console`
    ## - ``lang`` is the language of the speech (defaults to "en-us" for English)
    ## - ``app`` (optional) is a query string that returns some extra transcripts for some reason
    ## - ``client`` (optional) is the client that is making the request, this seems to do nothing
    ## _Google Developers Console: https://console.developers.google.com/
    
    var headers : string = "Content-Type: " & audioType
    headers &= "; rate = " & intToStr(rate) & "\c\L"
    headers &= "User-Agent: Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2049.0 Safari/537.36\c\L"
    
    var url : string = "https://www.google.com/speech-api/v2/recognize?output=json"
    url &= "&lang=" & lang
    url &= "&key=" & key
    if app != "":
        url &= "&app=" & app
    if client != "":
        url &= "&client=" & client
    
    var body : string = audio.readAll()
    var data : string = postContent(url, headers, body)
    
    var dataJson : PJsonNode = parseJson(data)
    var gs : GoogleSpeech
    gs.resultIndex = $dataJson["result_index"]
    gs.final = dataJson["result"][0]["final"].bval
    var results : PJsonNode = dataJson["result"][0]["alternative"]
    var gsSeq = newSeq[GoogleSpeechResult](len(results))
    for i in 0..len(results)-1:
        var result : GoogleSpeechResult
        result.transcript = $results[i]["transcript"]
        if results[i].hasKey("confidence")
            result.confidence = results[i]["confidence"].fnum
        gsSeq[i] = result
    gs.results = gsSeq
    
    return gs


proc getTextFromSpeech*(audio : string, audioType : string = "audio/flac", rate : int = 44100, key : string,
                        lang : string = "en-us", app : string = "", client : string = ""): GoogleSpeech = 
    ## Gets the text from the specified audio file.
    ##
    ## Parameters are the same as the previous procedure, except that ``audio`` is a string containing
    ## the filename of the audio file.
    
    return getTextFromSpeech(open(audio), audioType, rate, key, lang, app, client)












## https://github.com/gillesdemey/google-speech-v2