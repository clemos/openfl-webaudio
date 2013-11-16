package flash.media;


import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.SampleDataEvent;
import flash.net.URLRequest;
import flash.net.URLLoader;
import flash.Lib;
import flash.utils.ByteArray;
import js.html.Float32Array;
import js.html.MediaElement;
import js.Browser;
import js.html.audio.AudioContext;
import js.html.audio.ScriptProcessorNode;
import js.html.ArrayBuffer;
import js.html.audio.AudioBuffer;
import openfl.utils.ArrayBuffer;


@:autoBuild(openfl.Assets.embedSound())
class Sound extends EventDispatcher {
	
	
	static inline var EXTENSION_MP3 = "mp3";
	static inline var EXTENSION_OGG = "ogg";
	static inline var EXTENSION_WAV = "wav";
	static inline var EXTENSION_AAC = "aac";
	static inline var MEDIA_TYPE_MP3 = "audio/mpeg";
	static inline var MEDIA_TYPE_OGG = "audio/ogg; codecs=\"vorbis\"";
	static inline var MEDIA_TYPE_WAV = "audio/wav; codecs=\"1\"";
	static inline var MEDIA_TYPE_AAC = "audio/mp4; codecs=\"mp4a.40.2\"";
	
	public var bytesLoaded (default, null):Int;
	public var bytesTotal (default, null):Int;
	public var id3 (default, null):ID3Info;
	public var isBuffering (default, null):Bool;
	public var length (default, null):Float;
	public var url (default, null):String;
	
	private var __soundCache:URLLoader;
	private var __soundChannels:Map<Int, SoundChannel>;
	private var __soundIdx:Int;
	private var __streamUrl:String;

	public var __audioBuffer (default, null): AudioBuffer;
	
	private var __file:ByteArray;
	private var __channelData:Array<Float32Array>;
	//private var __channelDataBuffer:ArrayBuffer;
	private var __sampleIndex:Int;
	private var __scriptProcessorNode:ScriptProcessorNode;

	public static var __ctx (get___ctx,null) : AudioContext;
	private static var __ctxClass : Dynamic;

	static function get___ctx() untyped {

		if( __ctx != null ) return __ctx;

		__ctxClass = if( __js__('typeof webkitAudioContext') != "undefined" ){
			__js__('webkitAudioContext');
		}else if( __js__('typeof AudioContext') != "undefined" ){
			__js__('AudioContext');
		}else{
			null;
		}

		if( __ctxClass == null ){
			trace( "Web Audio Api is not available..." );
			return;
		}

		__ctx = untyped __new__( __ctxClass );
		return __ctx;
	}
	
	public function new (stream:URLRequest = null, context:SoundLoaderContext = null):Void {
		
		super (this);
		
		bytesLoaded = 0;
		bytesTotal = 0;
		id3 = null;
		isBuffering = false;
		length = 0;
		url = null;
		
		__soundChannels = new Map<Int, SoundChannel> ();
		__soundIdx = 0;

		if (stream != null) {	
			load (stream, context);
		}
		
	}
	
	
	public function close ():Void {
		
		
		
	}
	
	
	public function load (stream:URLRequest, context:SoundLoaderContext = null):Void {
		
		__load (stream, context);
		
	}

	public function extract( bytes : ByteArray , length : Int , startPosition = -1 ){

		if( __audioBuffer == null ) return 0;
		
		if( __channelData == null ){
			__channelData = [];
			// retrieve all channels from audio buffer
			for( i in 0...__audioBuffer.numberOfChannels ){
				__channelData[i] = __audioBuffer.getChannelData(i);
			}
			__sampleIndex = 0;
		}

		// if start position is negative, take internal __sampleIndex as offset
		var offset : Int = (startPosition<0) ? __sampleIndex : startPosition;
		var max : Int = Std.int( Math.min( offset+length , __channelData[0].length / Float32Array.BYTES_PER_ELEMENT ) );
		var len = max-offset;

		// preallocate for optimization
		bytes.length = 2 * len * 4;

		for( i in offset...max ){

			var s_left =  __channelData[0][i];
			var s_right = if( __channelData.length < 2 ){
				// if the signal is mono, write twice to emulate
				s_left;
			}else{
				__channelData[1][i];
			}

			bytes.writeFloat( s_left );
			bytes.writeFloat( s_right );
		}

		if( startPosition < 0 ) __sampleIndex += len;

		return len;
	}
	
