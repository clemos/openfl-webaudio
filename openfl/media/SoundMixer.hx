package openfl.media;

import js.html.audio.AudioContext;
import js.html.audio.AudioProcessingEvent;
import js.html.rtc.MediaStream;

class SoundMixer {
	
	public static var __audioContext (get,null) : AudioContext;
	private static var __audioContextClass : Dynamic;

	static function get___audioContext() untyped {

		if( __audioContext != null ) return __audioContext;

		__audioContextClass = if( __js__('typeof webkitAudioContext') != "undefined" ){
			__js__('webkitAudioContext');
		}else if( __js__('typeof AudioContext') != "undefined" ){
			__js__('AudioContext');
		}else{
			null;
		}

		if( __audioContextClass == null ){
			trace( "Web Audio Api is not available..." );
			return;
		}

		return __audioContext = untyped __new__( __audioContextClass );

	}

	public static function __createScriptProcessor( onaudioprocess : AudioProcessingEvent -> Void ){
		var __scriptProcessorNode = __audioContext.createScriptProcessor( 8192 );
		__scriptProcessorNode.onaudioprocess = onaudioprocess;
		return __scriptProcessorNode;
	}

	public static function __createMediaStreamSource( stream : MediaStream ){
		return __audioContext.createMediaStreamSource( stream );
	}

}