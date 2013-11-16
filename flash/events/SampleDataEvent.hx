package flash.events;

import flash.utils.ByteArray;
import js.html.audio.AudioProcessingEvent;

class SampleDataEvent extends Event {
	
	public static var SAMPLE_DATA = "sampleData";

	public var data (get_data,null) : ByteArray;

	//public var position (get_position,set_position) : Float;

	var __audioProcessingEvent : AudioProcessingEvent;

	public static function __create(e:AudioProcessingEvent){
		var _e = new SampleDataEvent( SAMPLE_DATA );
		_e.__audioProcessingEvent = e;
		return _e;
	} 

	function get_data(){
		return ByteArray.__ofBuffer( __audioProcessingEvent.outputBuffer.getChannelData(0).buffer );
	}

}