	public function play (startTime:Float = 0.0, loops:Int = 0, sndTransform:SoundTransform = null):SoundChannel {

		// -- GC the sound when the following closure is executed
		var self = this;
		var curIdx = __soundIdx;
		var removeRef = function () {
			self.__soundChannels.remove (curIdx);
		}
		// --

		__scriptProcessorNode = __ctx.createScriptProcessor( 8192 );
		__scriptProcessorNode.onaudioprocess = function(e){
			var sampleData = SampleDataEvent.__create(e);
			dispatchEvent( sampleData );

		};
		untyped __scriptProcessorNode["connect"](__ctx.destination);

		var channel = SoundChannel.__create (this, startTime, loops, sndTransform, removeRef);
		__soundChannels.set (curIdx, channel);
		__soundIdx++;
		
		return channel;
		
	}
	
	
	private function __addEventListeners ():Void {
		
		__soundCache.addEventListener (Event.COMPLETE, __onSoundLoaded);
		__soundCache.addEventListener (IOErrorEvent.IO_ERROR, __onSoundLoadError);
		
	}
	
	
	public static function __canPlayMime (mime:String):Bool {
		
		var audio:MediaElement = cast Browser.document.createElement ("audio");
		
		var playable = function (ok:String) {
			
			if (ok != "" && ok != "no") return true; else return false;
		}
		
		//return playable(audio.canPlayType(mime));
		return playable (audio.canPlayType (mime, null));
		
	}
	
	
	public static function __canPlayType (extension:String):Bool {
		
		var mime = __mimeForExtension (extension);
		if (mime == null) return false;
		return __canPlayMime (mime);
		
	}
	
	
	public function __load (stream:URLRequest, context:SoundLoaderContext = null, mime:String = ""):Void {
		
		#if debug
		if (mime == null) {
			
			var url = stream.url.split ("?");
			var extension = url[0].substr (url[0].lastIndexOf (".") + 1);
			mime = __mimeForExtension (extension);
			
		}
		
		if (mime == null || !__canPlayMime (mime))
			trace ("Warning: '" + stream.url + "' with type '" + mime + "' may not play on this browser.");
		#end
		
		__streamUrl = stream.url;
		
		// initiate a network request, so the resource is cached by the browser
		try {
			
			__soundCache = new URLLoader ();
			__soundCache.dataFormat = BINARY;
			__addEventListeners ();
			__soundCache.load (stream);
			
		} catch (e:Dynamic) {
			
			#if debug
			trace ("Warning: Could not preload '" + stream.url + "'");
			#end
			
		}
		
	}
	
	
	private static inline function __mimeForExtension (extension:String):String {
		
		var mime:String = null;
		
		switch (extension) {
			
			case EXTENSION_MP3: mime = MEDIA_TYPE_MP3;
			case EXTENSION_OGG: mime = MEDIA_TYPE_OGG;
			case EXTENSION_WAV: mime = MEDIA_TYPE_WAV;
			case EXTENSION_AAC: mime = MEDIA_TYPE_AAC;
			default: mime = null;
			
		}
		
		return mime;
		
	}
	
	
	private function __removeEventListeners ():Void {
		
		__soundCache.removeEventListener (Event.COMPLETE, __onSoundLoaded, false);
		__soundCache.removeEventListener (IOErrorEvent.IO_ERROR, __onSoundLoadError, false);
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function __onSoundLoadError (evt:IOErrorEvent):Void {
		
		__removeEventListeners ();
		
		#if debug
		trace ("Error loading sound '" + __streamUrl + "'");
		#end
		
		var evt = new IOErrorEvent (IOErrorEvent.IO_ERROR);
		dispatchEvent (evt);
		
	}
	
	
	private function __onSoundLoaded (evt:Event):Void {
		__file = __soundCache.data;
		__audioBuffer = __ctx.createBuffer( __file.__getBuffer() , false );


		trace("loaded",__file.length);
		trace("buffer",__audioBuffer.length);
		//trace(__soundCache.dataFormat);
		//trace(Type.typeof(__soundCache.data));

		__removeEventListeners ();
		var evt = new Event (Event.COMPLETE);
		dispatchEvent (evt);
		
	}
	
	
}