package openfl.media;


import flash.events.Event;
import flash.events.EventDispatcher;
import flash.media.SoundMixer;
import flash.utils.ByteArray;
import js.html.MediaElement;
import js.Browser;
import js.html.audio.AudioContext;
import js.html.audio.AudioBufferSourceNode;
import js.html.audio.GainNode;
import js.html.audio.PannerNode;
import js.html.ArrayBuffer;
import js.html.audio.ScriptProcessorNode;
import flash.events.SampleDataEvent;


class SoundChannel extends EventDispatcher {
	
	
	public var ChannelId (default, null):Int;
	public var leftPeak (default, null):Float;
	public var __source (default, null): AudioBufferSourceNode;
	public var __gain (default,null) : GainNode;
	public var __panner (default,null) : PannerNode;
	private var __scriptProcessorNode:ScriptProcessorNode;

	public var position (default, null):Float;
	public var rightPeak (default, null):Float;
	public var soundTransform (default, set_soundTransform):SoundTransform;

	private var __audioCurrentLoop:Int;
	private var __audioTotalLoops:Int;
	private var __removeRef:Void->Void;
	private var __startTime:Float;

	private function new ():Void {
		
		super ( #if bitfive this #end );

		ChannelId = -1;
		leftPeak = 0.;
		position = 0.;
		rightPeak = 0.;
		
		__audioCurrentLoop = 1;
		__audioTotalLoops = 1;
		
	}
	
	
	public function stop ():Void {
		
		if (__source != null) {
			
			__source.stop (0);
			__source = null;
			if (__removeRef != null) __removeRef ();
			
		}
		
	}
	
	public static function __create ( sound:Sound , startTime:Float = 0.0, loops:Int = 0, sndTransform:SoundTransform = null, removeRef:Void->Void):SoundChannel {
		
		var channel = new SoundChannel ();

		var __ctx = SoundMixer.__audioContext;
		
		channel.__source = __ctx.createBufferSource();
		channel.__gain = ( untyped __ctx.createGainNode != null ) ? untyped __ctx.createGainNode() : __ctx.createGain();
		channel.__panner = __ctx.createPanner();
		
		channel.__scriptProcessorNode = SoundMixer.__createScriptProcessor(function(e){
			var sampleData = SampleDataEvent.__create(e);
			channel.dispatchEvent( sampleData );
		});

		untyped channel.__source['connect']( channel.__scriptProcessorNode );
		untyped channel.__scriptProcessorNode['connect']( channel.__gain );
		untyped channel.__gain['connect']( channel.__panner );
		untyped channel.__panner['connect']( __ctx.destination );

		channel.__removeRef = removeRef;
		/*channel.__audio.addEventListener ("ended", cast channel.__onSoundChannelFinished, false);
		channel.__audio.addEventListener ("seeked", cast channel.__onSoundSeeked, false);
		channel.__audio.addEventListener ("stalled", cast channel.__onStalled, false);
		channel.__audio.addEventListener ("progress", cast channel.__onProgress, false);
		*/
		if (loops > 0) {

			channel.__audioTotalLoops = loops;
			// webkit-specific 
			channel.__source.loop = true;
			
		}
		
		channel.__startTime = startTime;

		var onLoad = null;
			
		onLoad = function (?_) { 
			
			channel.__source.buffer = sound.__audioBuffer;
			channel.__start();
			
			sound.removeEventListener( Event.COMPLETE , onLoad );
			
		}
		
		if ( sound.__audioBuffer == null ) {
			
			sound.addEventListener( Event.COMPLETE , onLoad , false );
			//channel.__source.addEventListener ("canplaythrough", cast onLoad, false);
			
		} else {
			 onLoad( null );
			//channel.__source.autoplay = true;
			
		}
		
		//channel.__audio.src = src;
		
		// note: the following line seems to crash completely on most browsers,
		// maybe because the sound isn't loaded ?
		
		//if (startTime > 0.) channel.__audio.currentTime = startTime;
		
		return channel;
		
	}

	private function __start(){
		untyped {
			if( __source.start != null ){
				__source.start ( SoundMixer.__audioContext.currentTime );	
			}else{
				__source.noteOn ( 0 );	
			}
		}
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function __onProgress (evt:Event):Void {
		
		#if debug
		trace ("sound progress: " + evt);
		#end
		
	}
	
	
	private function __onSoundChannelFinished (evt:Event):Void {
		
		if (__audioCurrentLoop >= __audioTotalLoops) {
			
			/*__audio.removeEventListener ("ended", cast __onSoundChannelFinished, false);
			__audio.removeEventListener ("seeked", cast __onSoundSeeked, false);
			__audio.removeEventListener ("stalled", cast __onStalled, false);
			__audio.removeEventListener ("progress", cast __onProgress, false);
			__audio = null;*/
			
			var evt = new Event (Event.SOUND_COMPLETE);
			evt.target = this;
			dispatchEvent (evt);
			
			if (__removeRef != null) {
				
				__removeRef ();
				
			}
			
		} else {
			
			// firefox-specific
			//__buffer.currentTime = __startTime;
			__start();
			
		}
		
	}
	
	
	private function __onSoundSeeked (evt:Event):Void {
		
		if (__audioCurrentLoop >= __audioTotalLoops) {
			
			__source.loop = false;
			stop();
			
		} else {
			
			__audioCurrentLoop++;
			
		}
		
	}
	
	
	private function __onStalled (evt:Event):Void {
		
		#if debug
		trace ("sound stalled");
		#end
		
		/*if (__audio != null) {
			
			__audio.load ();
			
		}*/
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function set_soundTransform (v:SoundTransform):SoundTransform {
		
		__gain.gain.value = v.volume;
		return this.soundTransform = v;
		
	}
	
	
}