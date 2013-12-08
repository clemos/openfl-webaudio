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
		if( data == null ) {
			// FIXME only works for microphone (mono)
			var __channelData = __audioProcessingEvent.inputBuffer.getChannelData(0);
			data = new ByteArray();
			data.length = __channelData.length * 4;
			for( f in __channelData ){
				data.writeFloat( f );
			}
			data.position = 0;
		}
		
		return data;

	}

}