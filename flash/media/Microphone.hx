package flash.media;

import flash.events.EventDispatcher;
import flash.media.SoundMixer;
import js.html.audio.MediaStreamAudioSourceNode;
import js.html.rtc.MediaStream;
import js.html.audio.ScriptProcessorNode;
import flash.events.SampleDataEvent;
import js.html.audio.AudioProcessingEvent;

class Microphone extends EventDispatcher {

	var __mediaStream : MediaStream;
	var __mediaStreamSource : MediaStreamAudioSourceNode;
	var __scriptProcessor : ScriptProcessorNode;

	// TODO
	public var rate (get,set) : Int;
	function get_rate(){ return 44; }
	function set_rate( r : Int ){ return r; }

	public function setSilenceLevel( silenceLevel : Float , ?timeout : Int = -1 ) : Void {
		// TODO
	}
	public function setUseEchoSuppression( useEchoSuppression : Bool ) : Void {
		// TODO
	}
	
	public function setLoopBack( ?state = true ){
		if( state ){
			untyped __mediaStreamSource['connect']( SoundMixer.__audioContext.destination );
		}
	}

	function __create( stream : MediaStream ){
		//trace('user media created',stream);
		// trigger unmute ?
		__mediaStream = stream;
		var __onSample = function(e : AudioProcessingEvent ){
			var sampleData = SampleDataEvent.__create(e);
			dispatchEvent( sampleData );
		};
		__scriptProcessor = SoundMixer.__createScriptProcessor( __onSample );
		__mediaStreamSource = SoundMixer.__createMediaStreamSource( __mediaStream );

		untyped __mediaStreamSource["connect"]( __scriptProcessor );
		untyped __scriptProcessor["connect"]( SoundMixer.__audioContext.destination );

	}

	public static function getMicrophone( ?index = -1 ){
		var mic = new Microphone();
		var __onError = function(e){
			// trigger something ?
			trace("error getting microphone",e);
		}

		var supported = false;
		for( k in ['getUserMedia','webkitGetUserMedia','mozGetUserMedia']){
			if( untyped js.Browser.navigator[k] != null ){
				untyped js.Browser.navigator[k]( { 
					audio : { 
						optional : [ 
							{echoCancellation : false} , 
							{echoCancelation : false} , 
							{googEchoCancellation : false} , 
							{googEchoCancellation2 : false} , 
							{googAutoGainControl : false}, 
							{googAutoGainControl2 : false}, 
							{googNoiseSuppression : false}, 
							{googNoiseSuppression2 : false}, 
							{googHighpassFilter : false}, 
							{googTypingNoiseDetection : false}, 
							{googAudioMirroring : false}
						] 
					}
				} , mic.__create , __onError );
				supported = true;
				break;
			}
		}

		if( !supported ){
			throw "Web Audio API not supported";
		}
		
		return mic;
	}

}